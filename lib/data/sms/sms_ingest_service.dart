import 'dart:async';

import 'package:permission_handler/permission_handler.dart';

import '../../core/ids.dart';
import '../../core/theme.dart';
import '../../domain/sms/bank_senders.dart';
import '../../domain/sms/parsed_transaction.dart';
import '../../domain/sms/sms_catch_up.dart';
import '../../domain/sms/sms_account_name.dart';
import '../../domain/sms/payee_category_memory.dart';
import '../../domain/sms/payee_normaliser.dart';
import '../../domain/sms/sms_categorizer.dart';
import '../../domain/sms/sms_confidence.dart';
import '../../domain/sms/sms_currency.dart';
import '../../domain/sms/sms_outcome.dart';
import '../../domain/sms/sms_parser.dart';
import '../../domain/sms/sms_transaction_key.dart';
import '../db/database.dart';
import '../repositories/accounts_repository.dart';
import '../repositories/categories_repository.dart';
import '../repositories/entries_repository.dart';
import '../repositories/payee_category_repository.dart';
import '../repositories/sms_log_repository.dart';
import 'sms_channel.dart';
import 'sms_reminder_linker.dart';
import 'sms_sync_cursor.dart';

/// What [SmsIngestService.ingest] did with one message. [pending] means it
/// is waiting in the review queue, whether it was read with low confidence
/// or could not be read at all; [unparsed] means it was dropped.
enum IngestStatus { duplicate, notBank, foreignCurrency, unparsed, pending, added }

/// An entry that was created from an SMS without the user approving it.
class SmsAutoAdded {
  const SmsAutoAdded({required this.smsId, required this.entryId, required this.amountMinor, required this.isDebit, this.payee});
  final String smsId;
  final String entryId;
  final int amountMinor;
  final bool isDebit;
  final String? payee;
}

/// What one [SmsIngestService.sync] did.
class SmsSyncResult {
  const SmsSyncResult({required this.scanned, required this.pending, required this.added});
  final int scanned;
  final int pending;
  final int added;
}

/// Turns raw SMS into log rows, accounts and (optionally) entries.
class SmsIngestService {
  SmsIngestService({
    required this.smsLog,
    required this.accounts,
    required this.categories,
    required this.entries,
    required this.cursor,
    this.source = const PlatformSmsSource(),
    required this.homeCurrencyCode,
    this.reminderLinker,
    this.payeeCategories,
  });

  final SmsLogRepository smsLog;
  final AccountsRepository accounts;
  final CategoriesRepository categories;
  final EntriesRepository entries;

  final SmsSyncCursor cursor;
  final SmsSource source;

  Future<void> _syncChain = Future.value();

  /// Read on every message, so a change of home currency applies at once.
  final String Function() homeCurrencyCode;

  /// Pays a pending reminder the new entry matches; null disables matching.
  final SmsReminderLinker? reminderLinker;

  /// Categories the user chose per payee; they win over the keyword rules.
  /// Null disables payee memory.
  final PayeeCategoryRepository? payeeCategories;

  final _autoAddedController = StreamController<SmsAutoAdded>.broadcast();

  /// Every entry added automatically, so the open app can offer Undo.
  Stream<SmsAutoAdded> get autoAdded => _autoAddedController.stream;

  Future<bool> requestPermission() async {
    if (!SmsChannel.isSupported) return false;
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async => SmsChannel.isSupported && await Permission.sms.isGranted;

  /// Runs everything captured since the last sync through [ingest]: first the
  /// messages the background receiver queued, then an inbox scan from the
  /// stored cursor (or [lookback] on a first scan) for anything it missed.
  /// Calls are serialised, so start, resume and live signals can overlap.
  Future<SmsSyncResult> sync({required bool autoAdd, Duration lookback = const Duration(days: 90), DateTime? now}) {
    final next = _syncChain.then((_) => _sync(autoAdd: autoAdd, lookback: lookback, now: now ?? DateTime.now()));
    _syncChain = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<SmsSyncResult> _sync({required bool autoAdd, required Duration lookback, required DateTime now}) async {
    final queued = await source.drainQueue();
    final since = catchUpSince(now: now, cursor: cursor.read(), lastLogged: await smsLog.latestReceivedAt(excludingSender: RawSms.pastedSender), lookback: lookback);
    final inbox = await source.readInbox(since: since);
    final counts = <IngestStatus, int>{};
    for (final message in [...queued, ...inbox]) {
      final status = await ingest(message, autoAdd: autoAdd);
      counts[status] = (counts[status] ?? 0) + 1;
    }
    // Every queued message is now added, waiting in review or ignored, and
    // the app shows that itself, so its background notification goes (#103).
    await source.cancelNotifications(queued);
    final advanced = advanceCursor(cursor.read(), inbox.map((message) => message.receivedAt));
    if (advanced != null) await cursor.write(advanced);
    return SmsSyncResult(scanned: queued.length + inbox.length, pending: counts[IngestStatus.pending] ?? 0, added: counts[IngestStatus.added] ?? 0);
  }

  /// Handles one message end to end. Safe to call repeatedly for the same SMS.
  Future<IngestStatus> ingest(RawSms message, {required bool autoAdd, bool force = false}) async {
    final id = SmsLogRepository.idFor(message.sender, message.body, message.receivedAt);
    final existing = await smsLog.getById(id);
    if (existing != null) {
      await _recordDuplicate(existing, message);
      return IngestStatus.duplicate;
    }
    if (!force && !_worthIngesting(message)) {
      if (!isPersonalSender(message.sender)) {
        await smsLog.record(id: id, sender: message.sender, body: message.body, receivedAt: message.receivedAt, status: SmsLogStatus.notBank);
      }
      return IngestStatus.notBank;
    }
    if (isForeignCurrency(smsCurrencyCode(message.body), homeCurrencyCode())) {
      // Cross-currency is not supported: logged so it is not read again, but
      // neither added nor queued for review.
      await smsLog.record(id: id, sender: message.sender, body: message.body, receivedAt: message.receivedAt, status: SmsLogStatus.skipped);
      return IngestStatus.foreignCurrency;
    }

    final parsed = parseBankSms(sender: message.sender, body: message.body, receivedAt: message.receivedAt);
    if (parsed == null) {
      final route = routeForSms(parsed: null, autoAddEnabled: autoAdd, possibleTransaction: looksLikeUnreadTransaction(message.body, sender: message.sender));
      if (route == SmsRoute.review) {
        await smsLog.record(id: id, sender: message.sender, body: message.body, receivedAt: message.receivedAt, status: SmsLogStatus.pending);
        return IngestStatus.pending;
      }
      if (!isPersonalSender(message.sender)) {
        await smsLog.record(id: id, sender: message.sender, body: message.body, receivedAt: message.receivedAt, status: SmsLogStatus.skipped);
      }
      return IngestStatus.unparsed;
    }

    // The same payment can arrive again under another id: pasted with today's
    // time, opened from a link, or read from the inbox after a paste.
    final transactionKey = smsTransactionKeyForParsed(message.body, parsed);
    if (await smsLog.hasTransaction(transactionKey)) return IngestStatus.duplicate;

    // Only an account we already know gets its balance refreshed here; a new
    // account is created when the user approves the transaction, not before.
    final known = await accounts.findBySmsKey(parsed.accountKey);
    if (known != null && parsed.balanceMinor != null) {
      await accounts.applyReportedBalance(known.id, parsed.balanceMinor!, parsed.occurredAt);
    }
    final categoryKey = suggestCategoryKey(parsed);
    final payload = parsed.toJson()
      ..['suggestedCategory'] = categoryKey
      ..['accountKey'] = parsed.accountKey
      ..['accountId'] = known?.id;

    if (routeForSms(parsed: parsed, autoAddEnabled: autoAdd, possibleTransaction: true) != SmsRoute.autoAdd) {
      await smsLog.record(id: id, sender: message.sender, body: message.body, receivedAt: message.receivedAt, status: SmsLogStatus.pending, parsed: payload, transactionKey: transactionKey);
      return IngestStatus.pending;
    }
    final account = await _ensureAccount(parsed);
    final entryId = await _createEntry(id, parsed, await categoryIdFor(parsed), account?.id);
    await smsLog.record(id: id, sender: message.sender, body: message.body, receivedAt: message.receivedAt, status: SmsLogStatus.added, parsed: payload, entryId: entryId, transactionKey: transactionKey);
    await reminderLinker?.linkEntry(smsId: id, parsed: parsed, entryId: entryId);
    _autoAddedController.add(SmsAutoAdded(
      smsId: id,
      entryId: entryId,
      amountMinor: parsed.amountMinor,
      isDebit: parsed.isDebit,
      payee: _payeeFor(parsed),
    ));
    return IngestStatus.added;
  }

  /// Reverses an automatic add: a reminder it paid reopens, the entry is
  /// deleted and the SMS is marked ignored, so it does not come back in the
  /// review queue.
  Future<void> undoAutoAdd(SmsAutoAdded added) async {
    await reminderLinker?.unlinkEntry(smsId: added.smsId, entryId: added.entryId);
    await entries.deleteEntry(added.entryId);
    await smsLog.setStatus(added.smsId, SmsLogStatus.ignored);
  }

  /// Runs an ignored or unparsed message through ingest again, e.g. after
  /// the parser learned a new format. The old row is replaced.
  Future<IngestStatus> reprocess(SmsLogData row, {required bool autoAdd}) async {
    await smsLog.delete(row.id);
    return ingest(RawSms(sender: row.sender, body: row.body, receivedAt: row.receivedAt), autoAdd: autoAdd, force: true);
  }

  /// A re-read of the same inbox message is silent; a bank re-delivery at a
  /// different time gets its own history row, linked to the original's entry.
  Future<void> _recordDuplicate(SmsLogData original, RawSms message) async {
    if (!logsDuplicateOf(original.status, message.body) || isSameDelivery(original.receivedAt, message.receivedAt)) return;
    final duplicateId = SmsLogRepository.duplicateIdFor(original.id, message.receivedAt);
    if (await smsLog.exists(duplicateId)) return;
    await smsLog.record(
      id: duplicateId,
      sender: message.sender,
      body: message.body,
      receivedAt: message.receivedAt,
      status: SmsLogStatus.duplicate,
      entryId: original.entryId,
    );
  }

  /// Approves a pending log row into an entry with the suggested values.
  Future<String?> approvePending(SmsLogData row) async {
    final parsed = parseBankSms(sender: row.sender, body: row.body, receivedAt: row.receivedAt);
    if (parsed == null) return null;
    final account = await _ensureAccount(parsed);
    final entryId = await _createEntry(row.id, parsed, await categoryIdFor(parsed), account?.id);
    await smsLog.setStatus(row.id, SmsLogStatus.added, entryId: entryId);
    await reminderLinker?.linkEntry(smsId: row.id, parsed: parsed, entryId: entryId);
    return entryId;
  }

  /// Pays the reminder a logged SMS matches once the user saved it as [entryId]
  /// from the editor. Returns the reminder id, or null.
  Future<String?> linkSavedEntry(String smsId, String entryId) async {
    final linker = reminderLinker;
    final row = await smsLog.getById(smsId);
    if (linker == null || row == null) return null;
    final parsed = parseBankSms(sender: row.sender, body: row.body, receivedAt: row.receivedAt);
    return parsed == null ? null : linker.linkEntry(smsId: smsId, parsed: parsed, entryId: entryId);
  }

  /// Creates (or finds) the account a logged SMS refers to. Used when the
  /// user saves a pending SMS from the editor without picking an account.
  Future<Account?> ensureAccountForSms(String smsId) async {
    final row = await smsLog.getById(smsId);
    if (row == null) return null;
    final parsed = parseBankSms(sender: row.sender, body: row.body, receivedAt: row.receivedAt);
    return parsed == null ? null : _ensureAccount(parsed);
  }

  /// The category a new entry from [parsed] gets: the one the user chose for
  /// this payee before, otherwise the keyword rules' suggestion.
  Future<String?> categoryIdFor(ParsedTransaction parsed) async {
    final remembered = await rememberedCategoryFor(kind: payeeKindFor(parsed.direction), counterparty: parsed.counterparty);
    return remembered?.id ?? (await categories.findBySeedKey(suggestCategoryKey(parsed)))?.id;
  }

  /// The category remembered for [counterparty] on the [kind] side, if it is
  /// still usable (not deleted, archived or of the other kind).
  Future<Category?> rememberedCategoryFor({required String kind, required String? counterparty}) async {
    final categoryId = await payeeCategories?.categoryIdFor(kind: kind, raw: counterparty);
    if (categoryId == null) return null;
    final category = await categories.byId(categoryId);
    return isUsablePayeeCategory(category, kind) ? category : null;
  }

  /// Remembers [categoryId] for the payee of the logged SMS [smsId], so its
  /// next messages get that category. Called when the user changes the
  /// category of an SMS entry or answers the new-payee prompt.
  Future<void> rememberCategoryForSms(String smsId, String categoryId) async {
    final memory = payeeCategories;
    final row = await smsLog.getById(smsId);
    if (memory == null || row == null) return;
    final parsed = parsedSmsPayee(row.parsedJson);
    if (parsed == null) return;
    final category = await categories.byId(categoryId);
    if (!isUsablePayeeCategory(category, parsed.kind)) return;
    await memory.remember(kind: parsed.kind, raw: parsed.counterparty, categoryId: categoryId);
  }

  Future<String> _createEntry(String smsId, ParsedTransaction parsed, String? categoryId, String? accountId) async {
    final id = newId();
    await entries.saveEntry(EntriesRepository.newExpense(
      id: id,
      kind: parsed.isDebit ? 'expense' : 'income',
      amountMinor: parsed.amountMinor,
      occurredAt: parsed.occurredAt,
      categoryId: categoryId,
      accountId: accountId,
      payee: _payeeFor(parsed),
      note: smsEntryNote(reference: parsed.reference, rawCounterparty: parsed.counterparty),
      source: 'sms',
      smsId: smsId,
    ));
    return id;
  }

  static String? _payeeFor(ParsedTransaction parsed) => parsed.counterparty == null ? null : normalisePayee(parsed.counterparty!);

  Future<Account?> _ensureAccount(ParsedTransaction parsed) async {
    final key = parsed.accountKey;
    final existing = await accounts.findBySmsKey(key);
    if (existing != null) return existing;
    final created = await accounts.create(
      name: smsAccountName(bank: parsed.bank, isCreditCard: parsed.isCreditCard, last4: parsed.accountLast4),
      type: parsed.isCreditCard ? 'card' : 'bank',
      color: kPaletteColors[key.hashCode.abs() % kPaletteColors.length],
      bankName: parsed.bank ?? 'Bank',
      last4: parsed.accountLast4,
      smsKey: key,
      includeInTotal: !parsed.isCreditCard,
    );
    if (parsed.balanceMinor != null) {
      await accounts.applyReportedBalance(created.id, parsed.balanceMinor!, parsed.occurredAt);
    }
    return created;
  }

  /// Personal chats are never ingested, however much they read like a debit.
  static bool _worthIngesting(RawSms message) =>
      isBusinessSender(message.sender) && (looksLikeBankSender(message.sender) || hasTransactionSignal(message.body));
}

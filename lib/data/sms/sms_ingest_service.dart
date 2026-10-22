import 'package:permission_handler/permission_handler.dart';

import '../../core/ids.dart';
import '../../core/theme.dart';
import '../../domain/sms/bank_senders.dart';
import '../../domain/sms/parsed_transaction.dart';
import '../../domain/sms/sms_catch_up.dart';
import '../../domain/sms/sms_account_name.dart';
import '../../domain/sms/payee_normaliser.dart';
import '../../domain/sms/sms_categorizer.dart';
import '../../domain/sms/sms_parser.dart';
import '../db/database.dart';
import '../repositories/accounts_repository.dart';
import '../repositories/categories_repository.dart';
import '../repositories/entries_repository.dart';
import '../repositories/sms_log_repository.dart';
import 'sms_channel.dart';
import 'sms_sync_cursor.dart';

enum IngestStatus { duplicate, notBank, unparsed, pending, added }

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
  });

  final SmsLogRepository smsLog;
  final AccountsRepository accounts;
  final CategoriesRepository categories;
  final EntriesRepository entries;

  final SmsSyncCursor cursor;
  final SmsSource source;

  Future<void> _syncChain = Future.value();

  Future<bool> requestPermission() async {
    if (!SmsChannel.isSupported) return false;
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async => SmsChannel.isSupported && await Permission.sms.isGranted;

  /// Asks for POST_NOTIFICATIONS (Android 13+) so SMS captured while the
  /// app is closed can be announced. Capture works whatever the answer.
  Future<void> requestNotificationPermission() async {
    if (!SmsChannel.isSupported) return;
    await Permission.notification.request();
  }

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
    final since = catchUpSince(now: now, cursor: cursor.read(), lastLogged: await smsLog.latestReceivedAt(), lookback: lookback);
    final inbox = await source.readInbox(since: since);
    final counts = <IngestStatus, int>{};
    for (final message in [...queued, ...inbox]) {
      final status = await ingest(message, autoAdd: autoAdd);
      counts[status] = (counts[status] ?? 0) + 1;
    }
    final advanced = advanceCursor(cursor.read(), inbox.map((message) => message.receivedAt));
    if (advanced != null) await cursor.write(advanced);
    return SmsSyncResult(scanned: queued.length + inbox.length, pending: counts[IngestStatus.pending] ?? 0, added: counts[IngestStatus.added] ?? 0);
  }

  /// Handles one message end to end. Safe to call repeatedly for the same SMS.
  Future<IngestStatus> ingest(RawSms message, {required bool autoAdd, bool force = false}) async {
    final id = SmsLogRepository.idFor(message.sender, message.body, message.receivedAt);
    if (await smsLog.exists(id)) return IngestStatus.duplicate;
    if (!force && !looksLikeBankSender(message.sender) && !_looksFinancial(message.body)) return IngestStatus.notBank;

    final parsed = parseBankSms(sender: message.sender, body: message.body, receivedAt: message.receivedAt);
    if (parsed == null) {
      if (force || looksLikeBankSender(message.sender)) {
        await smsLog.record(id: id, sender: message.sender, body: message.body, receivedAt: message.receivedAt, status: 'skipped');
      }
      return IngestStatus.unparsed;
    }

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

    if (!autoAdd) {
      await smsLog.record(id: id, sender: message.sender, body: message.body, receivedAt: message.receivedAt, status: 'pending', parsed: payload);
      return IngestStatus.pending;
    }
    final account = await _ensureAccount(parsed);
    final entryId = await _createEntry(id, parsed, categoryKey, account?.id);
    await smsLog.record(id: id, sender: message.sender, body: message.body, receivedAt: message.receivedAt, status: 'added', parsed: payload, entryId: entryId);
    return IngestStatus.added;
  }

  /// Approves a pending log row into an entry with the suggested values.
  Future<String?> approvePending(SmsLogData row) async {
    final parsed = parseBankSms(sender: row.sender, body: row.body, receivedAt: row.receivedAt);
    if (parsed == null) return null;
    final account = await _ensureAccount(parsed);
    final entryId = await _createEntry(row.id, parsed, suggestCategoryKey(parsed), account?.id);
    await smsLog.setStatus(row.id, 'added', entryId: entryId);
    return entryId;
  }

  /// Creates (or finds) the account a logged SMS refers to. Used when the
  /// user saves a pending SMS from the editor without picking an account.
  Future<Account?> ensureAccountForSms(String smsId) async {
    final row = await smsLog.getById(smsId);
    if (row == null) return null;
    final parsed = parseBankSms(sender: row.sender, body: row.body, receivedAt: row.receivedAt);
    return parsed == null ? null : _ensureAccount(parsed);
  }

  Future<String> _createEntry(String smsId, ParsedTransaction parsed, String categoryKey, String? accountId) async {
    final category = await categories.findBySeedKey(categoryKey);
    final id = newId();
    await entries.saveEntry(EntriesRepository.newExpense(
      id: id,
      kind: parsed.isDebit ? 'expense' : 'income',
      amountMinor: parsed.amountMinor,
      occurredAt: parsed.occurredAt,
      categoryId: category?.id,
      accountId: accountId,
      payee: parsed.counterparty == null ? null : normalisePayee(parsed.counterparty!),
      note: smsEntryNote(reference: parsed.reference, rawCounterparty: parsed.counterparty),
      source: 'sms',
      smsId: smsId,
    ));
    return id;
  }

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

  static final _financialHint = RegExp(r'(debited|credited|spent|withdrawn|a/c|acct|upi|card|rs\.?\s?\d|inr\s?\d|₹)', caseSensitive: false);
  static bool _looksFinancial(String body) => _financialHint.hasMatch(body);
}

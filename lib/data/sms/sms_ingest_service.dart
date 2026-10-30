import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:permission_handler/permission_handler.dart';

import '../../core/ids.dart';
import '../../core/theme.dart';
import '../../domain/accounts/default_account.dart';
import '../../domain/cards/card_payment_match.dart';
import '../../domain/cards/card_sms_facts.dart';
import '../../domain/ledger/balance_effects.dart';
import '../../domain/sms/bank_senders.dart';
import '../../domain/sms/card_sms.dart';
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
import '../repositories/entry_removal.dart';
import '../repositories/payee_category_repository.dart';
import '../repositories/sms_log_repository.dart';
import 'sms_channel.dart';
import 'sms_reminder_linker.dart';
import 'sms_sync_cursor.dart';

/// What [SmsIngestService.ingest] did with one message. [pending] means it
/// is waiting in the review queue, whether it was read with low confidence
/// or could not be read at all; [unparsed] means it was dropped.
enum IngestStatus { duplicate, notBank, foreignCurrency, unparsed, pending, added, cardUpdated }

/// An entry that was created from an SMS without the user approving it.
class SmsAutoAdded {
  const SmsAutoAdded({required this.smsId, required this.entryId, required this.amountMinor, required this.isDebit, this.payee});
  final String smsId;
  final String entryId;
  final int amountMinor;
  final bool isDebit;
  final String? payee;
}

/// Whether the logged SMS [row] is still the automatic add of [entryId].
bool isCurrentAutoAdd(SmsLogData? row, String entryId) => row != null && row.status == SmsLogStatus.added && row.entryId == entryId;

/// What one [SmsIngestService.sync] did.
class SmsSyncResult {
  const SmsSyncResult({required this.scanned, required this.pending, required this.added});
  final int scanned;
  final int pending;
  final int added;
}

/// What the SMS log stores about a read message: the parsed transaction, the
/// suggested category and the account it belongs to, if already known.
Map<String, dynamic> smsLogPayload(ParsedTransaction parsed, {String? accountId}) => parsed.toJson()
  ..['suggestedCategory'] = suggestCategoryKey(parsed)
  ..['accountKey'] = parsed.accountKey
  ..['accountId'] = accountId;

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
    this.defaultAccountId,
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

  /// The account the user set as default, read when a card bill payment
  /// needs a bank to come from; null treats it as unset.
  final String Function()? defaultAccountId;

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

    final cardStatus = await _ingestCardSms(id, message, autoAdd: autoAdd);
    if (cardStatus != null) return cardStatus;

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
    if (known != null) await _applyReportedFigures(known.id, parsed);
    final payload = smsLogPayload(parsed, accountId: known?.id);

    // The bank's side of a card bill payment already recorded from the card's
    // SMS completes that transfer instead of becoming an expense.
    final paidCard = await _linkBankDebitToCardPayment(parsed, message.body);
    if (paidCard != null) {
      await smsLog.record(id: id, sender: message.sender, body: message.body, receivedAt: message.receivedAt, status: SmsLogStatus.added, parsed: payload, entryId: paidCard, transactionKey: transactionKey);
      return IngestStatus.added;
    }

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
  Future<void> undoAutoAdd(SmsAutoAdded added) => _undoAdd(smsId: added.smsId, entryId: added.entryId);

  /// Undo from the notification of an automatic add, possibly long after it
  /// was posted: only while the SMS is still logged as added with
  /// [entryId], so a repeated tap or an entry already undone or re-saved is
  /// left alone. True when the add was undone.
  Future<bool> undoAutoAddIfCurrent({required String smsId, required String entryId}) async {
    if (!isCurrentAutoAdd(await smsLog.getById(smsId), entryId)) return false;
    await _undoAdd(smsId: smsId, entryId: entryId);
    return true;
  }

  Future<void> _undoAdd({required String smsId, required String entryId}) async {
    await reminderLinker?.unlinkEntry(smsId: smsId, entryId: entryId);
    await entries.deleteEntry(entryId);
    await smsLog.setStatus(smsId, SmsLogStatus.ignored);
  }

  /// Moves the entry an SMS added to [categoryId] and remembers it for the
  /// SMS payee. False (nothing written) when the entry is gone or the
  /// category is not usable for it.
  Future<bool> changeSmsEntryCategory({required String smsId, required String entryId, required String categoryId}) async {
    final details = await entries.getEntry(entryId);
    if (details == null || details.entry.deletedAt != null) return false;
    if (!isUsablePayeeCategory(await categories.byId(categoryId), details.entry.kind)) return false;
    if (!await entries.setCategory(entryId, categoryId)) return false;
    await rememberCategoryForSms(smsId, categoryId);
    return true;
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
    final payment = parseCardPaymentSms(sender: row.sender, body: row.body, receivedAt: row.receivedAt);
    if (payment != null) return _approveCardPayment(row, payment);
    final parsed = parseBankSms(sender: row.sender, body: row.body, receivedAt: row.receivedAt);
    if (parsed == null) return null;
    final paidCard = await _linkBankDebitToCardPayment(parsed, row.body);
    if (paidCard != null) {
      await smsLog.setStatus(row.id, SmsLogStatus.added, entryId: paidCard);
      return paidCard;
    }
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
    final existing = await accounts.findBySmsKey(parsed.accountKey);
    if (existing != null) return existing;
    final created = await _createSmsAccount(bank: parsed.bank, isCreditCard: parsed.isCreditCard, last4: parsed.accountLast4, key: parsed.accountKey);
    await _applyReportedFigures(created.id, parsed);
    return created;
  }

  Future<Account> _createSmsAccount({required String? bank, required bool isCreditCard, required String? last4, required String key}) => accounts.create(
        name: smsAccountName(bank: bank, isCreditCard: isCreditCard, last4: last4),
        type: isCreditCard ? 'card' : 'bank',
        color: kPaletteColors[key.hashCode.abs() % kPaletteColors.length],
        bankName: bank ?? 'Bank',
        last4: last4,
        smsKey: key,
        includeInTotal: !isCreditCard,
      );

  /// The balance and, for a card, the available limit the message reports.
  Future<void> _applyReportedFigures(String accountId, ParsedTransaction parsed) async {
    if (parsed.balanceMinor != null) await accounts.applyReportedBalance(accountId, parsed.balanceMinor!, parsed.occurredAt);
    if (parsed.isCreditCard && parsed.availableLimitMinor != null) {
      await accounts.applyReportedLimit(accountId, parsed.availableLimitMinor!, parsed.occurredAt);
    }
  }

  /// The card account a card SMS belongs to: the one with its SMS key, else
  /// the single card that fits its bank and digits ([matchingCardId]).
  Future<Account?> _findCard({required String? bank, required String? last4, required String key}) async {
    final byKey = await accounts.findBySmsKey(key);
    if (byKey != null) return byKey;
    final all = await accounts.getAll();
    final id = matchingCardId(all, bank: bank, last4: last4);
    return id == null ? null : all.firstWhere((account) => account.id == id);
  }

  /// A card statement or card bill payment SMS; null for any other message.
  Future<IngestStatus?> _ingestCardSms(String id, RawSms message, {required bool autoAdd}) async {
    final statement = parseCardStatementSms(sender: message.sender, body: message.body, receivedAt: message.receivedAt);
    if (statement != null) return _ingestStatement(id, message, statement);
    final payment = parseCardPaymentSms(sender: message.sender, body: message.body, receivedAt: message.receivedAt);
    if (payment != null) return _ingestCardPayment(id, message, payment, autoAdd: autoAdd);
    return null;
  }

  /// Puts the statement on its card, which moves the card's due reminder.
  /// A statement that names no card digits and fits no card is not kept.
  Future<IngestStatus> _ingestStatement(String id, RawSms message, CardStatementSms statement) async {
    final card = await _findCard(bank: statement.bank, last4: statement.cardLast4, key: statement.accountKey) ??
        (statement.cardLast4 == null ? null : await _createSmsAccount(bank: statement.bank, isCreditCard: true, last4: statement.cardLast4, key: statement.accountKey));
    if (card == null) {
      await smsLog.record(id: id, sender: message.sender, body: message.body, receivedAt: message.receivedAt, status: SmsLogStatus.skipped);
      return IngestStatus.unparsed;
    }
    final fields = cardStatementFromSms(statement, statementDay: card.statementDay, dueDay: card.dueDay, lastStatementAt: card.lastStatementAt);
    if (fields != null) await accounts.applySmsStatement(card.id, fields);
    await smsLog.record(id: id, sender: message.sender, body: message.body, receivedAt: message.receivedAt, status: SmsLogStatus.added);
    return IngestStatus.cardUpdated;
  }

  /// A bill payment the card received: the bank debit already recorded for
  /// it becomes the transfer; otherwise, with auto-add on, a transfer from
  /// the default bank account; otherwise it waits for review.
  Future<IngestStatus> _ingestCardPayment(String id, RawSms message, CardPaymentSms payment, {required bool autoAdd}) async {
    final transactionKey = smsTransactionKey(
      body: message.body,
      direction: kCardPaymentDirection,
      amountMinor: payment.amountMinor,
      occurredAt: payment.occurredAt,
      reference: payment.reference,
    );
    if (await smsLog.hasTransaction(transactionKey)) return IngestStatus.duplicate;
    final card = await _findCard(bank: payment.bank, last4: payment.cardLast4, key: payment.accountKey);
    if (card != null && payment.availableLimitMinor != null) {
      await accounts.applyReportedLimit(card.id, payment.availableLimitMinor!, payment.occurredAt);
    }
    final payload = cardPaymentPayload(payment, cardAccountId: card?.id);
    Future<void> record(String status, {String? entryId}) => smsLog.record(
          id: id,
          sender: message.sender,
          body: message.body,
          receivedAt: message.receivedAt,
          status: status,
          parsed: payload,
          entryId: entryId,
          transactionKey: transactionKey,
        );

    final linked = card == null ? null : await _linkCardPaymentToBankDebit(payment, card.id);
    if (linked != null) {
      await record(SmsLogStatus.added, entryId: linked);
      return IngestStatus.added;
    }
    final entryId = card == null || !autoAdd ? null : await _addCardPaymentTransfer(id, payment, card.id);
    if (entryId == null) {
      await record(SmsLogStatus.pending);
      return IngestStatus.pending;
    }
    await record(SmsLogStatus.added, entryId: entryId);
    _autoAddedController.add(SmsAutoAdded(smsId: id, entryId: entryId, amountMinor: payment.amountMinor, isDebit: true));
    return IngestStatus.added;
  }

  Future<String?> _approveCardPayment(SmsLogData row, CardPaymentSms payment) async {
    final card = await _findCard(bank: payment.bank, last4: payment.cardLast4, key: payment.accountKey) ??
        await _createSmsAccount(bank: payment.bank, isCreditCard: true, last4: payment.cardLast4, key: payment.accountKey);
    final entryId = await _linkCardPaymentToBankDebit(payment, card.id) ?? await _addCardPaymentTransfer(row.id, payment, card.id);
    if (entryId != null) await smsLog.setStatus(row.id, SmsLogStatus.added, entryId: entryId);
    return entryId;
  }

  /// A transfer from the bank account the payment is taken to come from
  /// ([cardPaymentSourceAccountId]) into [cardId]; null when there is none.
  Future<String?> _addCardPaymentTransfer(String smsId, CardPaymentSms payment, String cardId) async {
    final fromAccountId = cardPaymentSourceAccountId(await accounts.getAll(), configuredId: defaultAccountId?.call() ?? '');
    if (fromAccountId == null) return null;
    final id = newId();
    await entries.saveEntry(EntriesRepository.newExpense(
      id: id,
      kind: 'transfer',
      amountMinor: payment.amountMinor,
      occurredAt: payment.occurredAt,
      accountId: fromAccountId,
      note: smsEntryNote(reference: payment.reference, rawCounterparty: null),
      source: 'sms',
      smsId: smsId,
    ).copyWith(toAccountId: Value(cardId)));
    return id;
  }

  /// Turns the bank debit that paid this card bill into the transfer to
  /// [cardId]. Returns its id, or null when no single debit fits.
  Future<String?> _linkCardPaymentToBankDebit(CardPaymentSms payment, String cardId) async {
    final debits = await entries.bankDebitsBetween(
      amountMinor: payment.amountMinor,
      from: payment.occurredAt.subtract(kCardPaymentMatchWindow),
      to: payment.occurredAt.add(kCardPaymentMatchWindow),
    );
    final candidates = [
      for (final debit in debits)
        CardPaymentCandidate(
          entryId: debit.id,
          amountMinor: debit.amountMinor,
          occurredAt: debit.occurredAt,
          hintsCardBill: hintsCardBillPayment('${debit.payee ?? ''} ${debit.note} ${await _smsBodyOf(debit.smsId)}'),
        ),
    ];
    final match = pickCardPaymentMatch(candidates, amountMinor: payment.amountMinor, at: payment.occurredAt);
    if (match == null) return null;
    final debit = debits.firstWhere((entry) => entry.id == match.entryId);
    await entries.setTransfer(debit.id, toAccountId: cardId);
    final previous = snapshotOfEntry(debit);
    await accounts.applyBalanceDeltas(editDeltas(
      previous: previous,
      next: EntrySnapshot(kind: 'transfer', amountMinor: debit.amountMinor, accountId: debit.accountId, toAccountId: cardId, source: debit.source, groupId: debit.groupId),
    ));
    return debit.id;
  }

  Future<String> _smsBodyOf(String? smsId) async => smsId == null ? '' : (await smsLog.getById(smsId))?.body ?? '';

  /// When [parsed] is a bank debit paying a card bill already recorded from
  /// the card's SMS (a transfer no bank SMS completed yet), moves that
  /// transfer onto this bank account and returns its id; otherwise null.
  Future<String?> _linkBankDebitToCardPayment(ParsedTransaction parsed, String body) async {
    if (!parsed.isDebit || parsed.isCreditCard) return null;
    final payments = await entries.smsCardPaymentsBetween(
      amountMinor: parsed.amountMinor,
      from: parsed.occurredAt.subtract(kCardPaymentMatchWindow),
      to: parsed.occurredAt.add(kCardPaymentMatchWindow),
    );
    final hinted = hintsCardBillPayment(body);
    final candidates = [
      for (final payment in payments)
        if (await _awaitsBankSide(payment))
          CardPaymentCandidate(entryId: payment.id, amountMinor: payment.amountMinor, occurredAt: payment.occurredAt, hintsCardBill: hinted),
    ];
    final match = pickCardPaymentMatch(candidates, amountMinor: parsed.amountMinor, at: parsed.occurredAt);
    if (match == null) return null;
    final bank = await _ensureAccount(parsed);
    final payment = payments.firstWhere((entry) => entry.id == match.entryId);
    await entries.setTransfer(payment.id, fromAccountId: bank?.id, toAccountId: payment.toAccountId!);
    return payment.id;
  }

  /// Whether no SMS other than the card's own (and its re-deliveries) points
  /// at the transfer [payment] yet.
  Future<bool> _awaitsBankSide(Entry payment) async =>
      (await smsLog.forEntry(payment.id)).every((row) => row.id == payment.smsId || row.status == SmsLogStatus.duplicate);

  /// Personal chats are never ingested, however much they read like a debit.
  static bool _worthIngesting(RawSms message) =>
      isBusinessSender(message.sender) && (looksLikeBankSender(message.sender) || hasTransactionSignal(message.body));
}

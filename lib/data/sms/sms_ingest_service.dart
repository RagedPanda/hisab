import 'dart:async';

import 'package:permission_handler/permission_handler.dart';

import '../../core/ids.dart';
import '../../core/theme.dart';
import '../../domain/sms/bank_senders.dart';
import '../../domain/sms/parsed_transaction.dart';
import '../../domain/sms/sms_account_name.dart';
import '../../domain/sms/payee_normaliser.dart';
import '../../domain/sms/sms_categorizer.dart';
import '../../domain/sms/sms_outcome.dart';
import '../../domain/sms/sms_parser.dart';
import '../db/database.dart';
import '../repositories/accounts_repository.dart';
import '../repositories/categories_repository.dart';
import '../repositories/entries_repository.dart';
import '../repositories/sms_log_repository.dart';
import 'sms_channel.dart';

enum IngestStatus { duplicate, notBank, unparsed, pending, added }

/// Turns raw SMS into log rows, accounts and (optionally) entries.
class SmsIngestService {
  SmsIngestService({
    required this.smsLog,
    required this.accounts,
    required this.categories,
    required this.entries,
  });

  final SmsLogRepository smsLog;
  final AccountsRepository accounts;
  final CategoriesRepository categories;
  final EntriesRepository entries;

  StreamSubscription<RawSms>? _liveSubscription;

  Future<bool> requestPermission() async {
    if (!SmsChannel.isSupported) return false;
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async => SmsChannel.isSupported && await Permission.sms.isGranted;

  /// Scans the inbox for bank messages newer than the last one we logged
  /// (or [lookback] if the log is empty). Returns how many were queued/added.
  Future<({int scanned, int pending, int added})> scanInbox({Duration lookback = const Duration(days: 90), required bool autoAdd}) async {
    final since = (await smsLog.latestReceivedAt()) ?? DateTime.now().subtract(lookback);
    final messages = await SmsChannel.readInbox(since: since.subtract(const Duration(minutes: 1)));
    var pending = 0;
    var added = 0;
    for (final message in messages) {
      final status = await ingest(message, autoAdd: autoAdd);
      if (status == IngestStatus.pending) pending++;
      if (status == IngestStatus.added) added++;
    }
    return (scanned: messages.length, pending: pending, added: added);
  }

  void startListening({required bool Function() autoAdd}) {
    _liveSubscription ??= SmsChannel.incoming().listen((message) => ingest(message, autoAdd: autoAdd()));
  }

  void stopListening() {
    _liveSubscription?.cancel();
    _liveSubscription = null;
  }

  /// Handles one message end to end. Safe to call repeatedly for the same SMS.
  Future<IngestStatus> ingest(RawSms message, {required bool autoAdd, bool force = false}) async {
    final id = SmsLogRepository.idFor(message.sender, message.body, message.receivedAt);
    final existing = await smsLog.getById(id);
    if (existing != null) {
      await _recordDuplicate(existing, message);
      return IngestStatus.duplicate;
    }
    if (!force && !looksLikeBankSender(message.sender) && !_looksFinancial(message.body)) {
      if (!isPersonalSender(message.sender)) {
        await smsLog.record(id: id, sender: message.sender, body: message.body, receivedAt: message.receivedAt, status: SmsLogStatus.notBank);
      }
      return IngestStatus.notBank;
    }

    final parsed = parseBankSms(sender: message.sender, body: message.body, receivedAt: message.receivedAt);
    if (parsed == null) {
      if (force || looksLikeBankSender(message.sender)) {
        await smsLog.record(id: id, sender: message.sender, body: message.body, receivedAt: message.receivedAt, status: SmsLogStatus.skipped);
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
      await smsLog.record(id: id, sender: message.sender, body: message.body, receivedAt: message.receivedAt, status: SmsLogStatus.pending, parsed: payload);
      return IngestStatus.pending;
    }
    final account = await _ensureAccount(parsed);
    final entryId = await _createEntry(id, parsed, categoryKey, account?.id);
    await smsLog.record(id: id, sender: message.sender, body: message.body, receivedAt: message.receivedAt, status: SmsLogStatus.added, parsed: payload, entryId: entryId);
    return IngestStatus.added;
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
    if (isSameDelivery(original.receivedAt, message.receivedAt)) return;
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
    final entryId = await _createEntry(row.id, parsed, suggestCategoryKey(parsed), account?.id);
    await smsLog.setStatus(row.id, SmsLogStatus.added, entryId: entryId);
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

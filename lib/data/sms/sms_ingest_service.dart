import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:permission_handler/permission_handler.dart';

import '../../core/ids.dart';
import '../../core/theme.dart';
import '../../domain/sms/bank_senders.dart';
import '../../domain/sms/parsed_transaction.dart';
import '../../domain/sms/sms_categorizer.dart';
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
    if (await smsLog.exists(id)) return IngestStatus.duplicate;
    if (!force && !looksLikeBankSender(message.sender) && !_looksFinancial(message.body)) return IngestStatus.notBank;

    final parsed = parseBankSms(sender: message.sender, body: message.body, receivedAt: message.receivedAt);
    if (parsed == null) {
      if (force || looksLikeBankSender(message.sender)) {
        await smsLog.record(id: id, sender: message.sender, body: message.body, receivedAt: message.receivedAt, status: 'skipped');
      }
      return IngestStatus.unparsed;
    }

    final account = await _ensureAccount(parsed);
    if (account != null && parsed.balanceMinor != null) {
      await accounts.applyReportedBalance(account.id, parsed.balanceMinor!, parsed.occurredAt);
    }
    final categoryKey = suggestCategoryKey(parsed);
    final payload = parsed.toJson()
      ..['suggestedCategory'] = categoryKey
      ..['accountKey'] = parsed.accountKey
      ..['accountId'] = account?.id;

    if (!autoAdd) {
      await smsLog.record(id: id, sender: message.sender, body: message.body, receivedAt: message.receivedAt, status: 'pending', parsed: payload);
      return IngestStatus.pending;
    }
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
      payee: parsed.counterparty,
      note: parsed.reference == null ? '' : 'Ref ${parsed.reference}',
      source: 'sms',
      smsId: smsId,
    ));
    return id;
  }

  Future<Account?> _ensureAccount(ParsedTransaction parsed) async {
    final key = parsed.accountKey;
    final existing = await accounts.findBySmsKey(key);
    if (existing != null) return existing;
    final bank = parsed.bank ?? 'Bank';
    final suffix = parsed.accountLast4 == null ? '' : ' ••${parsed.accountLast4}';
    final created = await accounts.create(
      name: parsed.isCreditCard ? '$bank Card$suffix' : '$bank$suffix',
      type: parsed.isCreditCard ? 'card' : 'bank',
      color: kPaletteColors[key.hashCode.abs() % kPaletteColors.length],
      bankName: bank,
      last4: parsed.accountLast4,
      smsKey: key,
    );
    if (parsed.isCreditCard) {
      await accounts.update(AccountsCompanion(id: Value(created.id), includeInTotal: const Value(false)));
    }
    return created;
  }

  static final _financialHint = RegExp(r'(debited|credited|spent|withdrawn|a/c|acct|upi|card|rs\.?\s?\d|inr\s?\d|₹)', caseSensitive: false);
  static bool _looksFinancial(String body) => _financialHint.hasMatch(body);
}

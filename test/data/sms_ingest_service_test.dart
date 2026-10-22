import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/accounts_repository.dart';
import 'package:hisab/data/repositories/categories_repository.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/sms_log_repository.dart';
import 'package:hisab/data/sms/sms_channel.dart';
import 'package:hisab/data/sms/sms_ingest_service.dart';
import 'package:hisab/data/sms/sms_sync_cursor.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _upiDebit = 'Rs.459.00 debited from A/c XX1234 on 21-10-26 to swiggy@ybl (UPI Ref No 123456789012). Avl bal Rs.15,541.00';
const _atmDebit = 'Rs.4,000.00 withdrawn from A/c XX1234 at ATM on 21-10-26. Avl bal Rs.11,541.00';

void main() {
  late AppDatabase db;
  late AccountsRepository accounts;
  late SmsLogRepository smsLog;
  late SmsIngestService service;
  late FakeSmsSource source;
  late SmsSyncCursor cursor;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    accounts = AccountsRepository(db);
    smsLog = SmsLogRepository(db);
    source = FakeSmsSource();
    cursor = SmsSyncCursor(await SharedPreferences.getInstance());
    service = SmsIngestService(smsLog: smsLog, accounts: accounts, categories: CategoriesRepository(db), entries: EntriesRepository(db), cursor: cursor, source: source);
  });

  tearDown(() => db.close());

  Future<List<String>> accountNames() async => (await accounts.getAll()).map((a) => a.name).toList();

  test('IOS-04: a pending SMS creates no account until it is approved', () async {
    final received = DateTime(2026, 10, 21, 10, 0);
    final status = await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: false);
    expect(status, IngestStatus.pending);
    expect(await accountNames(), ['Cash'], reason: 'only the seeded Cash account exists');

    final row = (await smsLog.watchPending().first).single;
    await smsLog.setStatus(row.id, 'ignored');
    expect(await accountNames(), ['Cash']);
  });

  test('approving a pending SMS creates the account with the reported balance', () async {
    final received = DateTime(2026, 10, 21, 10, 0);
    await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: false);
    final row = (await smsLog.watchPending().first).single;
    final entryId = await service.approvePending(row);
    expect(entryId, isNotNull);
    final created = (await accounts.getAll()).firstWhere((a) => a.name != 'Cash');
    expect(created.name, 'HDFC Bank ••1234');
    expect(created.balanceMinor, 1554100);
  });

  test('AND-10: the same message received a minute later is a duplicate and cannot roll the balance back', () async {
    final first = DateTime(2026, 10, 21, 10, 0);
    await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: first), autoAdd: true);
    await service.ingest(RawSms(sender: 'HDFCBK', body: _atmDebit, receivedAt: first.add(const Duration(seconds: 30))), autoAdd: true);
    final account = (await accounts.getAll()).firstWhere((a) => a.name != 'Cash');
    expect(account.balanceMinor, 1154100);

    final again = await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: first.add(const Duration(minutes: 1))), autoAdd: true);
    expect(again, IngestStatus.duplicate);
    expect((await accounts.getAll()).firstWhere((a) => a.name != 'Cash').balanceMinor, 1154100);
  });

  test('idFor buckets by calendar day, not by minute', () {
    final morning = DateTime(2026, 10, 21, 9, 0);
    expect(SmsLogRepository.idFor('HDFCBK', _upiDebit, morning), SmsLogRepository.idFor('HDFCBK', _upiDebit, morning.add(const Duration(hours: 5))));
    expect(SmsLogRepository.idFor('HDFCBK', _upiDebit, morning), isNot(SmsLogRepository.idFor('HDFCBK', _upiDebit, morning.add(const Duration(days: 1)))));
  });

  group('sync', () {
    final now = DateTime(2026, 10, 22, 12);
    final morning = DateTime(2026, 10, 22, 9);

    test('ingests messages queued while the app was closed', () async {
      source.queue.add(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: morning));
      final result = await service.sync(autoAdd: false, now: now);
      expect(result.scanned, 1);
      expect(result.pending, 1);
      expect(source.queue, isEmpty, reason: 'draining empties the native queue');
    });

    test('a message both queued and in the inbox is ingested once', () async {
      final sms = RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: morning);
      source.queue.add(sms);
      source.inbox.add(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: morning.add(const Duration(seconds: 2))));
      final result = await service.sync(autoAdd: true, now: now);
      expect(result.scanned, 2);
      expect(result.added, 1);
      expect((await db.select(db.entries).get()).length, 1);
    });

    test('the inbox scan starts at the stored cursor and advances it', () async {
      final older = DateTime(2026, 10, 20, 9);
      await cursor.write(older);
      source.inbox.add(RawSms(sender: 'HDFCBK', body: _atmDebit, receivedAt: morning));
      await service.sync(autoAdd: false, now: now);
      expect(source.lastSince, older.subtract(const Duration(minutes: 1)));
      expect(cursor.read(), morning);
    });

    test('a first sync looks back the full window', () async {
      await service.sync(autoAdd: false, now: now, lookback: const Duration(days: 90));
      expect(source.lastSince, now.subtract(const Duration(days: 90, minutes: 1)));
      expect(cursor.read(), isNull, reason: 'nothing seen, nothing to remember');
    });

    test('overlapping calls run one after the other', () async {
      source.queue.add(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: morning));
      final results = await Future.wait([service.sync(autoAdd: true, now: now), service.sync(autoAdd: true, now: now)]);
      expect(results.map((r) => r.added).toList(), [1, 0]);
    });
  });
}

class FakeSmsSource implements SmsSource {
  final queue = <RawSms>[];
  final inbox = <RawSms>[];
  DateTime? lastSince;

  @override
  Future<List<RawSms>> drainQueue() async {
    final drained = List<RawSms>.of(queue);
    queue.clear();
    return drained;
  }

  @override
  Future<List<RawSms>> readInbox({required DateTime since}) async {
    lastSince = since;
    return inbox.where((sms) => sms.receivedAt.isAfter(since)).toList();
  }
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/accounts_repository.dart';
import 'package:hisab/data/repositories/categories_repository.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/sms_log_repository.dart';
import 'package:hisab/data/sms/sms_channel.dart';
import 'package:hisab/data/sms/sms_ingest_service.dart';

const _upiDebit = 'Rs.459.00 debited from A/c XX1234 on 21-10-26 to swiggy@ybl (UPI Ref No 123456789012). Avl bal Rs.15,541.00';
const _atmDebit = 'Rs.4,000.00 withdrawn from A/c XX1234 at ATM on 21-10-26. Avl bal Rs.11,541.00';

void main() {
  late AppDatabase db;
  late AccountsRepository accounts;
  late SmsLogRepository smsLog;
  late SmsIngestService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    accounts = AccountsRepository(db);
    smsLog = SmsLogRepository(db);
    service = SmsIngestService(smsLog: smsLog, accounts: accounts, categories: CategoriesRepository(db), entries: EntriesRepository(db));
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

  group('auto-add', () {
    final received = DateTime(2026, 10, 21, 10, 0);

    test('a confident bank SMS is added straight away and announced', () async {
      final announced = <SmsAutoAdded>[];
      final subscription = service.autoAdded.listen(announced.add);
      final status = await service.ingest(RawSms(sender: 'VM-HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: true);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(status, IngestStatus.added);
      expect(announced, hasLength(1));
      expect(announced.single.amountMinor, 45900);
      expect(announced.single.isDebit, isTrue);
      final entry = await EntriesRepository(db).getEntry(announced.single.entryId);
      expect(entry!.entry.source, 'sms', reason: 'the entry carries the Added from SMS marker');
      expect(await smsLog.watchPending().first, isEmpty);
    });

    test('a parse without bank or account waits for review even with auto-add on', () async {
      final status = await service.ingest(RawSms(sender: 'PASTED', body: 'Paid Rs 250 to Ramesh', receivedAt: received), autoAdd: true, force: true);
      expect(status, IngestStatus.pending);
      final row = (await smsLog.watchPending().first).single;
      expect(row.parsedJson, isNotNull);
    });

    test('a bank SMS that names an amount but cannot be read goes to the review queue', () async {
      const unread = 'A/c XX1234: transaction of INR 1,200.00 on 21-10-26. Ref 998877';
      final status = await service.ingest(RawSms(sender: 'VM-HDFCBK', body: unread, receivedAt: received), autoAdd: true);
      expect(status, IngestStatus.pending);
      final row = (await smsLog.watchPending().first).single;
      expect(row.parsedJson, isNull);
      expect(await service.approvePending(row), isNull, reason: 'nothing to add without an amount; the card offers Add manually');
    });

    test('an OTP from a bank is logged as skipped, not queued', () async {
      final status = await service.ingest(RawSms(sender: 'VM-HDFCBK', body: 'Your OTP for txn of Rs 500 is 123456. Do not share.', receivedAt: received), autoAdd: true);
      expect(status, IngestStatus.unparsed);
      expect(await smsLog.watchPending().first, isEmpty);
    });

    test('Undo deletes the entry and marks the SMS ignored, not back in the review queue', () async {
      final announced = <SmsAutoAdded>[];
      final subscription = service.autoAdded.listen(announced.add);
      await service.ingest(RawSms(sender: 'VM-HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: true);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      await service.undoAutoAdd(announced.single);
      final entry = await EntriesRepository(db).getEntry(announced.single.entryId);
      expect(entry == null || entry.entry.deletedAt != null, isTrue);
      expect(await smsLog.watchPending().first, isEmpty);
      final row = await smsLog.getById(announced.single.smsId);
      expect(row!.status, 'ignored');
      expect(row.entryId, isNull);
      final again = await service.ingest(RawSms(sender: 'VM-HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: true);
      expect(again, IngestStatus.duplicate, reason: 'a rescan must not add the undone SMS again');
    });
  });
}

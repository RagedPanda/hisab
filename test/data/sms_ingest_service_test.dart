import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/accounts_repository.dart';
import 'package:hisab/data/repositories/categories_repository.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/sms_log_repository.dart';
import 'package:hisab/data/sms/sms_channel.dart';
import 'package:hisab/data/sms/sms_ingest_service.dart';
import 'package:hisab/domain/sms/sms_outcome.dart';

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

  group('SMS history', () {
    final received = DateTime(2026, 10, 21, 10, 0);
    Future<List<SmsHistoryRow>> history() => smsLog.watchHistory().first;

    test('a non-bank message from a business sender is logged as not a bank message', () async {
      final status = await service.ingest(RawSms(sender: 'AMAZON', body: 'Your order has shipped', receivedAt: received), autoAdd: true);
      expect(status, IngestStatus.notBank);
      final row = (await history()).single.log;
      expect(row.status, SmsLogStatus.notBank);
      expect(row.sender, 'AMAZON');
      expect(row.receivedAt, received);
      expect(row.body, isEmpty, reason: 'the text of OTPs and promotions is never stored');
    });

    test('a not-bank message is still recognised without its text and its re-delivery is not logged', () async {
      const otp = 'Your OTP for login is 482913. Do not share it.';
      await service.ingest(RawSms(sender: 'AMAZON', body: otp, receivedAt: received), autoAdd: true);
      final again = await service.ingest(RawSms(sender: 'AMAZON', body: otp, receivedAt: received.add(const Duration(hours: 2))), autoAdd: true);
      expect(again, IngestStatus.duplicate);
      final rows = await history();
      expect(rows.single.log.status, SmsLogStatus.notBank);
      expect(rows.single.log.body, isEmpty);
    });

    test('not-bank text stored by an earlier build is wiped when the database opens', () async {
      await db.into(db.smsLog).insert(SmsLogCompanion.insert(id: 'old', sender: 'AMAZON', body: 'Your OTP is 123456', receivedAt: received, status: SmsLogStatus.notBank));
      await db.into(db.smsLog).insert(SmsLogCompanion.insert(id: 'bank', sender: 'HDFCBK', body: _upiDebit, receivedAt: received, status: SmsLogStatus.skipped));
      await db.wipeNotBankSmsText();
      expect((await smsLog.getById('old'))!.body, isEmpty);
      expect((await smsLog.getById('bank'))!.body, _upiDebit, reason: 'bank messages keep their text');
    });

    test('a message from a person is never kept', () async {
      await service.ingest(RawSms(sender: '+919810000000', body: 'See you at 6', receivedAt: received), autoAdd: true);
      expect(await history(), isEmpty);
    });

    test('a bank re-delivery gets its own duplicate row linked to the original entry', () async {
      await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: true);
      final again = await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received.add(const Duration(minutes: 20))), autoAdd: true);
      expect(again, IngestStatus.duplicate);
      final rows = await history();
      expect(rows.map((row) => row.log.status), [SmsLogStatus.duplicate, SmsLogStatus.added]);
      expect(rows.first.log.entryId, rows.last.log.entryId);
      expect(rows.first.hasEntry, isTrue);

      await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received.add(const Duration(minutes: 20))), autoAdd: true);
      expect(await history(), hasLength(2), reason: 'reading the re-delivery again adds nothing');
    });

    test('reading the same delivery again (live then inbox) is not a duplicate', () async {
      await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: true);
      await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received.add(const Duration(seconds: 4))), autoAdd: true);
      expect((await history()).single.log.status, SmsLogStatus.added);
    });

    test('a deleted entry no longer counts as linked', () async {
      await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: true);
      final row = (await history()).single;
      await EntriesRepository(db).deleteEntry(row.log.entryId!);
      expect((await history()).single.hasEntry, isFalse);
    });

    test('re-processing a dismissed message puts it back up for review', () async {
      await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: false);
      final pending = (await history()).single.log;
      await smsLog.setStatus(pending.id, SmsLogStatus.ignored);

      final status = await service.reprocess((await smsLog.getById(pending.id))!, autoAdd: false);
      expect(status, IngestStatus.pending);
      final row = (await history()).single.log;
      expect(row.id, pending.id);
      expect(row.status, SmsLogStatus.pending);
    });

    test('re-processing an unreadable bank message forces it through the parser again', () async {
      await service.ingest(RawSms(sender: 'HDFCBK', body: 'Your statement is ready on NetBanking.', receivedAt: received), autoAdd: true);
      final row = (await history()).single.log;
      expect(row.status, SmsLogStatus.skipped);
      final status = await service.reprocess(row, autoAdd: true);
      expect(status, IngestStatus.unparsed);
      expect((await history()).single.log.status, SmsLogStatus.skipped);
    });

    test('clearing hides processed messages, keeps pending ones and still blocks re-import', () async {
      await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: true);
      await service.ingest(RawSms(sender: 'HDFCBK', body: _atmDebit, receivedAt: received.add(const Duration(minutes: 5))), autoAdd: false);
      final cleared = await smsLog.clearHistory(now: received.add(const Duration(days: 1)));
      expect(cleared, 1);

      final rows = await history();
      expect(rows.single.log.status, SmsLogStatus.pending);
      final again = await service.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: true);
      expect(again, IngestStatus.duplicate);
      final entries = await db.select(db.entries).get();
      expect(entries, hasLength(1), reason: 'the cleared message is not added a second time');
      final wiped = await smsLog.getById(SmsLogRepository.idFor('HDFCBK', _upiDebit, received));
      expect(wiped!.body, isEmpty);
    });
  });
}

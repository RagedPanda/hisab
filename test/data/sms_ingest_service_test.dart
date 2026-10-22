import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/accounts_repository.dart';
import 'package:hisab/data/repositories/categories_repository.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/sms_log_repository.dart';
import 'package:hisab/data/sms/sms_channel.dart';
import 'package:hisab/data/sms/sms_ingest_service.dart';
import 'package:hisab/data/sms/sms_reminder_linker.dart';
import 'package:hisab/domain/reminders/sms_reminder_match.dart';

import 'fake_reminder_payment_port.dart';

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

  group('paying reminders (R2)', () {
    late FakeReminders reminders;
    late SmsIngestService matchingService;
    final received = DateTime(2026, 10, 21, 10, 0);

    setUp(() {
      reminders = FakeReminders([
        ReminderMatchCandidate(id: 'swiggy-one', kind: 'subscription', title: 'Swiggy One', dueAt: DateTime(2026, 10, 21), amountMinor: 45900, matchKeywords: const ['swiggy']),
      ]);
      matchingService = SmsIngestService(
        smsLog: smsLog,
        accounts: accounts,
        categories: CategoriesRepository(db),
        entries: EntriesRepository(db),
        reminderLinker: SmsReminderLinker(smsLog: smsLog, reminders: reminders),
      );
    });

    test('an auto-added SMS pays the reminder it matches with the new entry', () async {
      await matchingService.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: true);
      final row = (await smsLog.watchRecent().first).single;
      expect(reminders.paid.single, (reminderId: 'swiggy-one', entryId: row.entryId!));
      expect(row.matchedReminderId, 'swiggy-one');
    });

    test('a pending SMS pays nothing until it is approved', () async {
      await matchingService.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: false);
      expect(reminders.paid, isEmpty);
      final entryId = await matchingService.approvePending((await smsLog.watchPending().first).single);
      expect(reminders.paid.single, (reminderId: 'swiggy-one', entryId: entryId!));
    });

    test('an SMS saved from the editor pays the reminder on linkSavedEntry', () async {
      await matchingService.ingest(RawSms(sender: 'HDFCBK', body: _upiDebit, receivedAt: received), autoAdd: false);
      final row = (await smsLog.watchPending().first).single;
      expect(await matchingService.linkSavedEntry(row.id, 'edited-entry'), 'swiggy-one');
      expect(reminders.paid.single, (reminderId: 'swiggy-one', entryId: 'edited-entry'));
    });

    test('an SMS that matches nothing leaves reminders alone', () async {
      await matchingService.ingest(RawSms(sender: 'HDFCBK', body: _atmDebit, receivedAt: received), autoAdd: true);
      expect(reminders.paid, isEmpty);
    });
  });
}

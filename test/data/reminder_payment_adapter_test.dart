import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/notifications/notification_service.dart';
import 'package:hisab/core/notifications/reminder_alert_text.dart';
import 'package:hisab/core/notifications/reminder_payload.dart';
import 'package:hisab/core/notifications/reminder_scheduler.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/accounts_repository.dart';
import 'package:hisab/data/repositories/reminders_repository.dart';
import 'package:hisab/data/repositories/sms_log_repository.dart';
import 'package:hisab/data/sms/reminder_payment_adapter.dart';
import 'package:hisab/data/sms/sms_reminder_linker.dart';
import 'package:hisab/domain/reminders/reminder_draft.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:hisab/domain/sms/parsed_transaction.dart';

import '../core/fake_notification_gateway.dart';

void main() {
  late AppDatabase db;
  late RemindersRepository reminders;
  late AccountsRepository accounts;
  late SmsLogRepository smsLog;
  late FakeNotificationGateway gateway;
  late SmsReminderLinker linker;
  late ReminderScheduler scheduler;
  final now = DateTime(2026, 11, 5, 9);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    reminders = RemindersRepository(db, clock: () => now);
    accounts = AccountsRepository(db);
    smsLog = SmsLogRepository(db);
    gateway = FakeNotificationGateway();
    scheduler = ReminderScheduler(
      reminders: reminders,
      notifications: NotificationService(gateway,
          buildAlert: (reminder, alert) => alertRequestFor(reminder, alert, notificationLocalizations('en'), currencySymbol: '₹'), clock: () => now),
      clock: () => now,
    );
    linker = SmsReminderLinker(smsLog: smsLog, reminders: ReminderPaymentAdapter(reminders: reminders, scheduler: scheduler, accounts: accounts));
  });

  tearDown(() => db.close());

  ParsedTransaction emiDebit(int amountMinor) => ParsedTransaction(
        direction: TxnDirection.debit,
        amountMinor: amountMinor,
        instrument: Instrument.emi,
        occurredAt: now,
        raw: 'EMI of Rs 12,345 debited from HDFC Bank A/c XX1234',
        bank: 'HDFC Bank',
        accountLast4: '1234',
      );

  Future<String> carLoan() async {
    final account = await accounts.create(name: 'HDFC 1234', type: 'bank', color: 0, bankName: 'HDFC Bank', last4: '1234');
    return reminders.save(ReminderDraft(
      kind: ReminderKind.emi,
      title: 'Car loan',
      dueAt: DateTime(2026, 11, 5),
      amountMinor: 1234500,
      accountId: account.id,
      repeat: ReminderRepeat.monthly,
    ));
  }

  test('an EMI debit from the reminder bank marks it paid, links the entry and rolls to next month', () async {
    final reminderId = await carLoan();
    await smsLog.record(id: 's1', sender: 'HDFCBK', body: 'emi', receivedAt: now, status: 'added', entryId: 'e1');

    expect(await linker.linkEntry(smsId: 's1', parsed: emiDebit(1234500), entryId: 'e1'), reminderId);

    final paid = await reminders.getById(reminderId);
    expect(paid!.status, ReminderStatus.done);
    expect(paid.entryId, 'e1');
    final next = await reminders.getById(paid.nextId!);
    expect(next!.dueAt, DateTime(2026, 12, 5));
    expect(next.status, ReminderStatus.pending);
    expect((await smsLog.getById('s1'))!.matchedReminderId, reminderId);
    expect(gateway.alertsFor(reminderPayload(reminderId)), isEmpty, reason: 'the paid occurrence stops notifying');
  });

  test('undoing the SMS payment reopens the EMI, drops next month and brings its alerts back (decision 19)', () async {
    final account = await accounts.create(name: 'HDFC 1234', type: 'bank', color: 0, bankName: 'HDFC Bank', last4: '1234');
    final reminderId = await scheduler.save(ReminderDraft(
      kind: ReminderKind.emi,
      title: 'Car loan',
      dueAt: DateTime(2026, 11, 12),
      amountMinor: 1234500,
      accountId: account.id,
      repeat: ReminderRepeat.monthly,
      remindDaysBefore: const [0, 3],
    ));
    final alertsBefore = gateway.alertsFor(reminderPayload(reminderId)).map((alert) => alert.fireAt).toList();
    expect(alertsBefore, isNotEmpty);
    await smsLog.record(id: 's1', sender: 'HDFCBK', body: 'emi', receivedAt: now, status: 'added', entryId: 'e1');
    await linker.linkEntry(smsId: 's1', parsed: emiDebit(1234500), entryId: 'e1');
    final nextId = (await reminders.getById(reminderId))!.nextId!;

    expect(await linker.unlinkEntry(smsId: 's1', entryId: 'e1'), reminderId);

    final reopened = (await reminders.getById(reminderId))!;
    expect(reopened.status, ReminderStatus.pending);
    expect(reopened.entryId, isNull);
    expect(await reminders.getById(nextId), isNull, reason: 'the occurrence the payment spawned is dropped');
    expect(gateway.alertsFor(reminderPayload(reminderId)).map((alert) => alert.fireAt), alertsBefore, reason: 'its alerts are rescheduled');
    expect(gateway.alertsFor(reminderPayload(nextId)), isEmpty);
    expect((await smsLog.getById('s1'))!.matchedReminderId, isNull, reason: 'a later payment may pay it again');
  });

  test('undo leaves a reminder alone that was since paid by another entry', () async {
    final reminderId = await carLoan();
    await smsLog.record(id: 's1', sender: 'HDFCBK', body: 'emi', receivedAt: now, status: 'added', entryId: 'e1');
    await linker.linkEntry(smsId: 's1', parsed: emiDebit(1234500), entryId: 'e1');
    await reminders.undoDone(reminderId);
    await reminders.markDone(reminderId, entryId: 'manual-entry');

    await linker.unlinkEntry(smsId: 's1', entryId: 'e1');

    final row = (await reminders.getById(reminderId))!;
    expect(row.status, ReminderStatus.done);
    expect(row.entryId, 'manual-entry');
  });

  test('an EMI debit one rupee off leaves the reminder pending', () async {
    final reminderId = await carLoan();
    await smsLog.record(id: 's1', sender: 'HDFCBK', body: 'emi', receivedAt: now, status: 'added', entryId: 'e1');
    expect(await linker.linkEntry(smsId: 's1', parsed: emiDebit(1234600), entryId: 'e1'), isNull);
    expect((await reminders.getById(reminderId))!.status, ReminderStatus.pending);
  });

  test('documents and reminders without an amount are never candidates', () async {
    await reminders.save(ReminderDraft(kind: ReminderKind.document, title: 'PUC', dueAt: DateTime(2026, 11, 5)));
    await reminders.save(ReminderDraft(kind: ReminderKind.bill, title: 'Water', dueAt: DateTime(2026, 11, 5)));
    final adapter = ReminderPaymentAdapter(reminders: reminders, scheduler: ReminderScheduler(reminders: reminders, notifications: NotificationService(gateway, buildAlert: (r, a) => alertRequestFor(r, a, notificationLocalizations('en'), currencySymbol: '₹'))), accounts: accounts);
    expect(await adapter.pendingCandidates(), isEmpty);
  });
}

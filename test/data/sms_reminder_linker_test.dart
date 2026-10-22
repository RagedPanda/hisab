import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/sms_log_repository.dart';
import 'package:hisab/data/sms/sms_reminder_linker.dart';
import 'package:hisab/domain/reminders/sms_reminder_match.dart';
import 'package:hisab/domain/sms/parsed_transaction.dart';

class FakeReminders implements ReminderPaymentPort {
  FakeReminders(this.pending);
  final List<ReminderMatchCandidate> pending;
  final List<({String reminderId, String entryId, DateTime paidAt})> paid = [];

  @override
  Future<List<ReminderMatchCandidate>> pendingCandidates() async => pending;

  @override
  Future<void> markPaidBySms({required String reminderId, required String entryId, required DateTime paidAt}) async {
    paid.add((reminderId: reminderId, entryId: entryId, paidAt: paidAt));
    pending.removeWhere((candidate) => candidate.id == reminderId);
  }
}

void main() {
  late AppDatabase db;
  late SmsLogRepository smsLog;
  late FakeReminders reminders;
  late SmsReminderLinker linker;

  final paidAt = DateTime(2026, 11, 4, 10);
  final bescomDebit = ParsedTransaction(
    direction: TxnDirection.debit,
    amountMinor: 152000,
    instrument: Instrument.upi,
    occurredAt: paidAt,
    raw: 'Rs 1520 debited to bescom@okicici',
    bank: 'HDFC Bank',
    counterparty: 'bescom@okicici',
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    smsLog = SmsLogRepository(db);
    reminders = FakeReminders([
      ReminderMatchCandidate(id: 'electricity', kind: 'bill', title: 'Electricity', payee: 'BESCOM', dueAt: DateTime(2026, 11, 5), amountMinor: 150000),
    ]);
    linker = SmsReminderLinker(smsLog: smsLog, reminders: reminders);
    await smsLog.record(id: 's1', sender: 'HDFCBK', body: bescomDebit.raw, receivedAt: paidAt, status: 'added', entryId: 'e1');
  });

  tearDown(() => db.close());

  test('a matching SMS pays the reminder with its entry and is linked to it', () async {
    expect(await linker.linkEntry(smsId: 's1', parsed: bescomDebit, entryId: 'e1'), 'electricity');
    expect(reminders.paid.single, (reminderId: 'electricity', entryId: 'e1', paidAt: paidAt));
    expect((await smsLog.getById('s1'))!.matchedReminderId, 'electricity');
  });

  test('the same SMS never pays a second reminder', () async {
    await linker.linkEntry(smsId: 's1', parsed: bescomDebit, entryId: 'e1');
    reminders.pending.add(ReminderMatchCandidate(id: 'water', kind: 'bill', title: 'Water', payee: 'BESCOM', dueAt: DateTime(2026, 11, 6), amountMinor: 150000));
    expect(await linker.linkEntry(smsId: 's1', parsed: bescomDebit, entryId: 'e1'), isNull);
    expect(reminders.paid, hasLength(1));
  });

  test('a non-matching SMS leaves the reminder pending and the log unlinked', () async {
    final swiggy = ParsedTransaction(direction: TxnDirection.debit, amountMinor: 45900, instrument: Instrument.upi, occurredAt: paidAt, raw: 'Rs 459 debited', counterparty: 'swiggy@ybl');
    expect(await linker.linkEntry(smsId: 's1', parsed: swiggy, entryId: 'e1'), isNull);
    expect(reminders.paid, isEmpty);
    expect((await smsLog.getById('s1'))!.matchedReminderId, isNull);
  });
}

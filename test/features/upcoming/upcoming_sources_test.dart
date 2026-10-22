import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/recurring_repository.dart';
import 'package:hisab/data/repositories/reminders_repository.dart';
import 'package:hisab/domain/reminders/reminder_draft.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/features/upcoming/upcoming_sources.dart';

void main() {
  late AppDatabase db;
  late RecurringRepository recurring;
  final today = DateTime(2026, 10, 22);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    recurring = RecurringRepository(db);
  });
  tearDown(() => db.close());

  RecurringRulesCompanion rule(
    String name, {
    required RecurrenceFrequency frequency,
    required DateTime start,
    bool autoPost = true,
    String? payee,
    int? dayOfMonth,
  }) => RecurringRepository.newRule(
    name: name,
    kind: 'expense',
    amountMinor: 49900,
    payee: payee,
    frequency: frequency,
    dayOfMonth: dayOfMonth,
    startDate: start,
    autoPost: autoPost,
  );

  test('a weekly rule expands into every occurrence of the window', () async {
    await recurring.saveRule(rule('Maid', frequency: RecurrenceFrequency.weekly, start: DateTime(2026, 10, 24, 9)));
    final inputs = recurringOccurrenceInputs(await recurring.getViews(), today: today, start: today, end: DateTime(2026, 11, 8));
    expect(inputs.map((input) => input.dueAt), [DateTime(2026, 10, 24, 9), DateTime(2026, 10, 31, 9), DateTime(2026, 11, 7, 9)]);
    expect(inputs.first.title, 'Maid');
    expect(inputs.first.amountMinor, 49900);
  });

  test('a confirm-first rule past due stays listed; an auto-post one does not', () async {
    await recurring.saveRule(rule('Rent', frequency: RecurrenceFrequency.monthly, dayOfMonth: 5, start: DateTime(2026, 10, 5, 9), autoPost: false));
    await recurring.saveRule(rule('Netflix', frequency: RecurrenceFrequency.monthly, dayOfMonth: 5, start: DateTime(2026, 10, 5, 9)));
    final inputs = recurringOccurrenceInputs(await recurring.getViews(), today: today, start: today, end: DateTime(2026, 11, 1));
    expect(inputs.map((input) => '${input.title} ${input.dueAt.day}'), ['Rent 5']);
  });

  test('paused rules are left out and an unnamed rule falls back to its payee', () async {
    final pausedId = await recurring.saveRule(rule('Gym', frequency: RecurrenceFrequency.monthly, start: DateTime(2026, 10, 25)));
    await recurring.setStatus(pausedId, RecurringStatus.paused);
    await recurring.saveRule(rule('', payee: 'Airtel', frequency: RecurrenceFrequency.monthly, start: DateTime(2026, 10, 28)));
    final inputs = recurringOccurrenceInputs(await recurring.getViews(), today: today, start: today, end: DateTime(2026, 11, 1));
    expect(inputs.map((input) => input.title), ['Airtel']);
  });

  test('pending reminders up to the range end map with their rule link; paid ones drop out', () async {
    final reminders = RemindersRepository(db, clock: () => today);
    await reminders.save(ReminderDraft(kind: ReminderKind.bill, title: 'Electricity', dueAt: DateTime(2026, 10, 18), amountMinor: 184000, recurringId: 'rule-1'));
    final paidId = await reminders.save(ReminderDraft(kind: ReminderKind.bill, title: 'Water', dueAt: DateTime(2026, 10, 24)));
    await reminders.markDone(paidId);
    await reminders.save(ReminderDraft(kind: ReminderKind.insurance, title: 'Car insurance', dueAt: DateTime(2027, 1, 10)));
    final inputs = reminderInputs(await reminders.getUpcoming(), end: DateTime(2026, 11, 22));
    expect(inputs.map((input) => input.title), ['Electricity']);
    expect(inputs.single.recurringId, 'rule-1');
    expect(inputs.single.amountMinor, 184000);
  });
}

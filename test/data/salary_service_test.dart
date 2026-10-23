import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/salary_settings.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/salary/salary_service.dart';
import 'package:hisab/domain/salary/salary_schedule.dart';

void main() {
  late AppDatabase db;
  late SalaryService salary;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    salary = SalaryService(db);
  });

  tearDown(() => db.close());

  Future<SalarySettings> setUpSalary({int salaryDay = 31, SalaryShift shift = SalaryShift.previousWorkingDay}) =>
      salary.saveSalaryRule(settings: SalarySettings(amountMinor: 10000000, salaryDay: salaryDay, shift: shift), today: DateTime(2026, 10, 22));

  Future<void> addIncome(String id, DateTime at, int amount, {String source = 'sms'}) => db.into(db.entries).insert(
        EntriesCompanion.insert(id: id, kind: 'income', amountMinor: amount, occurredAt: at, source: Value(source)),
      );

  test('creates a confirm-first monthly income rule under the Salary category', () async {
    final settings = await setUpSalary();
    final rule = (await salary.recurring.getRule(settings.ruleId))!;
    expect(rule.kind, 'income');
    expect(rule.autoPost, isFalse);
    expect(rule.dayOfMonth, 31);
    expect(rule.name, kSalaryRuleName);
    // 31 Oct 2026 is a Saturday: the rule is due on Friday the 30th.
    expect(rule.nextDue, DateTime(2026, 10, 30, 9));
    expect(rule.categoryId, await salary.salaryCategoryId());
  });

  test('not seen yet before the salary arrives', () async {
    final settings = await setUpSalary();
    final status = (await salary.reconcile(settings, now: DateTime(2026, 11, 2, 12)))!;
    expect(status.expected, DateTime(2026, 10, 30));
    expect(status.reminderState, SalaryReminderState.due);
  });

  test('an SMS salary is recognised, linked and consumes the waiting occurrence', () async {
    final settings = await setUpSalary();
    await addIncome('sms-salary', DateTime(2026, 10, 30, 10), 9950000);
    final status = (await salary.reconcile(settings, now: DateTime(2026, 11, 2, 12)))!;
    expect(status.reminderState, SalaryReminderState.seen);
    final rule = (await salary.recurring.getRule(settings.ruleId))!;
    expect(rule.nextDue, DateTime(2026, 11, 30, 9));
    final entry = await (db.select(db.entries)..where((t) => t.id.equals('sms-salary'))).getSingle();
    expect(entry.recurringId, settings.ruleId);

    // Running again does not skip another month.
    await salary.reconcile(settings, now: DateTime(2026, 11, 3, 12));
    expect((await salary.recurring.getRule(settings.ruleId))!.nextDue, DateTime(2026, 11, 30, 9));
  });

  test('ignores a small unrelated income', () async {
    final settings = await setUpSalary();
    await addIncome('refund', DateTime(2026, 10, 30, 10), 50000);
    final status = (await salary.reconcile(settings, now: DateTime(2026, 11, 2, 12)))!;
    expect(status.isSeen, isFalse);
    expect((await salary.recurring.getRule(settings.ruleId))!.nextDue, DateTime(2026, 10, 30, 9));
  });

  test('a shift that crosses into the next month keeps the following cycle after a confirm', () async {
    // 31 Oct 2026 is a Saturday, so the next working day is Monday 2 Nov.
    final settings = await setUpSalary(shift: SalaryShift.nextWorkingDay);
    expect((await salary.recurring.getRule(settings.ruleId))!.nextDue, DateTime(2026, 11, 2, 9));

    await salary.recurring.confirmNext(settings.ruleId);
    await salary.reconcile(settings, now: DateTime(2026, 11, 3, 12));
    expect((await salary.recurring.getRule(settings.ruleId))!.nextDue, DateTime(2026, 11, 30, 9), reason: 'November is not skipped');
  });

  test('a shift that crosses into the previous month does not repeat the cycle after a skip', () async {
    // 1 Nov 2026 is a Sunday, so the previous working day is Friday 30 Oct.
    final settings = await setUpSalary(salaryDay: 1);
    expect((await salary.recurring.getRule(settings.ruleId))!.nextDue, DateTime(2026, 10, 30, 9));

    await salary.recurring.skipNext(settings.ruleId);
    await salary.reconcile(settings, now: DateTime(2026, 10, 31, 12));
    expect((await salary.recurring.getRule(settings.ruleId))!.nextDue, DateTime(2026, 12, 1, 9), reason: 'November was just skipped');
  });

  test('an early salary for the next cycle leaves a missed cycle waiting', () async {
    final settings = await setUpSalary();
    await addIncome('early', DateTime(2026, 11, 28, 10), 10000000);
    final status = (await salary.reconcile(settings, now: DateTime(2026, 11, 28, 12)))!;
    expect(status.isSeen, isTrue);
    expect(status.expected, DateTime(2026, 11, 30));
    expect((await salary.recurring.getRule(settings.ruleId))!.nextDue, DateTime(2026, 10, 30, 9), reason: 'October never arrived');
  });

  test('nothing to evaluate when the salary is not set up', () async {
    expect(await salary.reconcile(const SalarySettings(), now: DateTime(2026, 11, 2)), isNull);
  });

  group('editing the setup', () {
    test('a save with the same day keeps the waiting occurrence and its due date', () async {
      final settings = await setUpSalary();
      // 30 Oct passed with no salary: the occurrence is waiting in Recurring.
      final before = (await salary.recurring.getRule(settings.ruleId))!;
      final edited = await salary.saveSalaryRule(settings: settings.copyWith(amountMinor: 11000000), today: DateTime(2026, 11, 3));
      final after = (await salary.recurring.getRule(settings.ruleId))!;
      expect(after.nextDue, DateTime(2026, 10, 30, 9), reason: 'not moved to next month');
      expect((after.postedCount, after.startDate), (before.postedCount, before.startDate));
      expect(after.amountMinor, 11000000);
      expect(edited.ruleId, settings.ruleId);
      expect(edited.trackedSince, DateTime(2026, 10, 22), reason: 'still tracked from the original setup');
      final status = (await salary.reconcile(edited, now: DateTime(2026, 11, 3, 12)))!;
      expect((status.expected, status.isLate), (DateTime(2026, 10, 30), true));
    });

    test('a changed salary day rebuilds the rule from the save day', () async {
      final settings = await setUpSalary();
      final edited = await salary.saveSalaryRule(settings: settings.copyWith(salaryDay: 5), today: DateTime(2026, 11, 3));
      final rule = (await salary.recurring.getRule(edited.ruleId))!;
      expect(edited.ruleId, settings.ruleId);
      expect(rule.dayOfMonth, 5);
      expect(rule.nextDue, DateTime(2026, 11, 5, 9));
      expect(edited.trackedSince, DateTime(2026, 11, 3));
    });

    test('a changed shift moves only the waiting due date', () async {
      final settings = await setUpSalary();
      final edited = await salary.saveSalaryRule(settings: settings.copyWith(shift: SalaryShift.nextWorkingDay), today: DateTime(2026, 11, 3));
      // 31 Oct 2026 is a Saturday, the next working day is Monday 2 Nov.
      expect((await salary.recurring.getRule(edited.ruleId))!.nextDue, DateTime(2026, 11, 2, 9));
    });
  });

  test('a new rule is tracked from its setup day and never waits for an earlier cycle', () async {
    final settings = await setUpSalary();
    expect(settings.trackedSince, DateTime(2026, 10, 22));
    expect((await salary.reconcile(settings, now: DateTime(2026, 10, 23, 12)))!.expected, DateTime(2026, 10, 30), reason: 'not 30 Sep');

    // Saturday 31 Oct: the shifted date (Friday 30th) is already behind.
    final onSaturday = await salary.saveSalaryRule(settings: const SalarySettings(amountMinor: 10000000, salaryDay: 31), today: DateTime(2026, 10, 31));
    expect((await salary.recurring.getRule(onSaturday.ruleId))!.nextDue, DateTime(2026, 11, 30, 9));
    final status = (await salary.reconcile(onSaturday, now: DateTime(2026, 10, 31, 12)))!;
    expect((status.expected, status.isLate), (DateTime(2026, 11, 30), false));
  });
}

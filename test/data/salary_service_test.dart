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

  Future<SalarySettings> setUpSalary() async {
    const settings = SalarySettings(amountMinor: 10000000, salaryDay: 31, shift: SalaryShift.previousWorkingDay);
    final ruleId = await salary.saveSalaryRule(settings: settings, name: 'Salary', today: DateTime(2026, 10, 22));
    return settings.copyWith(ruleId: ruleId);
  }

  Future<void> addIncome(String id, DateTime at, int amount, {String source = 'sms'}) => db.into(db.entries).insert(
        EntriesCompanion.insert(id: id, kind: 'income', amountMinor: amount, occurredAt: at, source: Value(source)),
      );

  test('creates a confirm-first monthly income rule under the Salary category', () async {
    final settings = await setUpSalary();
    final rule = (await salary.recurring.getRule(settings.ruleId))!;
    expect(rule.kind, 'income');
    expect(rule.autoPost, isFalse);
    expect(rule.dayOfMonth, 31);
    expect(rule.nextDue, DateTime(2026, 10, 31, 9));
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
    expect((await salary.recurring.getRule(settings.ruleId))!.nextDue, DateTime(2026, 10, 31, 9));
  });

  test('nothing to evaluate when the salary is not set up', () async {
    expect(await salary.reconcile(const SalarySettings(), now: DateTime(2026, 11, 2)), isNull);
  });
}

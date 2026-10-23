import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/salary_settings.dart';
import 'package:hisab/domain/salary/salary_schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults when nothing is stored', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SalarySettings.fromPrefs(await SharedPreferences.getInstance());
    expect(settings.isSetUp, isFalse);
    expect(settings.shift, SalaryShift.previousWorkingDay);
    expect(settings.reminderDelayDays, kDefaultSalaryReminderDelayDays);
    expect(settings.matchWindowDays, kSalaryMatchWindowDays);
    expect(settings.tolerancePercent, kDefaultSalaryTolerancePercent);
    expect(settings.updatedAt, isNull);
  });

  test('round trips through shared preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final saved = SalarySettings(
      ruleId: 'rule-1',
      amountMinor: 8500000,
      accountId: 'hdfc',
      salaryDay: 30,
      shift: SalaryShift.nextWorkingDay,
      holidays: [DateTime(2026, 11, 8)],
      reminderEnabled: false,
      reminderDelayDays: 4,
      matchWindowDays: 6,
      tolerancePercent: 25,
      updatedAt: DateTime(2026, 10, 23, 9),
    );
    await saved.writeTo(prefs);
    final loaded = SalarySettings.fromPrefs(prefs);
    expect(loaded.ruleId, 'rule-1');
    expect(loaded.amountMinor, 8500000);
    expect(loaded.accountId, 'hdfc');
    expect(loaded.salaryDay, 30);
    expect(loaded.shift, SalaryShift.nextWorkingDay);
    expect(loaded.holidays, [DateTime(2026, 11, 8)]);
    expect(loaded.reminderEnabled, isFalse);
    expect(loaded.reminderDelayDays, 4);
    expect(loaded.matchWindowDays, 6);
    expect(loaded.tolerancePercent, 25);
    expect(loaded.updatedAt, DateTime(2026, 10, 23, 9));
    expect(loaded.copyWith(clearAccount: true).accountId, isNull);
  });

  test('bad holiday strings are dropped', () {
    expect(SalarySettings.parseHolidays(['2026-10-30', 'nope']), [DateTime(2026, 10, 30)]);
  });

  group('backup form', () {
    final full = SalarySettings(
      ruleId: 'rule-1',
      amountMinor: 8500000,
      accountId: 'hdfc',
      salaryDay: 30,
      shift: SalaryShift.nextWorkingDay,
      holidays: [DateTime(2026, 11, 8)],
      reminderEnabled: false,
      reminderDelayDays: 4,
      matchWindowDays: 2,
      tolerancePercent: 5,
      updatedAt: DateTime(2026, 10, 23, 9, 30),
    );

    test('round trips through JSON', () {
      final back = SalarySettings.fromJson(full.toJson());
      expect(back.toJson(), full.toJson());
    });

    test('a setup saved before detection settings existed gets the defaults', () {
      final json = full.toJson()..remove('matchWindowDays')..remove('tolerancePercent')..remove('updatedAt');
      final back = SalarySettings.fromJson(json);
      expect(back.matchWindowDays, kSalaryMatchWindowDays);
      expect(back.tolerancePercent, kDefaultSalaryTolerancePercent);
      expect(back.updatedAt, isNull);
      expect(back.ruleId, 'rule-1');
    });

    test('out-of-range and mistyped values are brought back within bounds', () {
      final back = SalarySettings.fromJson({'ruleId': 'r', 'salaryDay': 45, 'matchWindowDays': 99, 'tolerancePercent': -3, 'holidays': ['2026-10-30', 7], 'amountMinor': 'x'});
      expect(back.salaryDay, 31);
      expect(back.matchWindowDays, kMaxSalaryMatchWindowDays);
      expect(back.tolerancePercent, 0);
      expect(back.holidays, [DateTime(2026, 10, 30)]);
      expect(back.amountMinor, 0);
    });

    test('evaluate uses the stored window and tolerance', () {
      final setup = const SalarySettings(ruleId: 'r', amountMinor: 100000, salaryDay: 1, shift: SalaryShift.sameDay, tolerancePercent: 0);
      final incomes = [IncomeCandidate(occurredAt: DateTime(2026, 10, 1), amountMinor: 99000)];
      expect(setup.evaluate(now: DateTime(2026, 10, 2), incomes: incomes).isSeen, isFalse);
      expect(setup.copyWith(tolerancePercent: 5).evaluate(now: DateTime(2026, 10, 2), incomes: incomes).isSeen, isTrue);
    });
  });

  group('restore decision', () {
    final older = SalarySettings(ruleId: 'a', updatedAt: DateTime(2026, 10, 1));
    final newer = SalarySettings(ruleId: 'b', updatedAt: DateTime(2026, 10, 20));

    test('a newer backup replaces the local setup, an older one does not', () {
      expect(shouldRestoreSalarySettings(local: older, incoming: newer), isTrue);
      expect(shouldRestoreSalarySettings(local: newer, incoming: older), isFalse);
      expect(shouldRestoreSalarySettings(local: newer, incoming: newer), isFalse);
    });

    test('fills an empty device, never clears a setup', () {
      expect(shouldRestoreSalarySettings(local: const SalarySettings(), incoming: older), isTrue);
      expect(shouldRestoreSalarySettings(local: older, incoming: const SalarySettings()), isFalse);
    });

    test('an undated local setup counts as oldest, an undated backup never wins', () {
      expect(shouldRestoreSalarySettings(local: const SalarySettings(ruleId: 'x'), incoming: older), isTrue);
      expect(shouldRestoreSalarySettings(local: older, incoming: const SalarySettings(ruleId: 'y')), isFalse);
    });
  });

  test('the rule anchor and a declined alignment round trip through preferences and JSON', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SalarySettings(ruleId: 'r', salaryDay: 25, ruleAnchor: SalaryRuleAnchor(nominal: DateTime(2026, 10, 25), postedCount: 1), alignDeclinedRuleId: 'r');
    await settings.writeTo(prefs);
    final read = SalarySettings.fromPrefs(prefs);
    expect(read.ruleAnchor, settings.ruleAnchor);
    expect(read.alignDeclinedRuleId, 'r');
    expect(SalarySettings.fromJson(settings.toJson()).ruleAnchor, settings.ruleAnchor);

    await prefs.setString('salaryRuleAnchor', '{broken');
    expect(SalarySettings.fromPrefs(prefs).ruleAnchor, isNull);
  });

  test('the month-start suggestion is offered until declined for this rule', () {
    const settings = SalarySettings(ruleId: 'r', salaryDay: 25);
    expect(settings.shouldOfferMonthStartAlign(monthStartDay: 1), isTrue);
    expect(settings.shouldOfferMonthStartAlign(monthStartDay: 25), isFalse);
    expect(settings.copyWith(alignDeclinedRuleId: 'r').shouldOfferMonthStartAlign(monthStartDay: 1), isFalse);
    expect(settings.copyWith(alignDeclinedRuleId: 'old').shouldOfferMonthStartAlign(monthStartDay: 1), isTrue, reason: 'a new rule asks again');
  });
}

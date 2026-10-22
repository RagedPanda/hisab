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
    expect(loaded.copyWith(clearAccount: true).accountId, isNull);
  });

  test('bad holiday strings are dropped', () {
    expect(SalarySettings.parseHolidays(['2026-10-30', 'nope']), [DateTime(2026, 10, 30)]);
  });
}

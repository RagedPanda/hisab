import 'package:shared_preferences/shared_preferences.dart';

import '../domain/salary/salary_schedule.dart';

/// The user's salary setup, persisted beside [AppSettings]. The income itself
/// is a recurring rule ([ruleId]); this holds what the rule cannot: the
/// weekend/holiday shift and the "Salary not seen yet" reminder.
class SalarySettings {
  const SalarySettings({
    this.ruleId = '',
    this.amountMinor = 0,
    this.accountId,
    this.salaryDay = 1,
    this.shift = SalaryShift.previousWorkingDay,
    this.holidays = const [],
    this.reminderEnabled = true,
    this.reminderDelayDays = kDefaultSalaryReminderDelayDays,
  });

  /// Recurring income rule created by the salary setup; empty when not set up.
  final String ruleId;
  final int amountMinor;
  final String? accountId;

  /// Day of month the salary is due, 1..31 (clamped to short months).
  final int salaryDay;
  final SalaryShift shift;

  /// Bank holidays the shift skips besides weekends (dates, time ignored).
  final List<DateTime> holidays;
  final bool reminderEnabled;

  /// Days after the expected date before "Salary not seen yet".
  final int reminderDelayDays;

  bool get isSetUp => ruleId.isNotEmpty;
  Set<DateTime> get holidaySet => holidays.toSet();

  SalarySettings copyWith({
    String? ruleId,
    int? amountMinor,
    String? accountId,
    bool clearAccount = false,
    int? salaryDay,
    SalaryShift? shift,
    List<DateTime>? holidays,
    bool? reminderEnabled,
    int? reminderDelayDays,
  }) =>
      SalarySettings(
        ruleId: ruleId ?? this.ruleId,
        amountMinor: amountMinor ?? this.amountMinor,
        accountId: clearAccount ? null : (accountId ?? this.accountId),
        salaryDay: salaryDay ?? this.salaryDay,
        shift: shift ?? this.shift,
        holidays: holidays ?? this.holidays,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderDelayDays: reminderDelayDays ?? this.reminderDelayDays,
      );

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Stored holiday strings ("2026-10-30") back to dates; bad ones dropped.
  static List<DateTime> parseHolidays(List<String> stored) => [
        for (final value in stored)
          if (DateTime.tryParse(value) case final date?) DateTime(date.year, date.month, date.day),
      ];

  static SalarySettings fromPrefs(SharedPreferences prefs) {
    final account = prefs.getString('salaryAccountId') ?? '';
    return SalarySettings(
      ruleId: prefs.getString('salaryRuleId') ?? '',
      amountMinor: prefs.getInt('salaryAmountMinor') ?? 0,
      accountId: account.isEmpty ? null : account,
      salaryDay: prefs.getInt('salaryDay') ?? 1,
      shift: SalaryShift.parse(prefs.getString('salaryShift') ?? ''),
      holidays: parseHolidays(prefs.getStringList('salaryHolidays') ?? const []),
      reminderEnabled: prefs.getBool('salaryReminderEnabled') ?? true,
      reminderDelayDays: prefs.getInt('salaryReminderDelayDays') ?? kDefaultSalaryReminderDelayDays,
    );
  }

  Future<void> writeTo(SharedPreferences prefs) async {
    await prefs.setString('salaryRuleId', ruleId);
    await prefs.setInt('salaryAmountMinor', amountMinor);
    await prefs.setString('salaryAccountId', accountId ?? '');
    await prefs.setInt('salaryDay', salaryDay);
    await prefs.setString('salaryShift', shift.name);
    await prefs.setStringList('salaryHolidays', [for (final date in holidays) _dateKey(date)]);
    await prefs.setBool('salaryReminderEnabled', reminderEnabled);
    await prefs.setInt('salaryReminderDelayDays', reminderDelayDays);
  }
}

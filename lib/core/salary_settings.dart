import 'package:shared_preferences/shared_preferences.dart';

import '../domain/salary/salary_schedule.dart';

/// The user's salary setup, persisted beside [AppSettings] and carried in
/// backups (see [toJson]). The income itself is a recurring rule ([ruleId]);
/// this holds what the rule cannot: the weekend/holiday shift, how detection
/// matches an income and the "Salary not seen yet" reminder.
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
    this.matchWindowDays = kSalaryMatchWindowDays,
    this.tolerancePercent = kDefaultSalaryTolerancePercent,
    this.updatedAt,
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

  /// Days either side of the expected date an income still counts as salary.
  final int matchWindowDays;

  /// How far, in percent, an income may differ from [amountMinor] and still count.
  final int tolerancePercent;

  /// Last time the user saved the setup; a backup restores only a newer one.
  final DateTime? updatedAt;

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
    int? matchWindowDays,
    int? tolerancePercent,
    DateTime? updatedAt,
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
        matchWindowDays: matchWindowDays ?? this.matchWindowDays,
        tolerancePercent: tolerancePercent ?? this.tolerancePercent,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// This setup's pay cycle against recent [incomes].
  SalaryStatus evaluate({required DateTime now, required Iterable<IncomeCandidate> incomes}) => evaluateSalary(
        now: now,
        salaryDay: salaryDay,
        expectedMinor: amountMinor,
        incomes: incomes,
        shift: shift,
        holidays: holidaySet,
        accountId: accountId,
        reminderDelayDays: reminderDelayDays,
        windowDays: clampSalaryMatchWindowDays(matchWindowDays),
        tolerance: salaryToleranceFraction(tolerancePercent),
      );

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Stored holiday strings ("2026-10-30") back to dates; bad ones dropped.
  static List<DateTime> parseHolidays(List<String> stored) => [
        for (final value in stored)
          if (DateTime.tryParse(value) case final date?) DateTime(date.year, date.month, date.day),
      ];

  /// The backup form. Holidays are plain dates, [updatedAt] is ISO 8601.
  Map<String, dynamic> toJson() => {
        'ruleId': ruleId,
        'amountMinor': amountMinor,
        'accountId': accountId,
        'salaryDay': salaryDay,
        'shift': shift.name,
        'holidays': [for (final date in holidays) _dateKey(date)],
        'reminderEnabled': reminderEnabled,
        'reminderDelayDays': reminderDelayDays,
        'matchWindowDays': matchWindowDays,
        'tolerancePercent': tolerancePercent,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  /// Reads [toJson] output. Missing or mistyped values fall back to the
  /// defaults and out-of-range ones are brought back within bounds, so a
  /// hand-edited or future backup can never break detection.
  static SalarySettings fromJson(Map<String, dynamic> json) {
    T? read<T>(String key) => json[key] is T ? json[key] as T : null;
    final account = read<String>('accountId') ?? '';
    return SalarySettings(
      ruleId: read<String>('ruleId') ?? '',
      amountMinor: read<int>('amountMinor') ?? 0,
      accountId: account.isEmpty ? null : account,
      salaryDay: (read<int>('salaryDay') ?? 1).clamp(1, 31),
      shift: SalaryShift.parse(read<String>('shift') ?? ''),
      holidays: parseHolidays([for (final value in read<List>('holidays') ?? const []) if (value is String) value]),
      reminderEnabled: read<bool>('reminderEnabled') ?? true,
      reminderDelayDays: read<int>('reminderDelayDays') ?? kDefaultSalaryReminderDelayDays,
      matchWindowDays: clampSalaryMatchWindowDays(read<int>('matchWindowDays') ?? kSalaryMatchWindowDays),
      tolerancePercent: clampSalaryTolerancePercent(read<int>('tolerancePercent') ?? kDefaultSalaryTolerancePercent),
      updatedAt: DateTime.tryParse(read<String>('updatedAt') ?? ''),
    );
  }

  static SalarySettings fromPrefs(SharedPreferences prefs) => fromJson({
        'ruleId': prefs.getString('salaryRuleId'),
        'amountMinor': prefs.getInt('salaryAmountMinor'),
        'accountId': prefs.getString('salaryAccountId'),
        'salaryDay': prefs.getInt('salaryDay'),
        'shift': prefs.getString('salaryShift'),
        'holidays': prefs.getStringList('salaryHolidays'),
        'reminderEnabled': prefs.getBool('salaryReminderEnabled'),
        'reminderDelayDays': prefs.getInt('salaryReminderDelayDays'),
        'matchWindowDays': prefs.getInt('salaryMatchWindowDays'),
        'tolerancePercent': prefs.getInt('salaryTolerancePercent'),
        'updatedAt': prefs.getString('salaryUpdatedAt'),
      });

  Future<void> writeTo(SharedPreferences prefs) async {
    await prefs.setString('salaryRuleId', ruleId);
    await prefs.setInt('salaryAmountMinor', amountMinor);
    await prefs.setString('salaryAccountId', accountId ?? '');
    await prefs.setInt('salaryDay', salaryDay);
    await prefs.setString('salaryShift', shift.name);
    await prefs.setStringList('salaryHolidays', [for (final date in holidays) _dateKey(date)]);
    await prefs.setBool('salaryReminderEnabled', reminderEnabled);
    await prefs.setInt('salaryReminderDelayDays', reminderDelayDays);
    await prefs.setInt('salaryMatchWindowDays', matchWindowDays);
    await prefs.setInt('salaryTolerancePercent', tolerancePercent);
    if (updatedAt case final savedAt?) await prefs.setString('salaryUpdatedAt', savedAt.toIso8601String());
  }
}

/// Whether a backup's salary setup ([incoming]) should replace the [local]
/// one: only a set-up backup, and only when it is newer (a local setup saved
/// before timestamps existed counts as oldest). Same newer-wins rule as rows.
bool shouldRestoreSalarySettings({required SalarySettings local, required SalarySettings incoming}) {
  if (!incoming.isSetUp) return false;
  if (!local.isSetUp) return true;
  final localAt = local.updatedAt;
  final incomingAt = incoming.updatedAt;
  if (incomingAt == null) return false;
  return localAt == null || incomingAt.isAfter(localAt);
}

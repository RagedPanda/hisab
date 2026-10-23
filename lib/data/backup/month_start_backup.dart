import 'package:shared_preferences/shared_preferences.dart';

import '../../core/settings.dart';
import '../../domain/salary/salary_schedule.dart';
import 'backup_section.dart';

/// The "Month starts on" day read from a backup block, or null when it is
/// missing or outside 1..[kMaxMonthStartDay].
int? parseBackedUpMonthStartDay(Map<String, dynamic> json) {
  final day = json['monthStartDay'];
  return day is int && day >= 1 && day <= kMaxMonthStartDay ? day : null;
}

/// Whether a backup's [incoming] "Month starts on" should replace [local].
/// The setting carries no timestamp, so only a device still on the default
/// (the 1st) takes the backup's day; a day the user chose here is kept.
bool shouldRestoreMonthStartDay({required int local, required int? incoming}) => incoming != null && local == 1 && incoming != local;

/// Carries "Month starts on" in backups: budgets, the dashboard month and
/// the salary alignment all depend on it.
class MonthStartBackupSection implements BackupSection {
  const MonthStartBackupSection(this._prefs);

  final SharedPreferences _prefs;

  @override
  String get key => 'generalSettings';

  @override
  Map<String, dynamic>? export() => {'monthStartDay': _prefs.getInt(kMonthStartDayPref) ?? 1};

  @override
  Future<int> restore(Map<String, dynamic> json) async {
    final incoming = parseBackedUpMonthStartDay(json);
    if (!shouldRestoreMonthStartDay(local: _prefs.getInt(kMonthStartDayPref) ?? 1, incoming: incoming)) return 0;
    await _prefs.setInt(kMonthStartDayPref, incoming!);
    return 1;
  }
}

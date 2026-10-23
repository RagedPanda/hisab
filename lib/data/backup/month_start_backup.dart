import 'package:shared_preferences/shared_preferences.dart';

import '../../core/settings.dart';
import '../../domain/salary/salary_schedule.dart';
import '../db/database.dart';
import 'backup_section.dart';

/// The "Month starts on" day read from a backup block, or null when it is
/// missing or outside 1..[kMaxMonthStartDay].
int? parseBackedUpMonthStartDay(Map<String, dynamic> json) {
  final day = json['monthStartDay'];
  return day is int && day >= 1 && day <= kMaxMonthStartDay ? day : null;
}

/// Whether a backup's [incoming] "Month starts on" should replace [local].
/// A restore is the user asking for their saved state back, so the backup's
/// day always wins when it has one; a backup without it changes nothing.
bool shouldRestoreMonthStartDay({required int local, required int? incoming}) => incoming != null && incoming != local;

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
  Future<int> restore(Map<String, dynamic> json, {required AppDatabase db, required Map<String, dynamic> payload}) async {
    final incoming = parseBackedUpMonthStartDay(json);
    if (!shouldRestoreMonthStartDay(local: _prefs.getInt(kMonthStartDayPref) ?? 1, incoming: incoming)) return 0;
    await _prefs.setInt(kMonthStartDayPref, incoming!);
    return 1;
  }
}

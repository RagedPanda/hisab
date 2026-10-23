import 'package:shared_preferences/shared_preferences.dart';

import '../../core/salary_settings.dart';
import '../backup/backup_section.dart';

/// Carries the salary setup (shift, holidays, detection and reminder
/// settings) in backups; its recurring rule travels with the other rows.
class SalaryBackupSection implements BackupSection {
  const SalaryBackupSection(this._prefs);

  final SharedPreferences _prefs;

  @override
  String get key => 'salarySettings';

  @override
  Map<String, dynamic>? export() {
    final settings = SalarySettings.fromPrefs(_prefs);
    return settings.isSetUp ? settings.toJson() : null;
  }

  @override
  Future<int> restore(Map<String, dynamic> json) async {
    final incoming = SalarySettings.fromJson(json);
    if (!shouldRestoreSalarySettings(local: SalarySettings.fromPrefs(_prefs), incoming: incoming)) return 0;
    await incoming.writeTo(_prefs);
    return 1;
  }
}

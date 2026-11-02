import 'package:shared_preferences/shared_preferences.dart';

import '../backup/backup_section.dart';
import '../db/database.dart';

/// Preference holding the user's own UPI ID for udhaar reminders.
const String kMyUpiIdPref = 'myUpiId';

/// The UPI ID read from a backup block: the stored text (empty when the user
/// chose to leave it out), or null when the block lacks it.
String? parseBackedUpUpiId(Map<String, dynamic> json) {
  final upiId = json[kMyUpiIdPref];
  return upiId is String ? upiId.trim() : null;
}

/// Carries the udhaar settings kept in shared preferences (the user's own
/// UPI ID for reminders) in backups; the entries and People travel as rows.
class UdhaarBackupSection implements BackupSection {
  const UdhaarBackupSection(this._prefs);

  final SharedPreferences _prefs;

  @override
  String get key => 'udhaarSettings';

  @override
  Map<String, dynamic>? export() {
    final upiId = _prefs.getString(kMyUpiIdPref);
    return upiId == null ? null : {kMyUpiIdPref: upiId};
  }

  @override
  Future<int> restore(Map<String, dynamic> json, {required AppDatabase db, required Map<String, dynamic> payload}) async {
    final incoming = parseBackedUpUpiId(json);
    if (incoming == null || incoming == _prefs.getString(kMyUpiIdPref)) return 0;
    await _prefs.setString(kMyUpiIdPref, incoming);
    return 1;
  }
}

import 'package:shared_preferences/shared_preferences.dart';

/// Receive time of the newest inbox SMS already run through the ingest
/// pipeline, kept with the other settings in SharedPreferences.
class SmsSyncCursor {
  SmsSyncCursor(this.prefs);
  final SharedPreferences prefs;

  static const key = 'smsSyncedUntil';

  DateTime? read() {
    final millis = prefs.getInt(key);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> write(DateTime value) => prefs.setInt(key, value.millisecondsSinceEpoch);
}

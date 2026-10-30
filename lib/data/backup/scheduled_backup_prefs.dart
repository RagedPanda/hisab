import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/backup/scheduled_backup.dart';

/// Prefs key of the user's [ScheduledBackupChoices]. Only Settings writes it.
const kScheduledBackupChoicesPref = 'scheduledBackup';

/// Prefs key of the [ScheduledBackupHistory]. Only a backup run writes it,
/// so a background run never overwrites a choice made meanwhile.
const kScheduledBackupHistoryPref = 'scheduledBackupHistory';

Object? _decode(String? raw) {
  if (raw == null) return null;
  try {
    return jsonDecode(raw);
  } on FormatException {
    return null;
  }
}

ScheduledBackupChoices readScheduledBackupChoices(SharedPreferences prefs) => ScheduledBackupChoices.fromJson(_decode(prefs.getString(kScheduledBackupChoicesPref)));

Future<void> writeScheduledBackupChoices(SharedPreferences prefs, ScheduledBackupChoices choices) =>
    prefs.setString(kScheduledBackupChoicesPref, jsonEncode(choices.toJson()));

ScheduledBackupHistory readScheduledBackupHistory(SharedPreferences prefs) => ScheduledBackupHistory.fromJson(_decode(prefs.getString(kScheduledBackupHistoryPref)));

Future<void> writeScheduledBackupHistory(SharedPreferences prefs, ScheduledBackupHistory history) =>
    prefs.setString(kScheduledBackupHistoryPref, jsonEncode(history.toJson()));

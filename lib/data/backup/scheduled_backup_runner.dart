import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/settings.dart';
import '../../domain/backup/backup_file_name.dart';
import '../../domain/backup/scheduled_backup.dart';
import 'backup_service.dart';
import 'drive_account.dart';
import 'drive_backup_service.dart';
import 'drive_backup_store.dart';
import 'scheduled_backup_channel.dart';
import 'scheduled_backup_prefs.dart';

/// Writes the scheduled backup: the same encrypted file "Back up" makes
/// ([BackupService.exportEncrypted]), to the chosen folder (keeping the
/// newest few) and, when included, as the Google Drive copy. Runs in the app
/// on start and resume, and on Android also from the background job.
class ScheduledBackupRunner {
  const ScheduledBackupRunner({
    required this.backups,
    required this.folder,
    required this.vault,
    required this.prefs,
    this.driveConnected = false,
    this.driveStore,
  });

  final BackupService backups;
  final BackupFolderAccess folder;
  final BackupPassphraseVault vault;
  final SharedPreferences prefs;
  final bool driveConnected;

  /// Built only when Drive is written; null where Drive cannot be reached
  /// (the background job, which has no way to show a Google screen).
  final DriveBackupStore Function()? driveStore;

  bool get _driveReachable => driveConnected && driveStore != null;

  /// Runs the destinations that are due at [now]; returns what was attempted.
  Future<Map<ScheduledBackupTarget, BackupAttempt>> runDue(DateTime now) {
    final targets = dueBackupTargets(readScheduledBackupChoices(prefs), readScheduledBackupHistory(prefs), driveConnected: _driveReachable, now: now);
    return _run(targets, now);
  }

  /// "Back up now": every chosen destination, whatever the schedule.
  Future<Map<ScheduledBackupTarget, BackupAttempt>> runNow(DateTime now) =>
      _run(chosenBackupTargets(readScheduledBackupChoices(prefs), driveConnected: _driveReachable), now);

  Future<Map<ScheduledBackupTarget, BackupAttempt>> _run(Set<ScheduledBackupTarget> targets, DateTime now) async {
    if (targets.isEmpty) return const {};
    final choices = readScheduledBackupChoices(prefs);
    final passphrase = await vault.readPassphrase();
    Uint8List? bytes;
    if (passphrase != null && passphrase.isNotEmpty) {
      final settings = AppSettings.fromPrefs(prefs);
      bytes = await backups.exportEncrypted(passphrase, currencyCode: settings.currencyCode, numberFormat: settings.numberFormat);
    }
    final attempts = <ScheduledBackupTarget, BackupAttempt>{};
    for (final target in targets) {
      attempts[target] = bytes == null
          ? BackupAttempt(at: now, failure: ScheduledBackupFailure.noPassphrase)
          : await _attempt(() => _write(target, choices, bytes!, now), now);
    }
    // Re-read: another run (the background job) may have recorded meanwhile.
    var history = readScheduledBackupHistory(prefs);
    for (final entry in attempts.entries) {
      history = history.record(entry.key, entry.value);
    }
    await writeScheduledBackupHistory(prefs, history);
    return attempts;
  }

  Future<BackupAttempt> _attempt(Future<String?> Function() write, DateTime now) async {
    try {
      return BackupAttempt(at: now, detail: await write());
    } catch (error) {
      final failure = scheduledBackupFailureOf(error);
      return BackupAttempt(at: now, failure: failure, detail: failure == ScheduledBackupFailure.unknown ? '$error' : null);
    }
  }

  /// Writes one destination; returns the file name for the folder.
  Future<String?> _write(ScheduledBackupTarget target, ScheduledBackupChoices choices, Uint8List bytes, DateTime now) async {
    switch (target) {
      case ScheduledBackupTarget.folder:
        final folderUri = choices.folderUri;
        if (folderUri == null || folderUri.isEmpty) throw const _NoFolderChosen();
        final name = backupFileName(now);
        await folder.write(folderUri, name, bytes);
        for (final old in backupsToPrune(await folder.list(folderUri), keep: choices.keep)) {
          await folder.delete(folderUri, old);
        }
        return name;
      case ScheduledBackupTarget.drive:
        await driveStore!().upload(bytes);
        return null;
    }
  }
}

class _NoFolderChosen implements Exception {
  const _NoFolderChosen();
}

/// Sorts an error from a scheduled run into a [ScheduledBackupFailure].
ScheduledBackupFailure scheduledBackupFailureOf(Object error) => switch (error) {
      _NoFolderChosen() => ScheduledBackupFailure.noFolder,
      BackupFolderUnavailableException() => ScheduledBackupFailure.folderUnavailable,
      DriveSignInNeededException() => ScheduledBackupFailure.signInNeeded,
      _ => switch (driveBackupFailureOf(error)) {
          DriveBackupFailure.cancelled => ScheduledBackupFailure.signInNeeded,
          DriveBackupFailure.offline => ScheduledBackupFailure.offline,
          _ => ScheduledBackupFailure.unknown,
        },
    };

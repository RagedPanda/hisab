/// What the user chose for scheduled backups, what happened on each run,
/// and which destinations are due. Pure values; the prefs mapping lives in
/// lib/data/backup/scheduled_backup_prefs.dart.
library;

import 'backup_schedule.dart';

/// Where a scheduled backup goes.
enum ScheduledBackupTarget { folder, drive }

/// Why a scheduled backup did not happen, for the message to show.
enum ScheduledBackupFailure {
  /// No passphrase saved on this device; a scheduled run cannot ask for one.
  noPassphrase,

  /// The schedule is on but no folder was chosen.
  noFolder,

  /// The folder was moved, deleted, or Hisab lost access to it.
  folderUnavailable,

  /// Google needs the user to sign in again before Drive can be written.
  signInNeeded,
  offline,
  unknown;

  static ScheduledBackupFailure fromStorageKey(String? key) => values.firstWhere((value) => value.name == key, orElse: () => unknown);
}

/// One run for one destination: when, and why it failed (null when it worked).
class BackupAttempt {
  const BackupAttempt({required this.at, this.failure, this.detail});
  final DateTime at;
  final ScheduledBackupFailure? failure;

  /// The file written, or the error text for an [ScheduledBackupFailure.unknown] failure.
  final String? detail;

  bool get succeeded => failure == null;

  Map<String, dynamic> toJson() => {'at': at.toIso8601String(), 'failure': ?failure?.name, 'detail': ?detail};

  static BackupAttempt? fromJson(Object? json) {
    if (json is! Map) return null;
    final at = DateTime.tryParse('${json['at']}');
    if (at == null) return null;
    final failure = json['failure'];
    return BackupAttempt(
      at: at,
      failure: failure is String ? ScheduledBackupFailure.fromStorageKey(failure) : null,
      detail: json['detail'] is String ? json['detail'] as String : null,
    );
  }
}

/// The user's scheduled backup settings.
class ScheduledBackupChoices {
  const ScheduledBackupChoices({
    this.frequency = BackupFrequency.off,
    this.folderUri,
    this.folderName,
    this.keep = kDefaultBackupsKept,
    this.includeDrive = false,
  });

  final BackupFrequency frequency;

  /// Platform handle for the chosen folder (an Android tree URI, an iOS
  /// bookmark); null when none is chosen.
  final String? folderUri;

  /// The folder's name to show the user.
  final String? folderName;

  /// How many backups to keep in the folder.
  final int keep;

  /// Also replace the Google Drive copy on the same schedule.
  final bool includeDrive;

  bool get isOn => frequency != BackupFrequency.off;
  bool get hasFolder => folderUri != null && folderUri!.isNotEmpty;

  ScheduledBackupChoices copyWith({BackupFrequency? frequency, String? folderUri, String? folderName, int? keep, bool? includeDrive}) => ScheduledBackupChoices(
        frequency: frequency ?? this.frequency,
        folderUri: folderUri ?? this.folderUri,
        folderName: folderName ?? this.folderName,
        keep: keep ?? this.keep,
        includeDrive: includeDrive ?? this.includeDrive,
      );

  Map<String, dynamic> toJson() => {
        'frequency': frequency.storageKey,
        'folderUri': ?folderUri,
        'folderName': ?folderName,
        'keep': keep,
        'includeDrive': includeDrive,
      };

  static ScheduledBackupChoices fromJson(Object? json) {
    if (json is! Map) return const ScheduledBackupChoices();
    final keep = json['keep'];
    return ScheduledBackupChoices(
      frequency: BackupFrequency.fromStorageKey(json['frequency'] as String?),
      folderUri: json['folderUri'] is String ? json['folderUri'] as String : null,
      folderName: json['folderName'] is String ? json['folderName'] as String : null,
      keep: keep is int && keep > 0 ? keep : kDefaultBackupsKept,
      includeDrive: json['includeDrive'] == true,
    );
  }
}

/// The last attempt and last success per destination.
class ScheduledBackupHistory {
  const ScheduledBackupHistory({this.lastAttempt = const {}, this.lastSuccess = const {}});
  final Map<ScheduledBackupTarget, BackupAttempt> lastAttempt;
  final Map<ScheduledBackupTarget, BackupAttempt> lastSuccess;

  /// [attempt] recorded for [target].
  ScheduledBackupHistory record(ScheduledBackupTarget target, BackupAttempt attempt) => ScheduledBackupHistory(
        lastAttempt: {...lastAttempt, target: attempt},
        lastSuccess: attempt.succeeded ? {...lastSuccess, target: attempt} : lastSuccess,
      );

  Map<String, dynamic> toJson() => {
        'lastAttempt': {for (final entry in lastAttempt.entries) entry.key.name: entry.value.toJson()},
        'lastSuccess': {for (final entry in lastSuccess.entries) entry.key.name: entry.value.toJson()},
      };

  static ScheduledBackupHistory fromJson(Object? json) {
    if (json is! Map) return const ScheduledBackupHistory();
    Map<ScheduledBackupTarget, BackupAttempt> attempts(Object? block) => {
          if (block is Map)
            for (final target in ScheduledBackupTarget.values) target: ?BackupAttempt.fromJson(block[target.name]),
        };
    return ScheduledBackupHistory(lastAttempt: attempts(json['lastAttempt']), lastSuccess: attempts(json['lastSuccess']));
  }
}

/// Destinations a scheduled run should write at [now]. The folder counts
/// once the schedule is on even before one is chosen, so the missing folder
/// is reported; Drive only when it is connected and the user included it.
Set<ScheduledBackupTarget> dueBackupTargets(
  ScheduledBackupChoices choices,
  ScheduledBackupHistory history, {
  required bool driveConnected,
  required DateTime now,
}) {
  bool due(ScheduledBackupTarget target) => isBackupDue(
        frequency: choices.frequency,
        lastSuccess: history.lastSuccess[target]?.at,
        lastAttempt: history.lastAttempt[target]?.at,
        now: now,
      );
  return {
    if (due(ScheduledBackupTarget.folder) && (choices.hasFolder || !(choices.includeDrive && driveConnected))) ScheduledBackupTarget.folder,
    if (choices.includeDrive && driveConnected && due(ScheduledBackupTarget.drive)) ScheduledBackupTarget.drive,
  };
}

/// Destinations a "Back up now" writes, ignoring the schedule.
Set<ScheduledBackupTarget> chosenBackupTargets(ScheduledBackupChoices choices, {required bool driveConnected}) => {
      if (choices.hasFolder || !(choices.includeDrive && driveConnected)) ScheduledBackupTarget.folder,
      if (choices.includeDrive && driveConnected) ScheduledBackupTarget.drive,
    };

/// Why a Google Drive backup action failed, sorted so the user sees a short
/// message rather than an exception's text. Pure; the exception types are
/// matched in lib/data/backup/drive_backup_service.dart.
library;

import 'dart:convert';

import 'scheduled_backup.dart';

/// Why a Drive action failed, for picking the message to show.
enum DriveBackupFailure {
  /// The user closed the Google sign-in or permission screen.
  cancelled,

  /// No network, or Drive is down for now.
  offline,

  /// Google signed the user out or Hisab's access was removed.
  signedOut,

  /// The user's Drive storage is full.
  driveFull,
  notFound,
  wrongPassphrase,
  unknown,
}

/// `error.errors[].reason` values that mean the Drive storage is full.
const _driveFullReasons = {'storageQuotaExceeded', 'quotaExceeded'};

/// `error.errors[].reason` values that mean a busy Drive: try again later.
const _rateLimitReasons = {'rateLimitExceeded', 'userRateLimitExceeded', 'dailyLimitExceeded'};

/// The `reason` of each entry in a Drive API error [body]; empty when the
/// body is not Drive's error JSON.
Set<String> driveErrorReasons(String body) {
  try {
    final decoded = jsonDecode(body);
    final errors = decoded is Map && decoded['error'] is Map ? (decoded['error'] as Map)['errors'] : null;
    return {
      if (errors is List)
        for (final entry in errors)
          if (entry is Map && entry['reason'] is String) entry['reason'] as String,
    };
  } on FormatException {
    return const {};
  }
}

/// The failure behind a Drive API response with [statusCode] and [body].
/// A 401 comes after the token was already refreshed once, so access is gone.
DriveBackupFailure driveStatusFailure(int statusCode, String body) {
  final reasons = driveErrorReasons(body);
  if (reasons.any(_driveFullReasons.contains)) return DriveBackupFailure.driveFull;
  if (reasons.any(_rateLimitReasons.contains)) return DriveBackupFailure.offline;
  return switch (statusCode) {
    401 || 403 => DriveBackupFailure.signedOut,
    404 => DriveBackupFailure.notFound,
    429 || >= 500 => DriveBackupFailure.offline,
    _ => DriveBackupFailure.unknown,
  };
}

/// The scheduled-backup failure to record for a Drive [failure].
ScheduledBackupFailure scheduledFailureOfDrive(DriveBackupFailure failure) => switch (failure) {
      DriveBackupFailure.cancelled || DriveBackupFailure.signedOut => ScheduledBackupFailure.signInNeeded,
      DriveBackupFailure.offline => ScheduledBackupFailure.offline,
      DriveBackupFailure.driveFull => ScheduledBackupFailure.driveFull,
      DriveBackupFailure.notFound || DriveBackupFailure.wrongPassphrase || DriveBackupFailure.unknown => ScheduledBackupFailure.unknown,
    };

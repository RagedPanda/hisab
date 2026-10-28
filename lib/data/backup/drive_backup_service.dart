import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/backup/backup_codec.dart';
import '../../domain/money/money_format.dart';
import 'backup_service.dart';
import 'drive_account.dart';
import 'drive_backup_store.dart';
import 'drive_rest_backup_store.dart';

/// Manual backup to and restore from the user's Drive. The encryption and
/// the merge are [BackupService]'s; this only moves its ciphertext.
class DriveBackupService {
  const DriveBackupService({required this.backups, required this.store});
  final BackupService backups;
  final DriveBackupStore store;

  Future<DriveBackupInfo?> lastBackupInfo() => store.lastBackupInfo();

  /// Encrypts everything with [passphrase] and replaces the Drive copy.
  Future<DriveBackupInfo> backUp(String passphrase, {String? currencyCode, NumberFormatChoice? numberFormat}) async =>
      store.upload(await backups.exportEncrypted(passphrase, currencyCode: currencyCode, numberFormat: numberFormat));

  /// Downloads the Drive copy and merges it in (newer local edits win).
  /// Throws [DriveBackupNotFoundException] when Drive has none.
  Future<BackupRestoreResult> restore(String passphrase) async {
    final bytes = await store.download();
    if (bytes == null) throw const DriveBackupNotFoundException();
    return backups.importEncrypted(bytes, passphrase);
  }

  /// Deletes the Drive copy; false when there was none.
  Future<bool> deleteDriveCopy() => store.delete();
}

/// Why a Drive action failed, for picking the message to show.
enum DriveBackupFailure { cancelled, offline, notFound, wrongPassphrase, unknown }

/// Sorts an error thrown by a Drive action into a [DriveBackupFailure].
DriveBackupFailure driveBackupFailureOf(Object error) => switch (error) {
      DriveSignInCancelledException() => DriveBackupFailure.cancelled,
      DriveBackupNotFoundException() => DriveBackupFailure.notFound,
      BackupFormatException() => DriveBackupFailure.wrongPassphrase,
      SocketException() || http.ClientException() || TimeoutException() => DriveBackupFailure.offline,
      DriveRequestException(statusCode: >= 500) => DriveBackupFailure.offline,
      _ => DriveBackupFailure.unknown,
    };

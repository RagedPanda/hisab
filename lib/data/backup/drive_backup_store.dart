import 'dart:typed_data';

/// When the Drive copy was last written and how big it is.
class DriveBackupInfo {
  const DriveBackupInfo({required this.modifiedAt, required this.sizeBytes});
  final DateTime modifiedAt;
  final int sizeBytes;
}

/// Thrown when a restore finds no Hisab backup in the user's Drive.
class DriveBackupNotFoundException implements Exception {
  const DriveBackupNotFoundException();
  @override
  String toString() => 'No Hisab backup in Google Drive';
}

/// The one encrypted backup file Hisab keeps in the user's Drive
/// `appDataFolder`. Only ciphertext passes through here; tests use a fake.
abstract interface class DriveBackupStore {
  /// The stored backup's details, or null when there is none.
  Future<DriveBackupInfo?> lastBackupInfo();

  /// Writes [bytes] as the backup, replacing any earlier copy.
  Future<DriveBackupInfo> upload(Uint8List bytes);

  /// The stored backup, or null when there is none.
  Future<Uint8List?> download();

  /// Deletes the stored backup; false when there was none.
  Future<bool> delete();
}

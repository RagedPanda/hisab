
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A folder the user picked: the platform handle to keep, and its name.
typedef PickedBackupFolder = ({String uri, String name});

/// Thrown when the chosen folder can no longer be written: moved, deleted,
/// on a removed SD card, or Hisab's access was revoked.
class BackupFolderUnavailableException implements Exception {
  const BackupFolderUnavailableException(this.message);
  final String message;
  @override
  String toString() => 'Backup folder unavailable: $message';
}

/// A folder outside the app (Android Storage Access Framework, iOS Files)
/// that scheduled backups are written to. Tests use a fake.
abstract interface class BackupFolderAccess {
  /// Shows the system folder picker and keeps access to the folder; null when dismissed.
  Future<PickedBackupFolder?> pick();

  /// Writes [bytes] as [name] in the folder, replacing a file of that name.
  Future<void> write(String folderUri, String name, Uint8List bytes);

  /// Names of the files directly in the folder.
  Future<List<String>> list(String folderUri);

  /// Deletes [name] from the folder.
  Future<void> delete(String folderUri, String name);
}

/// The scheduled-backup passphrase, kept in the platform's secure storage
/// (Android Keystore, iOS Keychain) so a run can encrypt without asking.
abstract interface class BackupPassphraseVault {
  Future<String?> readPassphrase();
  Future<void> savePassphrase(String passphrase);
  Future<void> forgetPassphrase();
}

/// The Android job that wakes Hisab to run a due backup while it is closed.
abstract interface class BackgroundBackupScheduler {
  /// Whether this platform can run backups while Hisab is closed.
  bool get isSupported;

  /// Starts ([enabled]) or stops the periodic background check.
  Future<void> setEnabled(bool enabled);

  /// Tells the platform a background run has finished.
  Future<void> finishBackgroundRun();
}

/// All three over one method channel; see ScheduledBackupChannel.kt and
/// ios/Runner/AppDelegate.swift. Folder failures come back as
/// [BackupFolderUnavailableException].
class ScheduledBackupChannel implements BackupFolderAccess, BackupPassphraseVault, BackgroundBackupScheduler {
  const ScheduledBackupChannel();

  static const _channel = MethodChannel('com.ragedpanda.hisab/scheduled_backup');

  static bool get isPlatformSupported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<T?> _folderCall<T>(String method, Map<String, Object?> arguments) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      if (error.code == 'folder') throw BackupFolderUnavailableException(error.message ?? '');
      rethrow;
    }
  }

  @override
  Future<PickedBackupFolder?> pick() async {
    final picked = await _channel.invokeMapMethod<String, Object?>('pickFolder');
    if (picked == null) return null;
    return (uri: picked['uri']! as String, name: (picked['name'] as String?) ?? '');
  }

  @override
  Future<void> write(String folderUri, String name, Uint8List bytes) => _folderCall<void>('writeFile', {'folder': folderUri, 'name': name, 'bytes': bytes});

  @override
  Future<List<String>> list(String folderUri) async => [...?await _folderCall<List<Object?>>('listFiles', {'folder': folderUri})].whereType<String>().toList();

  @override
  Future<void> delete(String folderUri, String name) => _folderCall<void>('deleteFile', {'folder': folderUri, 'name': name});

  @override
  Future<String?> readPassphrase() => _channel.invokeMethod<String>('readPassphrase');

  @override
  Future<void> savePassphrase(String passphrase) => _channel.invokeMethod<void>('writePassphrase', {'passphrase': passphrase});

  @override
  Future<void> forgetPassphrase() => _channel.invokeMethod<void>('deletePassphrase');

  @override
  bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> setEnabled(bool enabled) async {
    if (isSupported) await _channel.invokeMethod<void>('setBackgroundSchedule', {'enabled': enabled});
  }

  @override
  Future<void> finishBackgroundRun() => _channel.invokeMethod<void>('backgroundRunFinished');
}

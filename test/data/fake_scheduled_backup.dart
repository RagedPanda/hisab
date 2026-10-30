import 'dart:typed_data';

import 'package:hisab/data/backup/scheduled_backup_channel.dart';

/// In-memory backup folder. [files] holds what is in it; set [failWith] to
/// make writes and listings throw it, as a folder that went away would.
class FakeBackupFolder implements BackupFolderAccess {
  FakeBackupFolder({Map<String, Uint8List>? files, this.picked}) : files = files ?? {};
  final Map<String, Uint8List> files;

  /// What the picker returns; null acts as a dismissed picker.
  PickedBackupFolder? picked;
  Object? failWith;
  int picks = 0;

  @override
  Future<PickedBackupFolder?> pick() async {
    picks++;
    return picked;
  }

  @override
  Future<void> write(String folderUri, String name, Uint8List bytes) async {
    if (failWith case final error?) throw error;
    files[name] = bytes;
  }

  @override
  Future<List<String>> list(String folderUri) async {
    if (failWith case final error?) throw error;
    return files.keys.toList();
  }

  @override
  Future<void> delete(String folderUri, String name) async => files.remove(name);
}

/// Passphrase vault in memory.
class FakePassphraseVault implements BackupPassphraseVault {
  FakePassphraseVault([this.passphrase]);
  String? passphrase;

  @override
  Future<String?> readPassphrase() async => passphrase;

  @override
  Future<void> savePassphrase(String value) async => passphrase = value;

  @override
  Future<void> forgetPassphrase() async => passphrase = null;
}

/// Records whether the background job is on.
class FakeBackgroundScheduler implements BackgroundBackupScheduler {
  FakeBackgroundScheduler({this.isSupported = true});
  @override
  final bool isSupported;
  bool? enabled;
  int finished = 0;

  @override
  Future<void> setEnabled(bool value) async => enabled = value;

  @override
  Future<void> finishBackgroundRun() async => finished++;
}

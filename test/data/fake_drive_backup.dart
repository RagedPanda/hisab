import 'dart:typed_data';

import 'package:hisab/data/backup/drive_account.dart';
import 'package:hisab/data/backup/drive_backup_store.dart';

/// In-memory [DriveBackupStore]: one optional file, like the real
/// `appDataFolder` copy. Set [failWith] to make every call throw it.
class FakeDriveBackupStore implements DriveBackupStore {
  FakeDriveBackupStore({this.now});
  final DateTime Function()? now;
  Uint8List? bytes;
  DateTime? modifiedAt;
  Object? failWith;
  int uploads = 0;

  void _maybeFail() {
    if (failWith case final error?) throw error;
  }

  @override
  Future<DriveBackupInfo?> lastBackupInfo() async {
    _maybeFail();
    final stored = bytes;
    return stored == null ? null : DriveBackupInfo(modifiedAt: modifiedAt!, sizeBytes: stored.length);
  }

  @override
  Future<DriveBackupInfo> upload(Uint8List data) async {
    _maybeFail();
    bytes = data;
    modifiedAt = (now ?? DateTime.now)();
    uploads++;
    return DriveBackupInfo(modifiedAt: modifiedAt!, sizeBytes: data.length);
  }

  @override
  Future<Uint8List?> download() async {
    _maybeFail();
    return bytes;
  }

  @override
  Future<bool> delete() async {
    _maybeFail();
    final had = bytes != null;
    bytes = null;
    modifiedAt = null;
    return had;
  }
}

/// [DriveAccount] that signs in as [email] without any Google screen.
/// Set [cancelSignIn] to act as if the user closed the sign-in.
class FakeDriveAccount implements DriveAccount {
  FakeDriveAccount({this.email = 'asha@example.com'});
  final String email;
  bool cancelSignIn = false;
  bool disconnected = false;

  @override
  Future<String> connect() async {
    if (cancelSignIn) throw const DriveSignInCancelledException();
    return email;
  }

  @override
  Future<String> accessToken() async => 'token';

  /// Set to act as if Google needs the user to sign in again.
  bool signInNeeded = false;

  @override
  Future<String> silentAccessToken() async {
    if (signInNeeded) throw const DriveSignInNeededException();
    return 'token';
  }

  @override
  Future<void> clearToken(String token) async {}

  @override
  Future<void> disconnect() async => disconnected = true;
}

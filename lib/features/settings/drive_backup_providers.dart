import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/providers.dart';
import '../../data/backup/drive_account.dart';
import '../../data/backup/drive_backup_service.dart';
import '../../data/backup/drive_backup_store.dart';
import '../../data/backup/drive_rest_backup_store.dart';
import '../app_lock/app_lock_providers.dart';

/// Drive backup is Android only for now: iOS personal backup is planned on
/// CloudKit (docs/SYNC_SHARING.md), and Google sign-in there needs an iOS client.
bool get isDriveBackupSupported => defaultTargetPlatform == TargetPlatform.android;

/// Prefs key of the Google account Drive backup is connected to.
const kDriveBackupEmailPref = 'driveBackupEmail';

/// Google sign-in for Drive; tests override it with a fake.
final driveAccountProvider = Provider<DriveAccount>((ref) => GoogleDriveAccount());

/// The Drive `appDataFolder` backup file; tests override it with a fake.
final driveBackupStoreProvider = Provider<DriveBackupStore>((ref) {
  final account = ref.watch(driveAccountProvider);
  final client = http.Client();
  ref.onDispose(client.close);
  return DriveRestBackupStore(client: client, accessToken: account.accessToken, onTokenRejected: account.clearToken);
});

final driveBackupServiceProvider = Provider(
  (ref) => DriveBackupService(backups: ref.watch(backupServiceProvider), store: ref.watch(driveBackupStoreProvider)),
);

/// The connected Google account's email, or null while Drive backup is off.
/// Kept in prefs so Settings shows it offline, without asking Google.
class DriveBackupEmailNotifier extends Notifier<String?> {
  @override
  String? build() => ref.watch(sharedPreferencesProvider).getString(kDriveBackupEmailPref);

  /// Runs the Google sign-in and permission screens, then remembers the account.
  Future<void> connect() async {
    final email = await ref.read(appLockProvider.notifier).whileInSystemScreen(ref.read(driveAccountProvider).connect);
    await ref.read(sharedPreferencesProvider).setString(kDriveBackupEmailPref, email);
    state = email;
  }

  /// Signs out, revokes Hisab's access and forgets the account. The Drive
  /// copy is left alone. Revoking needs a network; offline the account is
  /// still forgotten here, and the user can remove Hisab's access from their
  /// Google account settings.
  Future<void> disconnect() async {
    try {
      await ref.read(driveAccountProvider).disconnect();
    } on Exception {
      // Best effort: see above.
    }
    await ref.read(sharedPreferencesProvider).remove(kDriveBackupEmailPref);
    state = null;
  }
}

final driveBackupEmailProvider = NotifierProvider<DriveBackupEmailNotifier, String?>(DriveBackupEmailNotifier.new);

/// The Drive copy's details, fetched when the connected screen shows.
/// Never retried on its own: each retry could open a Google screen.
final driveLastBackupProvider = FutureProvider.autoDispose<DriveBackupInfo?>(
  (ref) => ref.watch(driveBackupServiceProvider).lastBackupInfo(),
  retry: (_, _) => null,
);

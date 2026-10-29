import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/backup/drive_rest_backup_store.dart';
import 'package:hisab/features/settings/drive_backup_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/fake_drive_backup.dart';

/// An account whose revoke call fails, as it does offline.
class OfflineDriveAccount extends FakeDriveAccount {
  @override
  Future<void> disconnect() async => throw Exception('no network');
}

Future<ProviderContainer> _container(FakeDriveAccount account, {String? connectedEmail}) async {
  SharedPreferences.setMockInitialValues({kDriveBackupEmailPref: ?connectedEmail});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), driveAccountProvider.overrideWithValue(account)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('the real Drive store is built on the signed-in account without touching the network', () async {
    final container = await _container(FakeDriveAccount());

    expect(container.read(driveBackupStoreProvider), isA<DriveRestBackupStore>());
  });

  test('disconnecting offline still forgets the account', () async {
    final container = await _container(OfflineDriveAccount(), connectedEmail: 'asha@example.com');
    expect(container.read(driveBackupEmailProvider), 'asha@example.com');

    await container.read(driveBackupEmailProvider.notifier).disconnect();

    expect(container.read(driveBackupEmailProvider), isNull);
    expect(container.read(sharedPreferencesProvider).getString(kDriveBackupEmailPref), isNull);
  });
}

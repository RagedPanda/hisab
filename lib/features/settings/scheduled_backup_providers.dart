import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/providers.dart';
import '../../data/backup/drive_backup_store.dart';
import '../../data/backup/drive_rest_backup_store.dart';
import '../../data/backup/scheduled_backup_channel.dart';
import '../../data/backup/scheduled_backup_prefs.dart';
import '../../data/backup/scheduled_backup_runner.dart';
import '../../domain/backup/scheduled_backup.dart';
import 'drive_backup_providers.dart';

/// The chosen backup folder; tests override it with a fake.
final backupFolderAccessProvider = Provider<BackupFolderAccess>((ref) => const ScheduledBackupChannel());

/// Where the scheduled-backup passphrase is kept; tests override it.
final backupPassphraseVaultProvider = Provider<BackupPassphraseVault>((ref) => const ScheduledBackupChannel());

/// The Android background job; tests override it.
final backgroundBackupSchedulerProvider = Provider<BackgroundBackupScheduler>((ref) => const ScheduledBackupChannel());

/// The Drive copy as a scheduled run writes it: the token is fetched without
/// any Google screen. Tests override it with a fake.
final scheduledDriveStoreProvider = Provider<DriveBackupStore>((ref) {
  final account = ref.watch(driveAccountProvider);
  final client = http.Client();
  ref.onDispose(client.close);
  return DriveRestBackupStore(client: client, accessToken: account.silentAccessToken, onTokenRejected: account.clearToken);
});

/// Whether the Drive copy can be part of a scheduled backup here.
final scheduledDriveConnectedProvider = Provider<bool>((ref) => isDriveBackupSupported && ref.watch(driveBackupEmailProvider) != null);

/// The user's scheduled backup settings. Saving keeps the background job in
/// step: it runs only while a schedule and a folder are both set.
class ScheduledBackupChoicesNotifier extends Notifier<ScheduledBackupChoices> {
  @override
  ScheduledBackupChoices build() => readScheduledBackupChoices(ref.watch(sharedPreferencesProvider));

  Future<void> save(ScheduledBackupChoices choices) async {
    await writeScheduledBackupChoices(ref.read(sharedPreferencesProvider), choices);
    state = choices;
    await syncBackgroundJob();
  }

  Future<void> syncBackgroundJob() => ref.read(backgroundBackupSchedulerProvider).setEnabled(state.isOn && state.hasFolder);
}

final scheduledBackupChoicesProvider = NotifierProvider<ScheduledBackupChoicesNotifier, ScheduledBackupChoices>(ScheduledBackupChoicesNotifier.new);

/// What the last runs did. [reload] picks up a run the background job made.
class ScheduledBackupHistoryNotifier extends Notifier<ScheduledBackupHistory> {
  @override
  ScheduledBackupHistory build() => readScheduledBackupHistory(ref.watch(sharedPreferencesProvider));

  void reload() => state = readScheduledBackupHistory(ref.read(sharedPreferencesProvider));
}

final scheduledBackupHistoryProvider = NotifierProvider<ScheduledBackupHistoryNotifier, ScheduledBackupHistory>(ScheduledBackupHistoryNotifier.new);

/// Whether a passphrase for scheduled backups is saved on this device.
final hasBackupPassphraseProvider = FutureProvider<bool>((ref) async {
  final passphrase = await ref.watch(backupPassphraseVaultProvider).readPassphrase();
  return passphrase != null && passphrase.isNotEmpty;
});

final scheduledBackupRunnerProvider = Provider(
  (ref) => ScheduledBackupRunner(
    backups: ref.watch(backupServiceProvider),
    folder: ref.watch(backupFolderAccessProvider),
    vault: ref.watch(backupPassphraseVaultProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    driveConnected: ref.watch(scheduledDriveConnectedProvider),
    driveStore: () => ref.read(scheduledDriveStoreProvider),
  ),
);

/// Runs the scheduled backup one run at a time (start, resume and "Back up
/// now" can overlap), then refreshes the history Settings shows. A run asked
/// for while one is in progress is skipped and returns nothing.
class ScheduledBackupGate {
  ScheduledBackupGate(this._ref);
  final Ref _ref;
  bool _running = false;

  Future<Map<ScheduledBackupTarget, BackupAttempt>> runDue(DateTime now) => _guard((runner) => runner.runDue(now));

  Future<Map<ScheduledBackupTarget, BackupAttempt>> runNow(DateTime now) => _guard((runner) => runner.runNow(now));

  Future<Map<ScheduledBackupTarget, BackupAttempt>> _guard(Future<Map<ScheduledBackupTarget, BackupAttempt>> Function(ScheduledBackupRunner runner) run) async {
    if (_running) return const {};
    _running = true;
    try {
      return await run(_ref.read(scheduledBackupRunnerProvider));
    } finally {
      _running = false;
      _ref.read(scheduledBackupHistoryProvider.notifier).reload();
    }
  }
}

final scheduledBackupGateProvider = Provider(ScheduledBackupGate.new);

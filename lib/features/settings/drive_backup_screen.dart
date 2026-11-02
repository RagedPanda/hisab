import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../data/backup/drive_backup_service.dart';
import '../../data/backup/drive_backup_store.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import '../shell/widgets/tile_group.dart';
import 'backup_actions.dart';
import 'drive_backup_providers.dart';

const String kDriveBackupLocation = '/settings/drive-backup';

/// What to tell the user when a Drive action fails with [error].
String driveFailureMessage(AppLocalizations l10n, Object error) => switch (driveBackupFailureOf(error)) {
  DriveBackupFailure.cancelled => l10n.driveErrorCancelled,
  DriveBackupFailure.offline => l10n.driveErrorOffline,
  DriveBackupFailure.notFound => l10n.driveErrorNotFound,
  DriveBackupFailure.wrongPassphrase => restoreFailureMessage(l10n, error),
  DriveBackupFailure.unknown => l10n.driveErrorUnknown('$error'),
};

/// The Drive copy's status line: last backup time, none yet, or checking.
String driveLastBackupLabel(AppLocalizations l10n, AsyncValue<DriveBackupInfo?> lastBackup, {String? locale}) => switch (lastBackup) {
  AsyncData(value: final info?) => l10n.driveLastBackup(formatShortDateTime(info.modifiedAt, locale: locale)),
  AsyncData() => l10n.driveNoBackupYet,
  AsyncError(:final error) => '${l10n.driveBackupStatusUnknown} · ${driveFailureMessage(l10n, error)}',
  _ => l10n.driveCheckingBackup,
};

/// Uploads a backup sealed with [passphrase] in the current currency and
/// number format, then refreshes the last-backup line. Takes the [container]
/// rather than a widget's ref: the screen may close before the upload ends.
Future<void> backUpToDrive(ProviderContainer container, String passphrase) async {
  final settings = container.read(settingsProvider);
  await container
      .read(driveBackupServiceProvider)
      .backUp(passphrase, currencyCode: settings.currencyCode, numberFormat: settings.numberFormat);
  container.invalidate(driveLastBackupProvider);
}

/// Deletes the Drive copy and refreshes the last-backup line. Returns whether
/// there was a copy to delete.
Future<bool> deleteDriveCopy(ProviderContainer container) async {
  final deleted = await container.read(driveBackupServiceProvider).deleteDriveCopy();
  container.invalidate(driveLastBackupProvider);
  return deleted;
}

/// Settings → "Back up to Google Drive": the consent screen until the user
/// connects, then the account, last backup and the manual actions.
class DriveBackupScreen extends ConsumerWidget {
  const DriveBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(driveBackupEmailProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.driveBackupTitle)),
      body: email == null ? const DriveConsentView() : DriveConnectedView(email: email),
    );
  }
}

/// Runs a Drive action with a busy flag, then shows its message or the
/// failure. [action] returns the message for success, or null for none.
mixin _DriveActionRunner<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool busy = false;

  Future<void> runDriveAction(Future<String?> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => busy = true);
    try {
      final message = await action();
      if (message != null) messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(driveFailureMessage(l10n, error))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

/// The consent screen from docs/SYNC_SHARING.md. Skip and Connect are the
/// same size and weight: skipping is a first-class choice.
class DriveConsentView extends ConsumerStatefulWidget {
  const DriveConsentView({super.key});

  @override
  ConsumerState<DriveConsentView> createState() => _DriveConsentViewState();
}

class _DriveConsentViewState extends ConsumerState<DriveConsentView> with _DriveActionRunner {
  void _skip() => context.canPop() ? context.pop() : context.go('/settings');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    Widget bullet(String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(right: 8), child: Text('•')),
          Expanded(child: Text(text)),
        ],
      ),
    );
    return SafeArea(
      child: Column(
        children: [
          if (busy) const LinearProgressIndicator(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              children: [
                Text(l10n.driveConsentTitle, style: theme.textTheme.titleLarge),
                Text(
                  l10n.driveConsentOptional,
                  style: theme.textTheme.titleSmall?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(l10n.driveConsentOffline),
                const SizedBox(height: 12),
                Text(l10n.driveConsentWhat),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: l10n.driveConsentWhyLead,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' ${l10n.driveConsentWhy}'),
                    ],
                  ),
                ),
                bullet(l10n.driveConsentCannotSee),
                bullet(l10n.driveConsentEncrypted),
                bullet(l10n.driveConsentTurnOff),
                const SizedBox(height: 12),
                Text(l10n.driveConsentSkip),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            // Equal height even when one label wraps to two lines.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      key: const Key('driveSkip'),
                      onPressed: busy ? null : _skip,
                      child: Text(l10n.driveSkipForNow, textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonal(
                      key: const Key('driveConnect'),
                      onPressed: busy
                          ? null
                          : () => runDriveAction(() async {
                              await ref.read(driveBackupEmailProvider.notifier).connect();
                              return null;
                            }),
                      child: Text(l10n.driveConnect, textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Connected: the account, when Drive last got a backup, and the actions.
class DriveConnectedView extends ConsumerStatefulWidget {
  const DriveConnectedView({super.key, required this.email});
  final String email;

  @override
  ConsumerState<DriveConnectedView> createState() => _DriveConnectedViewState();
}

class _DriveConnectedViewState extends ConsumerState<DriveConnectedView> with _DriveActionRunner {
  // Each action captures the container before its first await: the screen
  // may close (or Disconnect may swap it out) while Drive is still working.

  Future<void> _backUp() async {
    final container = ProviderScope.containerOf(context, listen: false);
    final passphrase = await promptNewBackupPassphrase(context);
    if (passphrase == null || !mounted) return;
    final l10n = context.l10n;
    await runDriveAction(() async {
      await backUpToDrive(container, passphrase);
      return l10n.driveBackedUp;
    });
  }

  Future<void> _restore() async {
    final container = ProviderScope.containerOf(context, listen: false);
    final passphrase = await promptRestorePassphrase(context);
    if (passphrase == null || !mounted) return;
    final l10n = context.l10n;
    await runDriveAction(() async {
      final restored = await container.read(driveBackupServiceProvider).restore(passphrase);
      await applyRestoredSettings(container, restored);
      return l10n.restoredRecords(restored.written);
    });
  }

  Future<void> _deleteCopy() async {
    final container = ProviderScope.containerOf(context, listen: false);
    final l10n = context.l10n;
    if (!await confirmDialog(context, title: l10n.driveDeleteCopy, message: l10n.driveDeleteConfirm) || !mounted) return;
    await runDriveAction(() async {
      final deleted = await deleteDriveCopy(container);
      return deleted ? l10n.driveCopyDeleted : l10n.driveErrorNotFound;
    });
  }

  Future<void> _disconnect() {
    final l10n = context.l10n;
    return runDriveAction(() async {
      await ref.read(driveBackupEmailProvider.notifier).disconnect();
      return l10n.driveDisconnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final lastBackup = ref.watch(driveLastBackupProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (busy) const LinearProgressIndicator(),
        Card(
          child: ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(l10n.driveConnectedAs(widget.email)),
            subtitle: Text(driveLastBackupLabel(l10n, lastBackup, locale: locale), key: const Key('driveLastBackup')),
          ),
        ),
        const SizedBox(height: 12),
        TileGroup(
          children: [
            ListTile(
              key: const Key('driveBackUpNow'),
              enabled: !busy,
              leading: const Icon(Icons.cloud_upload_outlined),
              title: Text(l10n.driveBackUpNow),
              subtitle: Text(l10n.driveBackUpNowHelp),
              onTap: _backUp,
            ),
            ListTile(
              key: const Key('driveRestore'),
              enabled: !busy,
              leading: const Icon(Icons.cloud_download_outlined),
              title: Text(l10n.driveRestore),
              subtitle: Text(l10n.restoreBackupHelp),
              onTap: _restore,
            ),
          ],
        ),
        const SizedBox(height: 12),
        TileGroup(
          children: [
            ListTile(
              key: const Key('driveDisconnect'),
              enabled: !busy,
              leading: const Icon(Icons.link_off),
              title: Text(l10n.driveDisconnect),
              subtitle: Text(l10n.driveDisconnectHelp),
              onTap: _disconnect,
            ),
            ListTile(
              key: const Key('driveDeleteCopy'),
              enabled: !busy,
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.driveDeleteCopy),
              subtitle: Text(l10n.driveDeleteCopyHelp),
              onTap: _deleteCopy,
            ),
          ],
        ),
      ],
    );
  }
}

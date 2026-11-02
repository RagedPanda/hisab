import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/l10n.dart';
import '../../domain/salary/salary_schedule.dart';
import '../salary/salary_providers.dart';
import '../salary/salary_reminder.dart';
import '../udhaar/udhaar_providers.dart';
import '../upcoming/upcoming_providers.dart';
import 'drive_backup_providers.dart';
import 'scheduled_backup_providers.dart';

/// The word the user types to unlock Erase. Kept in English in every
/// language so it reads the same as on the keyboard.
const kEraseConfirmWord = 'DELETE';

/// Whether [typed] unlocks Erase: the confirm word exactly, spaces around it ignored.
bool eraseConfirmationMatches(String typed) => typed.trim() == kEraseConfirmWord;

/// Asks the user to type [kEraseConfirmWord]. True only when they did and tapped Erase.
Future<bool> confirmEraseAllData(BuildContext context) async =>
    await showDialog<bool>(context: context, builder: (_) => const _EraseConfirmDialog()) ?? false;

/// Wipes the app back to a fresh install: every table (defaults re-seeded),
/// every pref, the Drive connection, and the scheduled backup (its saved
/// passphrase and background job). The Drive copy and the backups already in
/// the folder are left alone. The salary alert is dismissed here too: the
/// reminder watcher is gone with the old screens and cannot do it. Takes the [container] rather than a widget's
/// ref: the fresh start sends the app to onboarding, which unmounts Settings
/// before the erase is done.
Future<void> eraseEverything(ProviderContainer container) async {
  if (container.read(driveBackupEmailProvider) != null) await container.read(driveBackupEmailProvider.notifier).disconnect();
  await container.read(backupPassphraseVaultProvider).forgetPassphrase();
  await container.read(databaseProvider).eraseAllData();
  await container.read(sharedPreferencesProvider).clear();
  container.invalidate(settingsProvider);
  container.invalidate(salarySettingsProvider);
  container.invalidate(myUpiIdProvider);
  container.invalidate(upcomingWindowProvider);
  container.invalidate(driveBackupEmailProvider);
  container.invalidate(scheduledBackupChoicesProvider);
  container.invalidate(scheduledBackupHistoryProvider);
  container.invalidate(hasBackupPassphraseProvider);
  await container.read(scheduledBackupChoicesProvider.notifier).syncBackgroundJob();
  await container.read(reminderSchedulerProvider).rescheduleAll();
  await container.read(salaryAlertSinkProvider).apply(const CancelSalaryNotification());
}

class _EraseConfirmDialog extends StatefulWidget {
  const _EraseConfirmDialog();

  @override
  State<_EraseConfirmDialog> createState() => _EraseConfirmDialogState();
}

class _EraseConfirmDialogState extends State<_EraseConfirmDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final confirmed = eraseConfirmationMatches(_controller.text);
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: scheme.error),
      title: Text(l10n.eraseAllDataTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.eraseAllDataBody(kEraseConfirmWord)),
          const SizedBox(height: 16),
          TextField(
            key: const Key('eraseConfirmField'),
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: l10n.eraseConfirmLabel(kEraseConfirmWord)),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        FilledButton(
          key: const Key('eraseConfirmButton'),
          style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
          onPressed: confirmed ? () => Navigator.pop(context, true) : null,
          child: Text(l10n.eraseAction),
        ),
      ],
    );
  }
}

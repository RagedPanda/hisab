import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../domain/backup/backup_schedule.dart';
import '../../domain/backup/scheduled_backup.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'backup_actions.dart';
import 'drive_backup_providers.dart';
import 'drive_backup_screen.dart';
import 'scheduled_backup_providers.dart';

const String kScheduledBackupLocation = '/settings/scheduled-backup';

String backupFrequencyLabel(AppLocalizations l10n, BackupFrequency frequency) => switch (frequency) {
  BackupFrequency.off => l10n.backupFrequencyOff,
  BackupFrequency.daily => l10n.backupFrequencyDaily,
  BackupFrequency.weekly => l10n.backupFrequencyWeekly,
  BackupFrequency.monthly => l10n.backupFrequencyMonthly,
};

String backupFailureLabel(AppLocalizations l10n, BackupAttempt attempt) => switch (attempt.failure) {
  ScheduledBackupFailure.noPassphrase => l10n.backupFailureNoPassphrase,
  ScheduledBackupFailure.noFolder => l10n.backupFailureNoFolder,
  ScheduledBackupFailure.folderUnavailable => l10n.backupFailureFolderUnavailable,
  ScheduledBackupFailure.signInNeeded => l10n.backupFailureSignInNeeded,
  ScheduledBackupFailure.offline => l10n.backupFailureOffline,
  ScheduledBackupFailure.unknown || null => l10n.backupFailureUnknown(attempt.detail ?? ''),
};

/// Where [target] is, as the user knows it.
String backupPlaceLabel(AppLocalizations l10n, ScheduledBackupTarget target, ScheduledBackupChoices choices) => switch (target) {
  ScheduledBackupTarget.folder => choices.folderName ?? l10n.backupFolder,
  ScheduledBackupTarget.drive => l10n.scheduledBackupGoogleDrive,
};

/// Status of one destination: the failure when the latest attempt failed,
/// otherwise when and where the last backup went, or none yet.
String scheduledBackupStatus(AppLocalizations l10n, ScheduledBackupTarget target, ScheduledBackupChoices choices, ScheduledBackupHistory history, {String? locale}) {
  final attempt = history.lastAttempt[target];
  if (attempt != null && !attempt.succeeded) return l10n.scheduledBackupFailed(formatShortDateTime(attempt.at, locale: locale), backupFailureLabel(l10n, attempt));
  final success = history.lastSuccess[target];
  if (success == null) return l10n.scheduledBackupNone;
  return l10n.scheduledBackupLast(formatShortDateTime(success.at, locale: locale), backupPlaceLabel(l10n, target, choices));
}

/// The Settings row's subtitle: off, or how often plus the most recent
/// attempt's status (a failure shows plainly).
String scheduledBackupSummary(AppLocalizations l10n, ScheduledBackupChoices choices, ScheduledBackupHistory history, {String? locale}) {
  if (!choices.isOn) return l10n.scheduledBackupOff;
  final latest = history.lastAttempt.entries.fold<MapEntry<ScheduledBackupTarget, BackupAttempt>?>(
    null,
    (newest, entry) => newest == null || entry.value.at.isAfter(newest.value.at) ? entry : newest,
  );
  final status = latest == null ? l10n.scheduledBackupNone : scheduledBackupStatus(l10n, latest.key, choices, history, locale: locale);
  return l10n.scheduledBackupSummary(backupFrequencyLabel(l10n, choices.frequency), status);
}

/// Settings → "Scheduled backup": how often, the folder, how many to keep,
/// the Drive copy, the saved passphrase, and what the last runs did.
class ScheduledBackupScreen extends ConsumerStatefulWidget {
  const ScheduledBackupScreen({super.key});

  @override
  ConsumerState<ScheduledBackupScreen> createState() => _ScheduledBackupScreenState();
}

class _ScheduledBackupScreenState extends ConsumerState<ScheduledBackupScreen> {
  bool _busy = false;

  ScheduledBackupChoicesNotifier get _choices => ref.read(scheduledBackupChoicesProvider.notifier);

  /// Asks for a new passphrase and saves it; false when dismissed.
  Future<bool> _setPassphrase() async {
    final passphrase = await promptNewBackupPassphrase(context);
    if (passphrase == null) return false;
    await ref.read(backupPassphraseVaultProvider).savePassphrase(passphrase);
    ref.invalidate(hasBackupPassphraseProvider);
    return true;
  }

  /// Turning a schedule on needs a saved passphrase and, unless Drive is the
  /// only destination, a folder; each is asked for here.
  Future<void> _setFrequency(BackupFrequency frequency) async {
    var choices = ref.read(scheduledBackupChoicesProvider);
    if (frequency != BackupFrequency.off) {
      if (!await ref.read(hasBackupPassphraseProvider.future) && !await _setPassphrase()) return;
      if (!choices.hasFolder && !(choices.includeDrive && ref.read(scheduledDriveConnectedProvider))) {
        final picked = await _pickFolder();
        if (picked == null) return;
        choices = picked;
      }
    }
    await _choices.save(choices.copyWith(frequency: frequency));
  }

  /// Shows the folder picker; returns the choices with the folder, or null when dismissed.
  Future<ScheduledBackupChoices?> _pickFolder() async {
    final folder = await ref.read(backupFolderAccessProvider).pick();
    if (folder == null) return null;
    return ref.read(scheduledBackupChoicesProvider).copyWith(folderUri: folder.uri, folderName: folder.name);
  }

  Future<void> _chooseFolder() async {
    final picked = await _pickFolder();
    if (picked != null) await _choices.save(picked);
  }

  Future<void> _chooseKeep(int current) async {
    final l10n = context.l10n;
    final keep = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.backupsKept),
        children: [
          RadioGroup<int>(
            groupValue: current,
            onChanged: (value) => Navigator.pop(dialogContext, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [for (final count in kBackupsKeptChoices) RadioListTile<int>(value: count, title: Text(l10n.backupsKeptValue(count)))],
            ),
          ),
        ],
      ),
    );
    if (keep != null) await _choices.save(ref.read(scheduledBackupChoicesProvider).copyWith(keep: keep));
  }

  Future<void> _backUpNow() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    if (!await ref.read(hasBackupPassphraseProvider.future) && !await _setPassphrase()) return;
    setState(() => _busy = true);
    try {
      final attempts = await ref.read(scheduledBackupGateProvider).runNow(DateTime.now());
      final failed = attempts.values.where((attempt) => !attempt.succeeded).firstOrNull;
      if (attempts.isNotEmpty) messenger.showSnackBar(SnackBar(content: Text(failed == null ? l10n.scheduledBackupSaved : backupFailureLabel(l10n, failed))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final choices = ref.watch(scheduledBackupChoicesProvider);
    final history = ref.watch(scheduledBackupHistoryProvider);
    final hasPassphrase = ref.watch(hasBackupPassphraseProvider).value ?? false;
    final driveConnected = ref.watch(scheduledDriveConnectedProvider);
    final runsInBackground = ref.watch(backgroundBackupSchedulerProvider).isSupported;
    Widget status(ScheduledBackupTarget target) {
      final failed = history.lastAttempt[target]?.succeeded == false;
      return Text(
        scheduledBackupStatus(l10n, target, choices, history, locale: locale),
        key: Key('scheduledBackupStatus-${target.name}'),
        style: failed ? TextStyle(color: theme.colorScheme.error) : null,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scheduledBackupTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (_busy) const LinearProgressIndicator(),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.backupFrequency, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<BackupFrequency>(
                    key: const Key('backupFrequency'),
                    showSelectedIcon: false,
                    segments: [for (final frequency in BackupFrequency.values) ButtonSegment(value: frequency, label: Text(backupFrequencyLabel(l10n, frequency)))],
                    selected: {choices.frequency},
                    onSelectionChanged: _busy ? null : (selected) => _setFrequency(selected.single),
                  ),
                  const SizedBox(height: 8),
                  Text(runsInBackground ? l10n.scheduledBackupWhenBackground : l10n.scheduledBackupWhenOnOpen, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  key: const Key('backupFolderTile'),
                  enabled: !_busy,
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(choices.hasFolder ? choices.folderName ?? l10n.backupFolder : l10n.backupFolderNotChosen),
                  subtitle: choices.hasFolder ? status(ScheduledBackupTarget.folder) : Text(l10n.backupFolderHelp),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _chooseFolder,
                ),
                ListTile(
                  key: const Key('backupsKeptTile'),
                  enabled: !_busy,
                  leading: const Icon(Icons.layers_outlined),
                  title: Text(l10n.backupsKept),
                  subtitle: Text(l10n.backupsKeptHelp),
                  trailing: SettingValue(l10n.backupsKeptValue(choices.keep)),
                  onTap: () => _chooseKeep(choices.keep),
                ),
                if (isDriveBackupSupported)
                  SwitchListTile(
                    key: const Key('backupIncludeDrive'),
                    secondary: const Icon(Icons.cloud_upload_outlined),
                    title: Text(l10n.backupIncludeDrive),
                    subtitle: driveConnected
                        ? (choices.includeDrive ? status(ScheduledBackupTarget.drive) : Text(l10n.backupIncludeDriveHelp))
                        : Text(l10n.backupIncludeDriveNotConnected),
                    value: choices.includeDrive && driveConnected,
                    onChanged: _busy
                        ? null
                        : driveConnected
                            ? (value) => _choices.save(choices.copyWith(includeDrive: value))
                            : (_) => context.push(kDriveBackupLocation),
                  ),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  key: const Key('scheduledBackupPassphrase'),
                  enabled: !_busy,
                  leading: Icon(hasPassphrase ? Icons.lock_outline : Icons.lock_open_outlined),
                  title: Text(l10n.backupPassphrase),
                  subtitle: Text(
                    hasPassphrase ? l10n.scheduledBackupPassphraseSaved : l10n.scheduledBackupPassphraseMissing,
                    style: hasPassphrase || !choices.isOn ? null : TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: _setPassphrase,
                ),
                ListTile(
                  key: const Key('scheduledBackupNow'),
                  enabled: !_busy,
                  leading: const Icon(Icons.backup_outlined),
                  title: Text(l10n.driveBackUpNow),
                  onTap: _backUpNow,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(l10n.scheduledBackupPassphraseNote, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

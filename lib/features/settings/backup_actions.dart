import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/backup/backup_service.dart';
import '../../l10n/l10n.dart';
import '../salary/salary_providers.dart';
import '../shell/widgets/common.dart';

/// Shortest passphrase a new backup may use.
const kMinBackupPassphraseLength = 8;

/// Asks for the passphrase a new backup is encrypted with. Returns null when
/// dismissed or too short (after saying so).
Future<String?> promptNewBackupPassphrase(BuildContext context) async {
  final l10n = context.l10n;
  final passphrase = await promptText(context, title: l10n.backupPassphrase, hint: l10n.backupPassphraseHelp);
  if (passphrase == null) return null;
  if (passphrase.length < kMinBackupPassphraseLength) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.passphraseTooShort)));
    return null;
  }
  return passphrase;
}

/// Asks for the passphrase an existing backup was made with.
Future<String?> promptRestorePassphrase(BuildContext context) => promptText(context, title: context.l10n.backupPassphrase);

/// Brings the app in step after a restore: settings the backup wrote to
/// prefs, its currency and number format, and reminder alarms.
Future<void> applyRestoredSettings(WidgetRef ref, BackupRestoreResult restored) async {
  // Settings sections (month start, salary) were written to prefs directly.
  ref.invalidate(settingsProvider);
  ref.invalidate(salarySettingsProvider);
  final backupCurrency = restored.currencyCode;
  if (backupCurrency != null) {
    await ref.read(settingsProvider.notifier).update((s) => s.copyWith(currencyCode: backupCurrency, currencyConfirmed: true));
  }
  final backupNumberFormat = restored.numberFormat;
  if (backupNumberFormat != null) {
    await ref.read(settingsProvider.notifier).update((s) => s.copyWith(numberFormat: backupNumberFormat));
  }
  await ref.read(reminderSchedulerProvider).rescheduleAll();
}

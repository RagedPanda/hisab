import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/backup/backup_service.dart';
import '../../domain/backup/backup_passphrase.dart';
import '../../l10n/l10n.dart';
import '../salary/salary_providers.dart';
import '../udhaar/udhaar_providers.dart';

/// Asks for the passphrase a new backup is encrypted with, typed twice.
/// Returns null when dismissed; a short or mismatched entry is explained in
/// the dialog, which stays open.
Future<String?> promptNewBackupPassphrase(BuildContext context) =>
    showDialog<String>(context: context, builder: (_) => const BackupPassphraseDialog(confirm: true));

/// Asks for the passphrase an existing backup was made with.
Future<String?> promptRestorePassphrase(BuildContext context) =>
    showDialog<String>(context: context, builder: (_) => const BackupPassphraseDialog(confirm: false));

/// What to tell the user when restoring a backup failed with [error].
String restoreFailureMessage(AppLocalizations l10n, Object error) => switch (restoreFailureOf(error)) {
  RestoreFailure.wrongPassphrase => l10n.restoreWrongPassphrase,
  RestoreFailure.notABackup => l10n.restoreNotABackup,
  RestoreFailure.unknown => l10n.restoreFailedUnknown,
};

/// The message for a [NewPassphraseProblem].
String newPassphraseProblemLabel(AppLocalizations l10n, NewPassphraseProblem problem) => switch (problem) {
  NewPassphraseProblem.tooShort => l10n.passphraseTooShort,
  NewPassphraseProblem.mismatch => l10n.passphraseMismatch,
};

/// Lines the guidance and problems under a passphrase field may wrap onto,
/// enough for a long translation at the largest text size.
const _kGuidanceMaxLines = 8;

/// Passphrase entry, hidden as it is typed. With [confirm] it asks for the
/// passphrase twice and checks length and match before closing.
class BackupPassphraseDialog extends StatefulWidget {
  const BackupPassphraseDialog({super.key, required this.confirm});

  final bool confirm;

  @override
  State<BackupPassphraseDialog> createState() => _BackupPassphraseDialogState();
}

class _BackupPassphraseDialogState extends State<BackupPassphraseDialog> {
  final _passphrase = TextEditingController();
  final _confirmation = TextEditingController();
  bool _visible = false;
  NewPassphraseProblem? _problem;

  @override
  void dispose() {
    _passphrase.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    final passphrase = _passphrase.text.trim();
    final problem = widget.confirm ? newPassphraseProblem(passphrase, _confirmation.text.trim()) : null;
    if (problem != null) return setState(() => _problem = problem);
    Navigator.pop(context, passphrase);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final problem = _problem;
    return AlertDialog(
      // With the keyboard up and large text, a wrapped error can outgrow the space left.
      scrollable: true,
      title: Text(l10n.backupPassphrase),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('backupPassphraseField'),
            controller: _passphrase,
            autofocus: true,
            obscureText: !_visible,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: widget.confirm ? TextInputAction.next : TextInputAction.done,
            onChanged: (_) => setState(() => _problem = null),
            onSubmitted: widget.confirm ? null : (_) => _submit(),
            decoration: InputDecoration(
              // Guidance sits under the field, where it can wrap; a hint is cut to one line.
              helperText: widget.confirm ? l10n.backupPassphraseHelp : l10n.restorePassphraseHint,
              helperMaxLines: _kGuidanceMaxLines,
              errorText: problem == NewPassphraseProblem.tooShort ? newPassphraseProblemLabel(l10n, NewPassphraseProblem.tooShort) : null,
              errorMaxLines: _kGuidanceMaxLines,
              suffixIcon: IconButton(
                tooltip: _visible ? l10n.passphraseHide : l10n.passphraseShow,
                icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _visible = !_visible),
              ),
            ),
          ),
          if (widget.confirm)
            TextField(
              key: const Key('backupPassphraseConfirmField'),
              controller: _confirmation,
              obscureText: !_visible,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() => _problem = null),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: l10n.passphraseConfirmHint,
                errorText: problem == NewPassphraseProblem.mismatch ? newPassphraseProblemLabel(l10n, NewPassphraseProblem.mismatch) : null,
                errorMaxLines: _kGuidanceMaxLines,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(widget.confirm ? l10n.save : l10n.restorePassphraseAction)),
      ],
    );
  }
}

/// Brings the app in step after a restore: settings the backup wrote to
/// prefs, its currency and number format, and reminder alarms. Takes the
/// [container] rather than a widget's ref: the screen that started the restore
/// may close before this is done.
Future<void> applyRestoredSettings(ProviderContainer container, BackupRestoreResult restored) async {
  // Settings sections (month start, salary, udhaar UPI ID) were written to prefs directly.
  container.invalidate(settingsProvider);
  container.invalidate(salarySettingsProvider);
  container.invalidate(myUpiIdProvider);
  final backupCurrency = restored.currencyCode;
  if (backupCurrency != null) {
    await container.read(settingsProvider.notifier).update((s) => s.copyWith(currencyCode: backupCurrency, currencyConfirmed: true));
  }
  final backupNumberFormat = restored.numberFormat;
  if (backupNumberFormat != null) {
    await container.read(settingsProvider.notifier).update((s) => s.copyWith(numberFormat: backupNumberFormat));
  }
  await container.read(reminderSchedulerProvider).rescheduleAll();
}

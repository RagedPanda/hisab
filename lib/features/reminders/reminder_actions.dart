import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../domain/reminders/reminder_kind.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';

enum _PaidChoice { addEntry, justMark }

/// "Mark paid" from the app: money reminders with an amount offer to add the
/// matching expense first (the editor marks it paid on save); anything else
/// is closed straight away with an Undo snackbar.
Future<void> markReminderPaid(BuildContext context, WidgetRef ref, Reminder reminder) async {
  final l10n = context.l10n;
  final isMoney = ReminderKind.of(reminder.kind).isMoney;
  if (isMoney && reminder.amountMinor != null) {
    final symbol = ref.read(settingsProvider).currencySymbol;
    final choice = await showModalBottomSheet<_PaidChoice>(
      context: context,
      showDragHandle: true,
      useRootNavigator: true,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
            child: Text(l10n.reminderPaidSheetTitle(reminder.title), style: Theme.of(sheetContext).textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(l10n.reminderPaidSheetBody(formatMinor(reminder.amountMinor!, symbol: symbol))),
          ),
          ListTile(
            leading: const Icon(Icons.add_card_outlined),
            title: Text(l10n.reminderAddEntryAndMark),
            onTap: () => Navigator.pop(sheetContext, _PaidChoice.addEntry),
          ),
          ListTile(
            leading: const Icon(Icons.check),
            title: Text(l10n.reminderJustMark),
            onTap: () => Navigator.pop(sheetContext, _PaidChoice.justMark),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice == _PaidChoice.addEntry) {
      await context.push('/entry?reminder=${reminder.id}');
      return;
    }
  }
  if (!context.mounted) return;
  await closeReminderWithUndo(context, ref, reminder, skip: false);
}

/// Marks [reminder] done (or skips it) and offers Undo for six seconds.
Future<void> closeReminderWithUndo(BuildContext context, WidgetRef ref, Reminder reminder, {required bool skip}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final scheduler = ref.read(reminderSchedulerProvider);
  if (skip) {
    await scheduler.skip(reminder.id);
  } else {
    await scheduler.markDone(reminder.id);
  }
  final message = skip
      ? l10n.reminderSkipped
      : ReminderKind.of(reminder.kind).isMoney
          ? l10n.reminderMarkedPaid
          : l10n.reminderMarkedDone;
  showUndoSnackBar(
    messenger,
    message: message,
    undoLabel: l10n.undo,
    onUndo: () => scheduler.undoDone(reminder.id),
    duration: const Duration(seconds: 6),
  );
}

/// Deletes [reminder] (soft) with Undo.
Future<void> deleteReminderWithUndo(BuildContext context, WidgetRef ref, Reminder reminder) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final scheduler = ref.read(reminderSchedulerProvider);
  await scheduler.delete(reminder.id);
  showUndoSnackBar(messenger, message: l10n.reminderDeleted, undoLabel: l10n.undo, onUndo: () => scheduler.restore(reminder.id));
}

/// Asks for the notification permission; when the OS will not show the
/// prompt again, opens the app's system settings instead.
Future<void> turnOnReminderNotifications(WidgetRef ref) async {
  final granted = await ref.read(notificationServiceProvider).requestPermission();
  if (!granted) await openAppSettings();
  ref.invalidate(notificationPermissionProvider);
}

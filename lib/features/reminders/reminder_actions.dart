import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/money.dart';
import '../../core/notifications/alarm_timing.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../domain/reminders/reminder_draft.dart';
import '../../domain/reminders/reminder_kind.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'permission_explainer.dart';

enum _PaidChoice { addEntry, justMark }

/// "Mark paid" from the app: money reminders with an amount offer to add the
/// matching expense first (the editor marks it paid on save); anything else
/// is closed straight away with an Undo snackbar.
Future<void> markReminderPaid(BuildContext context, WidgetRef ref, Reminder reminder) async {
  final l10n = context.l10n;
  final isMoney = ReminderKind.of(reminder.kind).isMoney;
  final amount = reminderAmountOrNone(reminder.amountMinor);
  if (isMoney && amount != null) {
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
            child: Text(l10n.reminderPaidSheetBody(formatMinor(amount, symbol: symbol))),
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
/// prompt again, opens the app's system settings instead. Once granted,
/// follows with the "Alarms & reminders" sheet so alerts fire on time.
///
/// These flows read providers through the container, not a WidgetRef: the
/// widget that started them (the notifications-off banner, an editor sheet)
/// can be gone by the time the answers come back. The permission is
/// re-read only at the end so the caller stays put while the sheets show.
Future<void> turnOnReminderNotifications(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final granted = await container.read(notificationServiceProvider).requestPermission();
  if (!granted) await openAppSettings();
  if (granted && context.mounted) await askExactReminderAlarmsIfNeeded(context);
  container.invalidate(notificationPermissionProvider);
}

/// Pre-permission sheets shown when a reminder with alerts is saved while
/// notifications are off: first the notification permission, then (Android
/// 12+, when not granted) "Alarms & reminders" so alerts fire on time
/// (decision 22). Used by every flow that creates a reminder with alerts,
/// including groups' settle-up schedules; it is saved either way. [title] and
/// [body] default to the reminders wording.
Future<void> askReminderPermissionsIfNeeded(BuildContext context, {String? title, String? body}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final service = container.read(notificationServiceProvider);
  final before = await service.checkPermission();
  if (before.notificationsAllowed || !context.mounted) return;
  final l10n = context.l10n;
  final allow = await showPermissionExplainer(context, icon: Icons.notifications_active_outlined, title: title ?? l10n.notifPrePromptTitle, body: body ?? l10n.notifPrePromptBody);
  if (allow) await service.requestPermission();
  if (context.mounted) await askExactReminderAlarmsIfNeeded(context);
  container.invalidate(notificationPermissionProvider);
}

/// The "Alarms & reminders" sheet, shown only while notifications are on but
/// alerts would be posted inexact (see [shouldAskForExactAlarms]).
Future<void> askExactReminderAlarmsIfNeeded(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final permission = await container.read(notificationServiceProvider).checkPermission();
  if (!shouldAskForExactAlarms(permission) || !context.mounted) return;
  final l10n = context.l10n;
  final allowExact = await showPermissionExplainer(context, icon: Icons.alarm_on_outlined, title: l10n.exactAlarmPromptTitle, body: l10n.exactAlarmPromptBody);
  if (allowExact) await allowExactReminderAlarms(container);
}

/// Opens Android's "Alarms & reminders" setting for Hisab. When access is
/// granted, every alert is re-posted exact straight away (the resume check in
/// reminder_startup.dart also catches a grant made after this returns).
Future<void> allowExactReminderAlarms(ProviderContainer container) async {
  final granted = await container.read(notificationServiceProvider).requestExactAlarms();
  if (granted) await container.read(reminderSchedulerProvider).rescheduleAll();
  container.invalidate(notificationPermissionProvider);
}

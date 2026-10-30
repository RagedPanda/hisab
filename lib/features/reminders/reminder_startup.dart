import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/alarm_timing.dart';
import '../../core/notifications/notification_gateway.dart';
import '../../core/notifications/reminder_payload.dart';
import '../../core/notifications/reminder_tap_gate.dart';
import '../../core/providers.dart';
import '../accounts/card_reminder_sync.dart';
import '../groups/settle_reminder_service.dart';
import '../notifications/evening_summary_service.dart';
import '../salary/salary_reminder.dart';
import '../shell/router.dart';

/// Drops the second delivery of a cold-start tap (launch details plus callback).
final _tapGate = ReminderTapGate();

/// Opens the screen a reminder notification (or its Mark paid button) points
/// at; Snooze is applied in place without opening anything. A tap delivered
/// twice is handled once.
Future<void> handleReminderTap(ProviderContainer container, NotificationTap tap) async {
  if (!_tapGate.admit(tap)) return;
  if (tap.payload == kSalaryAlertPayload) {
    appRouter.push(kSalaryLocation);
    return;
  }
  final reminderId = reminderIdFromPayload(tap.payload);
  if (reminderId == null) return;
  if (tap.actionId == kSnoozeActionId) {
    await container.read(reminderSchedulerProvider).snooze(reminderId);
    return;
  }
  final location = reminderLocationFor(payload: tap.payload, actionId: tap.actionId);
  if (location != null) appRouter.push(location);
}

/// Sets up notifications after the first frame: listens for taps, follows
/// the tap that launched the app, and re-posts every pending reminder (this
/// is what restores alerts after a reboot, an app update, a force stop or a
/// time-zone change). Card due reminders are brought up to date first, so a
/// card's next bill gets its reminder, and then kept live as accounts and
/// entries change. Never throws: reminders still work in-app without it.
Future<void> startReminderNotifications(ProviderContainer container) async {
  try {
    final service = container.read(notificationServiceProvider);
    await service.initialize(onTap: (tap) => handleReminderTap(container, tap));
    final launch = await service.launchTap();
    if (launch != null) await handleReminderTap(container, launch);
    await container.read(settleReminderServiceProvider).refreshAll();
    NotificationPermissionState? known = await service.checkPermission();
    await syncCardReminderSafely(() => container.read(cardReminderSyncProvider).syncAll());
    container.read(cardReminderLiveSyncProvider);
    await container.read(reminderSchedulerProvider).rescheduleAll();
    // Re-post the salary alert now the plugin is ready (the first sync can beat it).
    await syncSalaryReminder(container.read, now: DateTime.now());
    await refreshEveningSummary(container.read);
    _resumeListener?.dispose();
    // The evening summary's text is worked out ahead, so it is redone each
    // time the app comes back or is left, when the day's figures may have moved.
    _resumeListener = AppLifecycleListener(
      onResume: () async {
        known = await recheckAlarmAccess(container, known);
        await refreshEveningSummary(container.read);
      },
      onPause: () => refreshEveningSummary(container.read),
    );
  } catch (error, stack) {
    debugPrint('Hisab: reminder notifications unavailable: $error\n$stack');
  }
}

AppLifecycleListener? _resumeListener;

/// On app resume: refreshes the permission state the Reminders screen shows
/// and, when "Alarms & reminders" access changed (the user just toggled it in
/// Settings), re-posts every alert so they become exact, or inexact, at once.
/// A revoke also kills the process; the next launch's rescheduleAll covers it.
/// Returns the state now known. Never throws.
Future<NotificationPermissionState?> recheckAlarmAccess(ProviderContainer container, NotificationPermissionState? previous) async {
  try {
    final current = await container.read(notificationServiceProvider).checkPermission();
    container.invalidate(notificationPermissionProvider);
    if (exactAlarmAccessChanged(previous, current)) await container.read(reminderSchedulerProvider).rescheduleAll();
    return current;
  } catch (error, stack) {
    debugPrint('Hisab: alarm access check failed: $error\n$stack');
    return previous;
  }
}

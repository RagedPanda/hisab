import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/alarm_timing.dart';
import '../../core/notifications/notification_gateway.dart';
import '../../core/notifications/reminder_payload.dart';
import '../../core/notifications/reminder_tap_gate.dart';
import '../../core/providers.dart';
import '../shell/router.dart';

/// Drops the second delivery of a cold-start tap (launch details plus callback).
final _tapGate = ReminderTapGate();

/// Opens the screen a reminder notification (or its Mark paid button) points
/// at; Snooze is applied in place without opening anything. A tap delivered
/// twice is handled once.
Future<void> handleReminderTap(ProviderContainer container, NotificationTap tap) async {
  if (!_tapGate.admit(tap)) return;
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
/// time-zone change). Never throws: reminders still work in-app without it.
Future<void> startReminderNotifications(ProviderContainer container) async {
  try {
    final service = container.read(notificationServiceProvider);
    await service.initialize(onTap: (tap) => handleReminderTap(container, tap));
    final launch = await service.launchTap();
    if (launch != null) await handleReminderTap(container, launch);
    NotificationPermissionState? known = await service.checkPermission();
    await container.read(reminderSchedulerProvider).rescheduleAll();
    _resumeListener?.dispose();
    _resumeListener = AppLifecycleListener(onResume: () async => known = await recheckAlarmAccess(container, known));
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

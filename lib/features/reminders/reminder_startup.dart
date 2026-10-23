import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_gateway.dart';
import '../../core/notifications/reminder_payload.dart';
import '../../core/notifications/reminder_tap_gate.dart';
import '../../core/providers.dart';
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
/// time-zone change). Never throws: reminders still work in-app without it.
Future<void> startReminderNotifications(ProviderContainer container) async {
  try {
    final service = container.read(notificationServiceProvider);
    await service.initialize(onTap: (tap) => handleReminderTap(container, tap));
    final launch = await service.launchTap();
    if (launch != null) await handleReminderTap(container, launch);
    await container.read(reminderSchedulerProvider).rescheduleAll();
    // Re-post the salary alert now the plugin is ready (the first sync can beat it).
    await syncSalaryReminder(container.read, now: DateTime.now());
  } catch (error, stack) {
    debugPrint('Hisab: reminder notifications unavailable: $error\n$stack');
  }
}

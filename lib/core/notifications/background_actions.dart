import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/db/database.dart';
import '../../data/repositories/reminders_repository.dart';
import '../../data/repositories/settle_schedule_repository.dart';
import '../settings.dart';
import 'notification_service.dart';
import 'plugin_notification_gateway.dart';
import 'reminder_alert_text.dart';
import 'reminder_payload.dart';
import 'reminder_scheduler.dart';

/// Builds the reminder scheduler outside the widget tree: in the background
/// action isolate, and in main() before the first frame.
ReminderScheduler buildReminderScheduler(AppDatabase db, AppSettings settings) {
  final l10n = notificationLocalizations(settings.localeCode);
  return ReminderScheduler(
    reminders: RemindersRepository(db),
    settleSchedules: SettleScheduleRepository(db),
    notifications: NotificationService(
      PluginNotificationGateway(notificationSetupTexts(l10n)),
      buildAlert: (reminder, alert) => alertRequestFor(reminder, alert, l10n, moneyFormat: homeMoneyFormatFor(settings, PlatformDispatcher.instance.locale)),
    ),
  );
}

/// Notification actions that do not open the app (Snooze) arrive here, in a
/// fresh background isolate, even when Hisab is not running.
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  handleBackgroundAction(payload: response.payload, actionId: response.actionId);
}

Future<void> handleBackgroundAction({required String? payload, required String? actionId}) async {
  final reminderId = reminderIdFromPayload(payload);
  if (reminderId == null || actionId != kSnoozeActionId) return;
  DartPluginRegistrant.ensureInitialized();
  final settings = AppSettings.fromPrefs(await SharedPreferences.getInstance());
  final db = AppDatabase();
  try {
    await buildReminderScheduler(db, settings).snooze(reminderId);
  } finally {
    await db.close();
  }
}

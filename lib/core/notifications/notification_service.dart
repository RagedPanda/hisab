import '../../data/db/database.dart';
import '../../domain/reminders/reminder_kind.dart';
import '../../domain/reminders/reminder_schedule.dart';
import 'notification_gateway.dart';
import 'reminder_payload.dart';

/// Builds the notification for one planned alert (texts, labels, payload).
typedef AlertBuilder = AlertRequest Function(Reminder reminder, PlannedAlert alert);

/// The one place Hisab posts local notifications. Every feature that wants a
/// due-date nudge stores a reminder row and calls [schedule] (or goes through
/// ReminderScheduler, which does both); nothing else talks to the plugin.
///
/// Exact alarms are used when the OS allows them; otherwise alerts are posted
/// inexact (a few minutes late is fine for bills) and nothing is blocked.
class NotificationService {
  NotificationService(this._gateway, {required this.buildAlert, DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final NotificationGateway _gateway;

  /// Turns a planned alert into the notification posted (texts in the app language).
  final AlertBuilder buildAlert;
  final DateTime Function() _clock;

  Future<void> initialize({required void Function(NotificationTap tap) onTap}) => _gateway.initialize(onTap: onTap);

  /// The notification tap that cold-started the app, if any.
  Future<NotificationTap?> launchTap() => _gateway.launchTap();

  Future<NotificationPermissionState> checkPermission() => _gateway.permissionState();

  /// Shows the system notification prompt; true when notifications are allowed.
  Future<bool> requestPermission() => _gateway.requestPermission();

  /// Opens the Android "Alarms & reminders" setting; true when exact alarms are allowed.
  Future<bool> requestExactAlarms() => _gateway.requestExactAlarms();

  /// Replaces every alert of [reminder] with the ones still due at now.
  /// Done, skipped, deleted or un-timed reminders end up with none.
  /// Returns what was posted.
  Future<List<PlannedAlert>> schedule(Reminder reminder) async {
    await cancel(reminder.id, daysBefore: parseRemindDaysBefore(reminder.remindDaysBefore));
    final alerts = _plan(reminder);
    if (alerts.isEmpty) return alerts;
    final exact = (await _gateway.permissionState()).exactAlarmsAllowed;
    for (final alert in alerts) {
      await _gateway.schedule(buildAlert(reminder, alert), exact: exact);
    }
    return alerts;
  }

  /// Removes every alert of the reminder [reminderId], posted or pending.
  Future<void> cancel(String reminderId, {List<int> daysBefore = const []}) async {
    final ids = {
      ...allNotificationIdsFor(reminderId, daysBefore),
      for (final pending in await _gateway.pending())
        if (reminderIdFromPayload(pending.payload) == reminderId) pending.id,
    };
    for (final id in ids) {
      await _gateway.cancel(id);
    }
  }

  /// Drops every pending reminder alert and posts [reminders] afresh. Run on
  /// app start (covers reboot, app update and time-zone change) and after a
  /// backup restore. Returns how many alerts were posted.
  Future<int> rescheduleAll(List<Reminder> reminders) async {
    for (final pending in await _gateway.pending()) {
      if (reminderIdFromPayload(pending.payload) != null) await _gateway.cancel(pending.id);
    }
    final exact = (await _gateway.permissionState()).exactAlarmsAllowed;
    var posted = 0;
    for (final reminder in reminders) {
      for (final alert in _plan(reminder)) {
        await _gateway.schedule(buildAlert(reminder, alert), exact: exact);
        posted++;
      }
    }
    return posted;
  }

  List<PlannedAlert> _plan(Reminder reminder) {
    final schedulable = reminder.deletedAt == null && reminder.status == ReminderStatus.pending && reminder.dueAt != null;
    if (!schedulable) return const [];
    return planAlerts(
      reminderId: reminder.id,
      dueAt: reminder.dueAt!,
      daysBefore: parseRemindDaysBefore(reminder.remindDaysBefore),
      notifyAtMinute: reminder.notifyAtMinute,
      snoozedUntil: reminder.snoozedUntil,
      now: _clock(),
    );
  }
}

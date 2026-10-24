import 'notification_gateway.dart';

/// Pure rules for on-time alerts (owner decision 22: reminders fire on time).
///
/// Android 12+ gates exact alarms behind "Alarms & reminders"
/// (SCHEDULE_EXACT_ALARM; Android 14+ does not pre-grant it). With it, alerts
/// are posted exact; without it they fall back to inexact, which can be late,
/// and the Reminders screen says so. iOS always reports exact as allowed.

/// Whether alerts are posted as exact alarms.
bool useExactAlarms(NotificationPermissionState permission) => permission.exactAlarmsAllowed;

/// Whether to explain and ask for "Alarms & reminders": notifications are on
/// but alerts would be posted inexact.
bool shouldAskForExactAlarms(NotificationPermissionState permission) =>
    permission.notificationsAllowed && !permission.exactAlarmsAllowed;

/// Whether the Reminders screen shows "Reminders may arrive late": some
/// reminder has alerts, notifications are on, exact alarms are not allowed.
bool remindersMayArriveLate(NotificationPermissionState? permission, {required bool hasAlerts}) =>
    permission != null && hasAlerts && shouldAskForExactAlarms(permission);

/// Whether posted alerts must be re-posted because the exact-alarm access
/// changed since [previous] (null when unknown: nothing to compare yet).
bool exactAlarmAccessChanged(NotificationPermissionState? previous, NotificationPermissionState current) =>
    previous != null && previous.exactAlarmsAllowed != current.exactAlarmsAllowed;

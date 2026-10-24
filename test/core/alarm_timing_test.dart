import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/notifications/alarm_timing.dart';
import 'package:hisab/core/notifications/notification_gateway.dart';

NotificationPermissionState _state({bool notifications = true, bool exact = true}) =>
    NotificationPermissionState(notificationsAllowed: notifications, exactAlarmsAllowed: exact);

void main() {
  test('alerts are exact when Alarms & reminders is allowed, inexact otherwise', () {
    expect(useExactAlarms(_state()), isTrue);
    expect(useExactAlarms(_state(exact: false)), isFalse);
  });

  test('ask for Alarms & reminders only when notifications are on and exact is not', () {
    expect(shouldAskForExactAlarms(_state(exact: false)), isTrue);
    expect(shouldAskForExactAlarms(_state()), isFalse);
    expect(shouldAskForExactAlarms(_state(notifications: false, exact: false)), isFalse, reason: 'the notifications-off banner comes first');
  });

  test('the may-arrive-late note needs a reminder with alerts and the inexact fallback', () {
    expect(remindersMayArriveLate(_state(exact: false), hasAlerts: true), isTrue);
    expect(remindersMayArriveLate(_state(exact: false), hasAlerts: false), isFalse);
    expect(remindersMayArriveLate(_state(), hasAlerts: true), isFalse);
    expect(remindersMayArriveLate(null, hasAlerts: true), isFalse, reason: 'permission not known yet');
  });

  test('a change of exact-alarm access triggers a reschedule; no change or no baseline does not', () {
    expect(exactAlarmAccessChanged(_state(exact: false), _state()), isTrue);
    expect(exactAlarmAccessChanged(_state(), _state(exact: false)), isTrue);
    expect(exactAlarmAccessChanged(_state(), _state()), isFalse);
    expect(exactAlarmAccessChanged(_state(exact: false), _state(notifications: false, exact: false)), isFalse);
    expect(exactAlarmAccessChanged(null, _state()), isFalse);
  });
}

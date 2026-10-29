import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'background_actions.dart';
import 'notification_gateway.dart';
import 'reminder_payload.dart';
import 'sms_entry_payload.dart';

const String _channelId = 'reminders';
const String _smsChannelId = 'sms_entries';
const String _moneyCategoryId = 'reminderMoney';
const String _doneCategoryId = 'reminderDone';

/// [NotificationGateway] on flutter_local_notifications. The only file that
/// imports the plugin.
class PluginNotificationGateway implements NotificationGateway {
  PluginNotificationGateway(this._texts, {FlutterLocalNotificationsPlugin? plugin}) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final NotificationSetupTexts _texts;
  final FlutterLocalNotificationsPlugin _plugin;
  static Future<void>? _timeZoneReady;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  /// Loads the time-zone database and the device zone once per isolate.
  static Future<void> ensureTimeZone() => _timeZoneReady ??= () async {
        tz_data.initializeTimeZones();
        try {
          final zone = await FlutterTimezone.getLocalTimezone();
          tz.setLocalLocation(tz.getLocation(zone.identifier));
        } catch (error) {
          // Unknown zone name: keep UTC; alerts are still posted, at the UTC wall time.
          debugPrint('Hisab: local time zone unavailable ($error)');
        }
      }();

  @override
  Future<void> initialize({required void Function(NotificationTap tap) onTap}) async {
    await ensureTimeZone();
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(
          // Asked for from the Reminders flow, never at launch.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(_moneyCategoryId, actions: [
              DarwinNotificationAction.plain(kMarkPaidActionId, _texts.markPaidLabel, options: {DarwinNotificationActionOption.foreground}),
              DarwinNotificationAction.plain(kSnoozeActionId, _texts.snoozeLabel),
            ]),
            DarwinNotificationCategory(_doneCategoryId, actions: [
              DarwinNotificationAction.plain(kMarkPaidActionId, _texts.doneLabel, options: {DarwinNotificationActionOption.foreground}),
              DarwinNotificationAction.plain(kSnoozeActionId, _texts.snoozeLabel),
            ]),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: (response) => onTap(NotificationTap(payload: response.payload, actionId: response.actionId)),
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationResponse,
    );
    await _android?.createNotificationChannel(AndroidNotificationChannel(
      _channelId,
      _texts.channelName,
      description: _texts.channelDescription,
      importance: Importance.high,
    ));
  }

  @override
  Future<NotificationTap?> launchTap() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    final response = details?.notificationResponse;
    if (details?.didNotificationLaunchApp != true || response == null) return null;
    return NotificationTap(payload: response.payload, actionId: response.actionId);
  }

  @override
  Future<void> schedule(AlertRequest request, {required bool exact}) async {
    await ensureTimeZone();
    await _plugin.zonedSchedule(
      id: request.id,
      title: request.title,
      body: request.body,
      payload: request.payload,
      scheduledDate: tz.TZDateTime.from(request.fireAt, tz.local),
      androidScheduleMode: exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _texts.channelName,
          channelDescription: _texts.channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          category: AndroidNotificationCategory.reminder,
          actions: request.withActions
              ? [
                  AndroidNotificationAction(kMarkPaidActionId, request.markPaidLabel, showsUserInterface: true),
                  AndroidNotificationAction(kSnoozeActionId, request.snoozeLabel),
                ]
              : null,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: request.withActions ? (request.isMoney ? _moneyCategoryId : _doneCategoryId) : null,
        ),
      ),
    );
  }

  /// Android only: Bank SMS is read on Android alone.
  @override
  Future<void> show(SmsEntryAlert alert) => _plugin.show(
        id: alert.id,
        title: alert.title,
        body: alert.body,
        payload: alert.payload,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _smsChannelId,
            _texts.smsChannelName,
            channelDescription: _texts.smsChannelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@drawable/ic_notification',
            category: AndroidNotificationCategory.status,
            styleInformation: BigTextStyleInformation(alert.body),
            actions: [
              AndroidNotificationAction(kSmsChangeCategoryActionId, alert.changeCategoryLabel, showsUserInterface: true),
              AndroidNotificationAction(kSmsUndoActionId, alert.undoLabel),
            ],
          ),
        ),
      );

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<List<PendingAlert>> pending() async => [
        for (final request in await _plugin.pendingNotificationRequests()) PendingAlert(id: request.id, payload: request.payload),
      ];

  @override
  Future<NotificationPermissionState> permissionState() async {
    final android = _android;
    if (android != null) {
      return NotificationPermissionState(
        notificationsAllowed: await android.areNotificationsEnabled() ?? false,
        exactAlarmsAllowed: await android.canScheduleExactNotifications() ?? false,
      );
    }
    final options = await _ios?.checkPermissions();
    return NotificationPermissionState(notificationsAllowed: options?.isEnabled ?? false, exactAlarmsAllowed: true);
  }

  @override
  Future<bool> requestPermission() async {
    final android = _android;
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    return await _ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
  }

  @override
  Future<bool> requestExactAlarms() async => await _android?.requestExactAlarmsPermission() ?? true;
}

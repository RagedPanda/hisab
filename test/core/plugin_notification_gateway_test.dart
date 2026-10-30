import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/notifications/notification_gateway.dart';
import 'package:hisab/core/notifications/plugin_notification_gateway.dart';
import 'package:hisab/core/notifications/reminder_payload.dart';
import 'package:timezone/timezone.dart' as tz;

const _texts = NotificationSetupTexts(channelName: 'Reminders', channelDescription: 'Bills and documents', markPaidLabel: 'Mark paid', doneLabel: 'Done', snoozeLabel: 'Snooze 1 day');

/// Android side of the plugin: answers permission questions and records the
/// channel it was asked to create.
class FakeAndroidPlugin implements AndroidFlutterLocalNotificationsPlugin {
  FakeAndroidPlugin({this.notificationsEnabled, this.exactAllowed, this.grantNotifications, this.grantExact});

  final bool? notificationsEnabled;
  final bool? exactAllowed;
  final bool? grantNotifications;
  final bool? grantExact;
  final List<AndroidNotificationChannel> channels = [];

  @override
  Future<void> createNotificationChannel(AndroidNotificationChannel notificationChannel) async => channels.add(notificationChannel);

  @override
  Future<bool?> areNotificationsEnabled() async => notificationsEnabled;

  @override
  Future<bool?> canScheduleExactNotifications() async => exactAllowed;

  @override
  Future<bool?> requestNotificationsPermission() async => grantNotifications;

  @override
  Future<bool?> requestExactAlarmsPermission() async => grantExact;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// iOS side of the plugin.
class FakeIosPlugin implements IOSFlutterLocalNotificationsPlugin {
  FakeIosPlugin({this.options, this.granted});

  final NotificationsEnabledOptions? options;
  final bool? granted;
  final List<({bool alert, bool badge, bool sound})> requests = [];

  @override
  Future<NotificationsEnabledOptions?> checkPermissions() async => options;

  @override
  Future<bool?> requestPermissions({bool sound = false, bool alert = false, bool badge = false, bool provisional = false, bool critical = false, bool carPlay = false, bool providesAppNotificationSettings = false}) async {
    requests.add((alert: alert, badge: badge, sound: sound));
    return granted;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stands in for the plugin singleton and records every call the gateway makes.
class FakeNotificationsPlugin implements FlutterLocalNotificationsPlugin {
  FakeNotificationsPlugin({this.android, this.ios, this.launchDetails, this.pendingRequests = const []});

  final FakeAndroidPlugin? android;
  final FakeIosPlugin? ios;
  final NotificationAppLaunchDetails? launchDetails;
  final List<PendingNotificationRequest> pendingRequests;

  InitializationSettings? initializationSettings;
  DidReceiveNotificationResponseCallback? onResponse;
  DidReceiveBackgroundNotificationResponseCallback? onBackgroundResponse;
  final List<({int id, String? title, String? payload, tz.TZDateTime scheduledDate, NotificationDetails details, AndroidScheduleMode mode})> scheduled = [];
  final List<int> cancelled = [];
  final List<({int id, String? title, NotificationDetails? details})> shown = [];

  @override
  Future<void> show({required int id, String? title, String? body, NotificationDetails? notificationDetails, String? payload}) async =>
      shown.add((id: id, title: title, details: notificationDetails));

  @override
  T? resolvePlatformSpecificImplementation<T extends FlutterLocalNotificationsPlatform>() {
    if (T == AndroidFlutterLocalNotificationsPlugin) return android as T?;
    if (T == IOSFlutterLocalNotificationsPlugin) return ios as T?;
    return null;
  }

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback? onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializationSettings = settings;
    onResponse = onDidReceiveNotificationResponse;
    onBackgroundResponse = onDidReceiveBackgroundNotificationResponse;
    return true;
  }

  @override
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() async => launchDetails;

  @override
  Future<void> zonedSchedule({
    required int id,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? title,
    String? body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async =>
      scheduled.add((id: id, title: title, payload: payload, scheduledDate: scheduledDate, details: notificationDetails, mode: androidScheduleMode));

  @override
  Future<void> cancel({required int id, String? tag}) async => cancelled.add(id);

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async => pendingRequests;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AlertRequest alertRequest({bool withActions = true, bool isMoney = true}) => AlertRequest(
      id: 41,
      title: 'Electricity bill',
      body: 'Due in 3 days',
      fireAt: DateTime.utc(2026, 11, 2, 3, 30),
      payload: reminderPayload('power'),
      markPaidLabel: isMoney ? 'Mark paid' : 'Done',
      snoozeLabel: 'Snooze 1 day',
      isMoney: isMoney,
      withActions: withActions,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // The device zone, as flutter_timezone reports it.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (call) async => call.method == 'getLocalTimezone' ? 'Asia/Kolkata' : null,
    );
    await PluginNotificationGateway.ensureTimeZone();
  });

  test('loads the device time zone once per isolate', () async {
    expect(tz.local.name, 'Asia/Kolkata');
    await PluginNotificationGateway.ensureTimeZone();
    expect(tz.local.name, 'Asia/Kolkata');
  });

  group('initialize', () {
    test('creates the Android channel and registers both action categories for iOS', () async {
      final android = FakeAndroidPlugin();
      final plugin = FakeNotificationsPlugin(android: android);
      final taps = <NotificationTap>[];

      await PluginNotificationGateway(_texts, plugin: plugin).initialize(onTap: taps.add);

      expect(android.channels.map((channel) => channel.id), ['reminders', 'updates']);
      final channel = android.channels.first;
      expect(channel.id, 'reminders');
      expect(channel.name, 'Reminders');
      expect(channel.description, 'Bills and documents');
      expect(channel.importance, Importance.high);
      final darwin = plugin.initializationSettings!.iOS!;
      expect(darwin.requestAlertPermission, isFalse, reason: 'permission is asked from the Reminders flow, never at launch');
      expect(darwin.notificationCategories.map((category) => category.identifier), ['reminderMoney', 'reminderDone']);
      expect(darwin.notificationCategories.first.actions.map((action) => action.title), ['Mark paid', 'Snooze 1 day']);
      expect(darwin.notificationCategories.last.actions.map((action) => action.title), ['Done', 'Snooze 1 day']);
      expect(plugin.onBackgroundResponse, isNotNull);

      plugin.onResponse!(NotificationResponse(notificationResponseType: NotificationResponseType.selectedNotificationAction, payload: reminderPayload('power'), actionId: kMarkPaidActionId));
      expect(taps.single.payload, reminderPayload('power'));
      expect(taps.single.actionId, kMarkPaidActionId);
    });

    test('skips the channel where there is no Android plugin', () async {
      final plugin = FakeNotificationsPlugin();
      await PluginNotificationGateway(_texts, plugin: plugin).initialize(onTap: (_) {});
      expect(plugin.initializationSettings, isNotNull);
    });
  });

  group('launchTap', () {
    test('returns the tap that launched the app', () async {
      final plugin = FakeNotificationsPlugin(
        launchDetails: NotificationAppLaunchDetails(
          true,
          notificationResponse: NotificationResponse(notificationResponseType: NotificationResponseType.selectedNotification, payload: reminderPayload('power')),
        ),
      );
      final tap = await PluginNotificationGateway(_texts, plugin: plugin).launchTap();
      expect(tap?.payload, reminderPayload('power'));
      expect(tap?.actionId, isNull);
    });

    test('is null when the app was opened normally', () async {
      final normalLaunch = FakeNotificationsPlugin(launchDetails: const NotificationAppLaunchDetails(false));
      expect(await PluginNotificationGateway(_texts, plugin: normalLaunch).launchTap(), isNull);
      expect(await PluginNotificationGateway(_texts, plugin: FakeNotificationsPlugin()).launchTap(), isNull);
    });
  });

  group('schedule', () {
    test('posts an exact alarm with Mark paid and Snooze actions at the local wall time', () async {
      final plugin = FakeNotificationsPlugin();
      await PluginNotificationGateway(_texts, plugin: plugin).schedule(alertRequest(), exact: true);

      final posted = plugin.scheduled.single;
      expect(posted.id, 41);
      expect(posted.title, 'Electricity bill');
      expect(posted.payload, reminderPayload('power'));
      expect(posted.mode, AndroidScheduleMode.exactAllowWhileIdle);
      expect(posted.scheduledDate.location.name, 'Asia/Kolkata');
      expect(posted.scheduledDate.isAtSameMomentAs(DateTime.utc(2026, 11, 2, 3, 30)), isTrue);
      final android = posted.details.android!;
      expect(android.channelId, 'reminders');
      expect(android.category, AndroidNotificationCategory.reminder);
      expect(android.actions!.map((action) => action.id), [kMarkPaidActionId, kSnoozeActionId]);
      expect(android.actions!.first.showsUserInterface, isTrue);
      expect(posted.details.iOS!.categoryIdentifier, 'reminderMoney');
    });

    test('a document reminder uses the Done category', () async {
      final plugin = FakeNotificationsPlugin();
      await PluginNotificationGateway(_texts, plugin: plugin).schedule(alertRequest(isMoney: false), exact: true);
      expect(plugin.scheduled.single.details.iOS!.categoryIdentifier, 'reminderDone');
    });

    test('a plain nudge has no actions and may fire inexactly', () async {
      final plugin = FakeNotificationsPlugin();
      await PluginNotificationGateway(_texts, plugin: plugin).schedule(alertRequest(withActions: false), exact: false);
      final posted = plugin.scheduled.single;
      expect(posted.mode, AndroidScheduleMode.inexactAllowWhileIdle);
      expect(posted.details.android!.actions, isNull);
      expect(posted.details.iOS!.categoryIdentifier, isNull);
    });
  });

  test('show posts at once on the updates channel, without actions', () async {
    final plugin = FakeNotificationsPlugin();
    final request = AlertRequest(
      id: 7,
      title: 'Sample · Your day in Hisab',
      body: 'Nothing spent today',
      fireAt: DateTime(2026, 10, 29, 21),
      payload: 'hisab://sample',
      markPaidLabel: '',
      snoozeLabel: '',
      isMoney: false,
      withActions: false,
      channel: AlertChannel.updates,
    );

    await PluginNotificationGateway(_texts, plugin: plugin).show(request);

    final android = plugin.shown.single.details!.android!;
    expect(plugin.shown.single.id, 7);
    expect(android.channelId, 'updates');
    expect(android.channelName, 'Reminders', reason: 'falls back to the reminders channel name when none is given');
    expect(android.actions, isNull);
    expect(plugin.scheduled, isEmpty);
  });

  test('cancel and pending pass through to the plugin', () async {
    final plugin = FakeNotificationsPlugin(pendingRequests: [PendingNotificationRequest(41, 'Electricity bill', 'Due', reminderPayload('power'))]);
    final gateway = PluginNotificationGateway(_texts, plugin: plugin);

    await gateway.cancel(41);
    final pending = await gateway.pending();

    expect(plugin.cancelled, [41]);
    expect(pending.single.id, 41);
    expect(pending.single.payload, reminderPayload('power'));
  });

  group('permissions on Android', () {
    test('reads both permissions, treating unknown as denied', () async {
      final allowed = PluginNotificationGateway(_texts, plugin: FakeNotificationsPlugin(android: FakeAndroidPlugin(notificationsEnabled: true, exactAllowed: true)));
      final state = await allowed.permissionState();
      expect(state.notificationsAllowed, isTrue);
      expect(state.exactAlarmsAllowed, isTrue);

      final unknown = await PluginNotificationGateway(_texts, plugin: FakeNotificationsPlugin(android: FakeAndroidPlugin())).permissionState();
      expect(unknown.notificationsAllowed, isFalse);
      expect(unknown.exactAlarmsAllowed, isFalse);
    });

    test('requests pass the user answer through', () async {
      final granting = PluginNotificationGateway(_texts, plugin: FakeNotificationsPlugin(android: FakeAndroidPlugin(grantNotifications: true, grantExact: false)));
      expect(await granting.requestPermission(), isTrue);
      expect(await granting.requestExactAlarms(), isFalse);

      final silent = PluginNotificationGateway(_texts, plugin: FakeNotificationsPlugin(android: FakeAndroidPlugin()));
      expect(await silent.requestPermission(), isFalse);
      expect(await silent.requestExactAlarms(), isTrue, reason: 'no answer means the platform has no exact-alarm gate');
    });
  });

  group('permissions on iOS', () {
    const enabled = NotificationsEnabledOptions(
      isEnabled: true,
      isSoundEnabled: true,
      isAlertEnabled: true,
      isBadgeEnabled: true,
      isProvisionalEnabled: false,
      isCriticalEnabled: false,
      isProvidesAppNotificationSettingsEnabled: false,
    );

    test('exact alarms are always allowed; notifications follow the settings', () async {
      final state = await PluginNotificationGateway(_texts, plugin: FakeNotificationsPlugin(ios: FakeIosPlugin(options: enabled))).permissionState();
      expect(state.notificationsAllowed, isTrue);
      expect(state.exactAlarmsAllowed, isTrue);
    });

    test('asks for alert, badge and sound together', () async {
      final ios = FakeIosPlugin(granted: true);
      expect(await PluginNotificationGateway(_texts, plugin: FakeNotificationsPlugin(ios: ios)).requestPermission(), isTrue);
      expect(ios.requests.single, (alert: true, badge: true, sound: true));
    });
  });

  test('with no platform plugin nothing is allowed and exact alarms need no grant', () async {
    final gateway = PluginNotificationGateway(_texts, plugin: FakeNotificationsPlugin());
    final state = await gateway.permissionState();
    expect(state.notificationsAllowed, isFalse);
    expect(state.exactAlarmsAllowed, isTrue);
    expect(await gateway.requestPermission(), isFalse);
    expect(await gateway.requestExactAlarms(), isTrue);
  });
}

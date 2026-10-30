import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hisab/core/notifications/notification_gateway.dart';
import 'package:hisab/core/notifications/plugin_notification_gateway.dart';
import 'package:hisab/core/notifications/reminder_alert_text.dart';
import 'package:hisab/core/providers.dart';

import 'gateway_call_log.dart';

export 'gateway_call_log.dart';

/// iOS only: grants provisional notification authorization, which iOS gives
/// silently with no system prompt on a simulator that has never been asked.
/// The OS then accepts and lists scheduled requests, so flows can assert the
/// real pending list. Returns whether iOS accepted (true on other platforms).
Future<bool> grantProvisionalNotificationsOnIOS() async {
  if (!Platform.isIOS) return true;
  final ios = FlutterLocalNotificationsPlugin().resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
  return await ios?.requestPermissions(alert: true, badge: true, sound: true, provisional: true) ?? false;
}

/// The real plugin gateway, recording every schedule and cancel into [log].
class RecordingNotificationGateway implements NotificationGateway {
  RecordingNotificationGateway(this._delegate, this.log);

  final NotificationGateway _delegate;
  final GatewayCallLog log;

  @override
  Future<void> initialize({required void Function(NotificationTap tap) onTap}) => _delegate.initialize(onTap: onTap);
  @override
  Future<NotificationTap?> launchTap() => _delegate.launchTap();
  @override
  Future<void> schedule(AlertRequest request, {required bool exact}) {
    log.recordPost(request);
    return _delegate.schedule(request, exact: exact);
  }

  @override
  Future<void> show(ShownAlert alert) => _delegate.show(alert);

  @override
  Future<void> cancel(int id) {
    log.recordCancel(id);
    return _delegate.cancel(id);
  }

  @override
  Future<List<PendingAlert>> pending() => _delegate.pending();
  @override
  Future<NotificationPermissionState> permissionState() => _delegate.permissionState();
  @override
  Future<bool> requestPermission() => _delegate.requestPermission();
  @override
  Future<bool> requestExactAlarms() => _delegate.requestExactAlarms();
}

/// Overrides the gateway with a recording wrapper around the same plugin
/// gateway the app builds (mirrors `notificationGatewayProvider`).
Override recordingGatewayOverride(GatewayCallLog log) => notificationGatewayProvider.overrideWith((ref) {
      final localeCode = ref.watch(settingsProvider.select((settings) => settings.localeCode));
      return RecordingNotificationGateway(PluginNotificationGateway(notificationSetupTexts(notificationLocalizations(localeCode))), log);
    });

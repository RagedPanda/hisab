import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hisab/core/notifications/notification_gateway.dart';
import 'package:hisab/core/notifications/plugin_notification_gateway.dart';
import 'package:hisab/core/notifications/reminder_alert_text.dart';
import 'package:hisab/core/providers.dart';

/// What the app asked the OS to schedule and cancel, kept across gateway
/// rebuilds (the gateway provider rebuilds when the app language changes).
class GatewayCallLog {
  final List<AlertRequest> scheduled = [];
  final List<int> cancelled = [];

  /// Alert ids scheduled for [payload] that were never cancelled afterwards.
  Set<int> liveIdsFor(String payload) {
    final live = <int>{};
    for (final request in scheduled.where((request) => request.payload == payload)) {
      live.add(request.id);
    }
    return live.difference(cancelled.toSet());
  }
}

/// Whether the OS pending list shows what was scheduled. iOS drops requests
/// while notification permission is undecided or denied (a fresh simulator
/// cannot grant it headlessly), so there only the gateway calls can be checked.
bool osPendingIsObservable({required bool isIOS, required bool notificationsAllowed}) => !isIOS || notificationsAllowed;

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
    log.scheduled.add(request);
    return _delegate.schedule(request, exact: exact);
  }

  @override
  Future<void> cancel(int id) {
    log.cancelled.add(id);
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

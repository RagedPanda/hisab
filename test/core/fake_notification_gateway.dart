import 'package:hisab/core/notifications/notification_gateway.dart';

/// In-memory [NotificationGateway]: records what would be posted.
class FakeNotificationGateway implements NotificationGateway {
  FakeNotificationGateway({this.notificationsAllowed = true, this.exactAlarmsAllowed = true, this.grantOnRequest = true, this.grantExactOnRequest = false});

  bool notificationsAllowed;
  bool exactAlarmsAllowed;
  bool grantOnRequest;
  bool grantExactOnRequest;
  int exactRequests = 0;
  final Map<int, AlertRequest> scheduled = {};
  final Map<int, bool> exactById = {};
  final List<int> cancelled = [];
  int permissionRequests = 0;
  NotificationTap? launch;

  /// When set, scheduling at or before this clock's time throws, as the
  /// plugin's zonedSchedule does.
  DateTime Function()? clock;

  /// When true, exact scheduling throws (exact alarms revoked mid-way).
  bool failExact = false;
  void Function(NotificationTap tap)? onTap;

  @override
  Future<void> initialize({required void Function(NotificationTap tap) onTap}) async => this.onTap = onTap;

  @override
  Future<NotificationTap?> launchTap() async => launch;

  @override
  Future<void> schedule(AlertRequest request, {required bool exact}) async {
    final now = clock?.call();
    if (now != null && !request.fireAt.isAfter(now)) throw ArgumentError.value(request.fireAt, 'scheduledDate', 'Must be a date in the future');
    if (exact && failExact) throw StateError('exact alarms not permitted');
    scheduled[request.id] = request;
    exactById[request.id] = exact;
  }

  /// SMS entry notifications shown, by id.
  final Map<int, SmsEntryAlert> shown = {};

  @override
  Future<void> show(SmsEntryAlert alert) async => shown[alert.id] = alert;

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.remove(id);
    shown.remove(id);
  }

  @override
  Future<List<PendingAlert>> pending() async => [for (final request in scheduled.values) PendingAlert(id: request.id, payload: request.payload)];

  @override
  Future<NotificationPermissionState> permissionState() async =>
      NotificationPermissionState(notificationsAllowed: notificationsAllowed, exactAlarmsAllowed: exactAlarmsAllowed);

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    if (grantOnRequest) notificationsAllowed = true;
    return notificationsAllowed;
  }

  @override
  Future<bool> requestExactAlarms() async {
    exactRequests++;
    if (grantExactOnRequest) exactAlarmsAllowed = true;
    return exactAlarmsAllowed;
  }

  /// Alerts posted for [payload], earliest first.
  List<AlertRequest> alertsFor(String payload) =>
      scheduled.values.where((request) => request.payload == payload).toList()..sort((a, b) => a.fireAt.compareTo(b.fireAt));
}

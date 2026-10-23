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
  void Function(NotificationTap tap)? onTap;

  @override
  Future<void> initialize({required void Function(NotificationTap tap) onTap}) async => this.onTap = onTap;

  @override
  Future<NotificationTap?> launchTap() async => launch;

  @override
  Future<void> schedule(AlertRequest request, {required bool exact}) async {
    scheduled[request.id] = request;
    exactById[request.id] = exact;
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.remove(id);
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

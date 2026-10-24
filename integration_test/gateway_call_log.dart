import 'package:hisab/core/notifications/notification_gateway.dart';

/// One gateway call: a post of [payload] under [id], or a cancel of [id]
/// (when [payload] is null).
typedef GatewayCall = ({int id, String? payload});

/// What the app asked the OS to schedule and cancel, in call order, kept
/// across gateway rebuilds (the gateway provider rebuilds when the app
/// language changes).
class GatewayCallLog {
  final List<GatewayCall> calls = [];

  void recordPost(AlertRequest request) => calls.add((id: request.id, payload: request.payload));
  void recordCancel(int id) => calls.add((id: id, payload: null));

  /// Alert ids still live for [payload] after replaying every call in order.
  /// Order matters: the service cancels an alert's ids before re-posting
  /// them, so a cancel followed by a post of the same id leaves it live (#94).
  Set<int> liveIdsFor(String payload) => liveIdsAfter(calls, payload);
}

/// Replays [calls] in order and returns the ids whose latest call is a post
/// of [payload].
Set<int> liveIdsAfter(List<GatewayCall> calls, String payload) {
  final live = <int, String>{};
  for (final call in calls) {
    final posted = call.payload;
    if (posted == null) {
      live.remove(call.id);
    } else {
      live[call.id] = posted;
    }
  }
  return {for (final entry in live.entries) if (entry.value == payload) entry.key};
}

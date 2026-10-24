import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/notifications/notification_gateway.dart';

import '../../integration_test/gateway_call_log.dart';

void main() {
  const payload = 'reminder:7';

  test('cancel then post of the same id leaves it live (#94)', () {
    final calls = <GatewayCall>[(id: 70, payload: null), (id: 70, payload: payload)];
    expect(liveIdsAfter(calls, payload), {70});
  });

  test('post then cancel of the same id leaves nothing live', () {
    final calls = <GatewayCall>[(id: 70, payload: payload), (id: 70, payload: null)];
    expect(liveIdsAfter(calls, payload), isEmpty);
  });

  test('reschedule cycle: post, cancel, re-post, then a final cancel', () {
    final calls = <GatewayCall>[
      (id: 70, payload: payload),
      (id: 71, payload: payload),
      (id: 70, payload: null),
      (id: 71, payload: null),
      (id: 70, payload: payload),
    ];
    expect(liveIdsAfter(calls, payload), {70});
    expect(liveIdsAfter([...calls, (id: 70, payload: null)], payload), isEmpty);
  });

  test('only ids whose latest post carries the payload count', () {
    final calls = <GatewayCall>[(id: 70, payload: payload), (id: 70, payload: 'reminder:8'), (id: 80, payload: payload)];
    expect(liveIdsAfter(calls, payload), {80});
  });

  test('the log records posts and cancels in call order', () {
    final request = AlertRequest(id: 70, title: 'Electricity bill', body: 'Due today', fireAt: DateTime(2026, 11, 5, 9), payload: payload, markPaidLabel: 'Mark paid', snoozeLabel: 'Snooze 1 day', isMoney: true);
    final log = GatewayCallLog()
      ..recordCancel(70)
      ..recordPost(request);
    expect(log.liveIdsFor(payload), {70});
    log.recordCancel(70);
    expect(log.liveIdsFor(payload), isEmpty);
  });
}

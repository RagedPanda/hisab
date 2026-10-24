import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/notifications/notification_gateway.dart';
import 'package:hisab/core/notifications/reminder_tap_gate.dart';

void main() {
  const markPaid = NotificationTap(payload: 'reminder:r1', actionId: 'mark_paid');
  final start = DateTime(2026, 10, 23, 9);

  test('isDuplicateTap: same key inside the window only', () {
    final key = tapKey(markPaid);
    expect(isDuplicateTap(previousKey: null, previousAt: null, key: key, now: start), isFalse);
    expect(isDuplicateTap(previousKey: key, previousAt: start, key: key, now: start.add(const Duration(seconds: 2))), isTrue);
    expect(isDuplicateTap(previousKey: key, previousAt: start, key: key, now: start.add(kDuplicateTapWindow)), isFalse);
    expect(isDuplicateTap(previousKey: key, previousAt: start, key: tapKey(const NotificationTap(payload: 'reminder:r1')), now: start), isFalse);
  });

  test('a cold-start tap delivered twice is admitted once', () {
    var now = start;
    final gate = ReminderTapGate(clock: () => now);
    expect(gate.admit(markPaid), isTrue, reason: 'launch details');
    now = now.add(const Duration(milliseconds: 300));
    expect(gate.admit(markPaid), isFalse, reason: 'response callback for the same tap');
  });

  test('a different tap, or the same one later, gets through', () {
    var now = start;
    final gate = ReminderTapGate(clock: () => now);
    expect(gate.admit(markPaid), isTrue);
    expect(gate.admit(const NotificationTap(payload: 'reminder:r2', actionId: 'mark_paid')), isTrue);
    now = now.add(const Duration(minutes: 1));
    expect(gate.admit(const NotificationTap(payload: 'reminder:r2', actionId: 'mark_paid')), isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/notifications/reminder_payload.dart';

void main() {
  test('payload round-trips and rejects other links', () {
    expect(reminderIdFromPayload(reminderPayload('abc')), 'abc');
    expect(reminderIdFromPayload('hisab://reminder/'), isNull);
    expect(reminderIdFromPayload('hisab://sms?text=x'), isNull);
    expect(reminderIdFromPayload(null), isNull);
  });

  test('tap opens the reminder, Mark paid opens a prefilled entry, Snooze opens nothing', () {
    final payload = reminderPayload('r1');
    expect(reminderLocationFor(payload: payload, actionId: null), '/reminders/r1');
    expect(reminderLocationFor(payload: payload, actionId: kMarkPaidActionId), '/entry?reminder=r1');
    expect(reminderLocationFor(payload: payload, actionId: kSnoozeActionId), isNull);
    expect(reminderLocationFor(payload: 'other', actionId: null), isNull);
  });
}

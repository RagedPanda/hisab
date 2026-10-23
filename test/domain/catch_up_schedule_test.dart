import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/recurring/catch_up_schedule.dart';
import 'package:hisab/domain/recurring/repeat_draft.dart' show RecurringStatus;

void main() {
  test('nextLocalMidnight is the start of the following day', () {
    expect(nextLocalMidnight(DateTime(2026, 10, 23, 13, 51)), DateTime(2026, 10, 24));
    expect(nextLocalMidnight(DateTime(2026, 10, 23)), DateTime(2026, 10, 24), reason: 'exactly midnight waits for the next one');
    expect(nextLocalMidnight(DateTime(2026, 12, 31, 23, 59)), DateTime(2027, 1, 1));
    expect(nextLocalMidnight(DateTime(2028, 2, 28, 8)), DateTime(2028, 2, 29));
  });

  test('delayUntilNextDay reaches just past midnight', () {
    expect(delayUntilNextDay(DateTime(2026, 10, 23, 23, 59, 30)), const Duration(seconds: 31));
    expect(delayUntilNextDay(DateTime(2026, 10, 23, 12), slack: Duration.zero), const Duration(hours: 12));
  });

  group('nextWakeAt', () {
    final now = DateTime(2026, 10, 23, 8, 58);
    WakeRule rule(DateTime? nextDue, {String status = RecurringStatus.active}) => (status: status, nextDue: nextDue);

    test('wakes at a 09:00 occurrence due later today', () {
      expect(nextWakeAt([rule(DateTime(2026, 10, 23, 9)), rule(DateTime(2026, 10, 23, 18))], now), DateTime(2026, 10, 23, 9));
    });

    test('wakes at midnight when the next occurrence is after it', () {
      expect(nextWakeAt([rule(DateTime(2026, 11, 5, 9))], now), DateTime(2026, 10, 24));
      expect(nextWakeAt([rule(DateTime(2026, 10, 24, 0, 30))], now), DateTime(2026, 10, 24));
    });

    test('wakes at midnight with no rules', () {
      expect(nextWakeAt(const [], now), DateTime(2026, 10, 24));
    });

    test('ignores paused and ended rules', () {
      expect(nextWakeAt([rule(DateTime(2026, 10, 23, 9), status: RecurringStatus.paused), rule(null, status: RecurringStatus.ended)], now), DateTime(2026, 10, 24));
    });

    test('ignores occurrences already due, so a waiting confirm-first rule cannot spin the timer', () {
      expect(nextWakeAt([rule(DateTime(2026, 10, 23, 8)), rule(now)], now), DateTime(2026, 10, 24));
    });
  });

  test('delayUntil never goes below the slack for a wake already passed', () {
    expect(delayUntil(DateTime(2026, 10, 23, 9), DateTime(2026, 10, 23, 9, 5)), const Duration(seconds: 1));
  });
}

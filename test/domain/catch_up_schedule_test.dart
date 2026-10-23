import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/recurring/catch_up_schedule.dart';

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
}

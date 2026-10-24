import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';

void main() {
  test('groupConsecutiveByDay keeps order and starts a run on each new day', () {
    final times = [DateTime(2026, 10, 22, 21), DateTime(2026, 10, 22, 8), DateTime(2026, 10, 20, 12), DateTime(2026, 10, 20, 9)];
    final groups = groupConsecutiveByDay(times, (time) => time);
    expect(groups.map((group) => group.day), [DateTime(2026, 10, 22), DateTime(2026, 10, 20)]);
    expect(groups.first.items, times.sublist(0, 2));
    expect(groupConsecutiveByDay(const <DateTime>[], (time) => time), isEmpty);
  });
}

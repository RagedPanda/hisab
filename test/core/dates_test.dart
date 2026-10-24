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

  test('isoDay and parseIsoDay round-trip a calendar day', () {
    expect(isoDay(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
    expect(parseIsoDay('2026-03-07'), DateTime(2026, 3, 7));
    expect(parseIsoDay(isoDay(DateTime(2027, 12, 31))), DateTime(2027, 12, 31));
  });

  test('parseIsoDay rejects missing, malformed and impossible days', () {
    expect(parseIsoDay(null), isNull);
    expect(parseIsoDay(''), isNull);
    expect(parseIsoDay('2026-3-7'), isNull);
    expect(parseIsoDay('2026-02-30'), isNull);
    expect(parseIsoDay('2026-10-24T10:00'), isNull);
  });
}

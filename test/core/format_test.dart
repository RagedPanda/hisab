import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/format.dart';

void main() {
  test('joinWithOverflow shows the first names and a +N tail', () {
    String more(int remaining) => '+$remaining';
    expect(joinWithOverflow(const ['Groceries', 'Restaurants'], max: 3, overflow: more), 'Groceries, Restaurants');
    expect(joinWithOverflow(const ['a', 'b', 'c'], max: 3, overflow: more), 'a, b, c');
    expect(joinWithOverflow(const ['a', 'b', 'c', 'd', 'e'], max: 3, overflow: more), 'a, b, c, +2');
    expect(joinWithOverflow(const <String>[], max: 3, overflow: more), '');
  });

  group('formatDayLabel', () {
    final now = DateTime(2026, 10, 29, 12);
    String label(DateTime day) => formatDayLabel(day, today: 'Today', yesterday: 'Yesterday', now: now);

    test('names today and yesterday', () {
      expect(label(DateTime(2026, 10, 29, 8)), 'Today');
      expect(label(DateTime(2026, 10, 28, 23)), 'Yesterday');
    });

    test('drops the year inside the current year and keeps it outside', () {
      expect(label(DateTime(2026, 10, 2)), 'Fri, 2 Oct');
      expect(label(DateTime(2025, 12, 31)), '31 Dec 2025');
    });
  });

  test('formatQuantity trims trailing zeros and appends the unit', () {
    expect(formatQuantity(2, 'kg'), '2 kg');
    expect(formatQuantity(1.5, null), '1.5');
    expect(formatQuantity(0.25, ''), '0.25');
  });
}

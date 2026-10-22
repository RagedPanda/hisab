import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/upcoming/calendar_grid.dart';

void main() {
  test('October 2026 starts on a Thursday, padded to full weeks', () {
    final cells = calendarMonthCells(DateTime(2026, 10, 22));
    expect(cells.length % 7, 0);
    expect(cells.take(3), everyElement(isNull));
    expect(cells[3], DateTime(2026, 10, 1));
    expect(cells.whereType<DateTime>().length, 31);
    expect(cells.whereType<DateTime>().last, DateTime(2026, 10, 31));
    expect(cells.length, 35);
  });

  test('a month starting on the first weekday has no leading pad', () {
    final cells = calendarMonthCells(DateTime(2027, 2));
    expect(cells.first, DateTime(2027, 2, 1));
    expect(cells.length, 28);
  });

  test('Sunday-first weeks shift the padding', () {
    final cells = calendarMonthCells(DateTime(2026, 11), firstWeekday: DateTime.sunday);
    expect(cells.first, DateTime(2026, 11, 1));
    expect(calendarWeekdays(firstWeekday: DateTime.sunday), [7, 1, 2, 3, 4, 5, 6]);
    expect(calendarWeekdays(), [1, 2, 3, 4, 5, 6, 7]);
  });

  test('leap February has 29 days', () {
    expect(calendarMonthCells(DateTime(2028, 2)).whereType<DateTime>().length, 29);
  });
}

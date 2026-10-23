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

  group('calendarFirstWeekday follows the device region for the app language', () {
    int weekStart(String app, List<String> device) => calendarFirstWeekday(appLanguage: app, deviceLocaleTags: device);

    test('en-GB starts on Monday and en-US on Sunday', () {
      expect(weekStart('en', ['en-GB']), DateTime.monday);
      expect(weekStart('en', ['en_US']), DateTime.sunday);
      expect(weekStart('en', ['en-IN']), DateTime.sunday);
      expect(weekStart('en', ['en-AE']), DateTime.saturday);
      expect(weekStart('en', ['en-Latn-GB']), DateTime.monday, reason: 'a script subtag is skipped');
    });

    test('the first device locale in the app language decides', () {
      expect(weekStart('en', ['de-DE', 'en-GB', 'en-US']), DateTime.monday);
      expect(weekStart('hi', ['en-GB', 'hi-IN']), DateTime.sunday);
    });

    test('without a matching region the language default applies', () {
      expect(weekStart('en', []), DateTime.sunday);
      expect(weekStart('en', ['en']), DateTime.sunday);
      expect(weekStart('hi', ['en-GB']), DateTime.sunday);
      expect(weekStart('xx', []), DateTime.monday);
    });
  });
}

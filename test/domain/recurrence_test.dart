import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/domain/recurring/recurrence.dart';

RecurrenceSpec monthly(DateTime start, {int? day, int interval = 1, DateTime? endDate, int? maxCount}) =>
    RecurrenceSpec(frequency: RecurrenceFrequency.monthly, start: start, dayOfMonth: day, interval: interval, endDate: endDate, maxCount: maxCount);

List<DateTime> take(RecurrenceSpec spec, int count, {int monthStartDay = 1}) {
  final result = [firstOccurrence(spec, monthStartDay: monthStartDay)];
  while (result.length < count) {
    result.add(nextAfter(spec, result.last, monthStartDay: monthStartDay));
  }
  return result;
}

void main() {
  group('daysInMonth and resolveDayOfMonth', () {
    test('handles leap years including century rules', () {
      expect(daysInMonth(2024, 2), 29);
      expect(daysInMonth(2026, 2), 28);
      expect(daysInMonth(2000, 2), 29);
      expect(daysInMonth(2100, 2), 28);
      expect(daysInMonth(2026, 12), 31);
    });

    test('clamps to short months and resolves the special days', () {
      expect(resolveDayOfMonth(31, 2026, 4), 30);
      expect(resolveDayOfMonth(30, 2026, 2), 28);
      expect(resolveDayOfMonth(kLastDayOfMonth, 2024, 2), 29);
      expect(resolveDayOfMonth(kMonthStartDayOfMonth, 2026, 10, monthStartDay: 25), 25);
      expect(resolveDayOfMonth(kMonthStartDayOfMonth, 2026, 10), 1);
    });
  });

  group('monthly', () {
    test('the 31st keeps coming back after short months', () {
      final dates = take(monthly(DateTime(2026, 1, 31, 9)), 4);
      expect(dates, [DateTime(2026, 1, 31, 9), DateTime(2026, 2, 28, 9), DateTime(2026, 3, 31, 9), DateTime(2026, 4, 30, 9)]);
    });

    test('the last day of the month follows leap Februaries', () {
      final dates = take(monthly(DateTime(2024, 1, 10), day: kLastDayOfMonth), 3);
      expect(dates, [DateTime(2024, 1, 31), DateTime(2024, 2, 29), DateTime(2024, 3, 31)]);
    });

    test('a day already past in the start month moves to the next month', () {
      expect(firstOccurrence(monthly(DateTime(2026, 10, 20), day: 5)), DateTime(2026, 11, 5));
      expect(firstOccurrence(monthly(DateTime(2026, 10, 5, 18, 30), day: 5)), DateTime(2026, 10, 5, 18, 30));
    });

    test('every three months crosses the year end', () {
      final dates = take(monthly(DateTime(2026, 11, 15), interval: 3), 3);
      expect(dates, [DateTime(2026, 11, 15), DateTime(2027, 2, 15), DateTime(2027, 5, 15)]);
    });

    test('the month start day setting decides a salary-day rule', () {
      final spec = monthly(DateTime(2026, 10, 1), day: kMonthStartDayOfMonth);
      expect(take(spec, 2, monthStartDay: 25), [DateTime(2026, 10, 25), DateTime(2026, 11, 25)]);
      expect(take(spec, 2), [DateTime(2026, 10, 1), DateTime(2026, 11, 1)]);
    });

    test('occurrencesInRange counts what falls in a salary month', () {
      final rent = monthly(DateTime(2026, 1, 1), day: 5);
      final salaryMonth = monthRange(DateTime(2026, 10, 30), startDay: 25);
      expect(occurrencesInRange(rent, salaryMonth, monthStartDay: 25), [DateTime(2026, 11, 5)]);
      final everyOther = monthly(DateTime(2026, 1, 1), day: 5, interval: 2);
      expect(occurrencesInRange(everyOther, monthRange(DateTime(2026, 10, 10)), monthStartDay: 1), isEmpty);
      expect(occurrencesInRange(everyOther, monthRange(DateTime(2026, 9, 10)), monthStartDay: 1), [DateTime(2026, 9, 5)]);
    });
  });

  group('weekly and daily', () {
    test('weekly lands on the chosen weekday and steps by the interval', () {
      // 22 Oct 2026 is a Thursday; Monday is weekday 1.
      final spec = RecurrenceSpec(frequency: RecurrenceFrequency.weekly, start: DateTime(2026, 10, 22, 8), weekday: DateTime.monday, interval: 2);
      expect(take(spec, 3), [DateTime(2026, 10, 26, 8), DateTime(2026, 11, 9, 8), DateTime(2026, 11, 23, 8)]);
    });

    test('weekly defaults to the start weekday', () {
      final spec = RecurrenceSpec(frequency: RecurrenceFrequency.weekly, start: DateTime(2026, 10, 22));
      expect(take(spec, 2), [DateTime(2026, 10, 22), DateTime(2026, 10, 29)]);
    });

    test('daily crosses month and leap day boundaries', () {
      final spec = RecurrenceSpec(frequency: RecurrenceFrequency.daily, start: DateTime(2028, 2, 28, 7), interval: 1);
      expect(take(spec, 3), [DateTime(2028, 2, 28, 7), DateTime(2028, 2, 29, 7), DateTime(2028, 3, 1, 7)]);
      final everyTen = RecurrenceSpec(frequency: RecurrenceFrequency.daily, start: DateTime(2026, 12, 25), interval: 10);
      expect(take(everyTen, 2).last, DateTime(2027, 1, 4));
    });
  });

  group('yearly', () {
    test('29 Feb falls back to 28 Feb in common years and returns in leap years', () {
      final spec = RecurrenceSpec(frequency: RecurrenceFrequency.yearly, start: DateTime(2024, 2, 29));
      expect(take(spec, 5), [DateTime(2024, 2, 29), DateTime(2025, 2, 28), DateTime(2026, 2, 28), DateTime(2027, 2, 28), DateTime(2028, 2, 29)]);
    });

    test('a date already past this year moves to next year', () {
      final spec = RecurrenceSpec(frequency: RecurrenceFrequency.yearly, start: DateTime(2026, 3, 12));
      expect(firstOnOrAfter(spec, DateTime(2026, 10, 22)), DateTime(2027, 3, 12));
    });
  });

  group('end conditions and catch-up', () {
    test('dueOccurrences catches up every missed month up to now', () {
      final spec = monthly(DateTime(2026, 7, 1), day: 1);
      final due = dueOccurrences(spec, nextDue: DateTime(2026, 7, 1), now: DateTime(2026, 10, 22));
      expect(due, [DateTime(2026, 7, 1), DateTime(2026, 8, 1), DateTime(2026, 9, 1), DateTime(2026, 10, 1)]);
    });

    test('an occurrence later today is not yet due', () {
      final spec = monthly(DateTime(2026, 10, 22, 18), day: 22);
      expect(dueOccurrences(spec, nextDue: DateTime(2026, 10, 22, 18), now: DateTime(2026, 10, 22, 9)), isEmpty);
    });

    test('maxCount counts occurrences already posted', () {
      final spec = monthly(DateTime(2026, 1, 1), maxCount: 3);
      final due = dueOccurrences(spec, nextDue: DateTime(2026, 2, 1), now: DateTime(2026, 12, 31), postedCount: 1);
      expect(due, [DateTime(2026, 2, 1), DateTime(2026, 3, 1)]);
    });

    test('endDate is inclusive by day', () {
      final spec = monthly(DateTime(2026, 1, 15, 10), endDate: DateTime(2026, 3, 15));
      final due = dueOccurrences(spec, nextDue: DateTime(2026, 1, 15, 10), now: DateTime(2026, 12, 31));
      expect(due, hasLength(3));
    });

    test('catch-up is capped so a forgotten daily rule cannot stall the app', () {
      final spec = RecurrenceSpec(frequency: RecurrenceFrequency.daily, start: DateTime(2020, 1, 1));
      expect(dueOccurrences(spec, nextDue: DateTime(2020, 1, 1), now: DateTime(2026, 1, 1)), hasLength(kMaxCatchUp));
    });

    test('advance moves the next due date and ends the rule at its limit', () {
      final spec = monthly(DateTime(2026, 1, 31), maxCount: 2);
      final first = advance(spec, nextDue: DateTime(2026, 1, 31), postedCount: 0, consumed: 1);
      expect(first.nextDue, DateTime(2026, 2, 28));
      expect(first.postedCount, 1);
      final second = advance(spec, nextDue: first.nextDue!, postedCount: first.postedCount, consumed: 1);
      expect(second.nextDue, isNull);
      expect(second.postedCount, 2);
    });

    test('initialNextDue is null when the end date is before the first occurrence', () {
      final spec = monthly(DateTime(2026, 10, 20), day: 5, endDate: DateTime(2026, 10, 31));
      expect(initialNextDue(spec), isNull);
      expect(initialNextDue(monthly(DateTime(2026, 10, 20), day: 5)), DateTime(2026, 11, 5));
    });

    test('occurrencesBefore lists the upcoming window', () {
      final spec = RecurrenceSpec(frequency: RecurrenceFrequency.weekly, start: DateTime(2026, 10, 22));
      expect(occurrencesBefore(spec, nextDue: DateTime(2026, 10, 22), until: DateTime(2026, 11, 6)), hasLength(3));
    });
  });
}

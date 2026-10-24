import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/cards/card_cycle.dart';

void main() {
  group('daysInMonth', () {
    test('handles 30/31-day months and leap Februaries', () {
      expect(daysInMonth(2026, 1), 31);
      expect(daysInMonth(2026, 4), 30);
      expect(daysInMonth(2026, 2), 28);
      expect(daysInMonth(2028, 2), 29);
      expect(daysInMonth(2100, 2), 28, reason: 'century years are not leap');
      expect(daysInMonth(2000, 2), 29, reason: 'every 400th year is leap');
      expect(daysInMonth(2026, 12), 31);
    });
  });

  group('clampedMonthDay', () {
    test('clamps past the end of a short month', () {
      expect(clampedMonthDay(2026, 2, 31), DateTime(2026, 2, 28));
      expect(clampedMonthDay(2028, 2, 31), DateTime(2028, 2, 29));
      expect(clampedMonthDay(2028, 2, 30), DateTime(2028, 2, 29));
      expect(clampedMonthDay(2026, 4, 31), DateTime(2026, 4, 30));
      expect(clampedMonthDay(2026, 5, 31), DateTime(2026, 5, 31));
    });

    test('rolls month overflow into the next or previous year', () {
      expect(clampedMonthDay(2026, 13, 31), DateTime(2027, 1, 31));
      expect(clampedMonthDay(2026, 0, 31), DateTime(2025, 12, 31));
      expect(clampedMonthDay(2027, 14, 31), DateTime(2028, 2, 29));
    });
  });

  group('calendarDaysBetween', () {
    test('counts calendar days in either direction', () {
      expect(calendarDaysBetween(DateTime(2026, 10, 22, 23, 59), DateTime(2026, 10, 23)), 1);
      expect(calendarDaysBetween(DateTime(2026, 10, 22), DateTime(2026, 10, 22, 18)), 0);
      expect(calendarDaysBetween(DateTime(2026, 11, 1), DateTime(2026, 10, 30)), -2);
      expect(calendarDaysBetween(DateTime(2028, 2, 28), DateTime(2028, 3, 1)), 2);
      expect(calendarDaysBetween(DateTime(2026, 2, 28), DateTime(2026, 3, 1)), 1);
      expect(calendarDaysBetween(DateTime(2026, 12, 31), DateTime(2027, 1, 1)), 1);
    });
  });

  group('statement dates', () {
    test('statement day itself counts as both previous and next', () {
      final today = DateTime(2026, 10, 15);
      expect(previousStatementDate(today, 15), DateTime(2026, 10, 15));
      expect(nextStatementDate(today, 15), DateTime(2026, 10, 15));
    });

    test('mid-cycle finds the dates on either side', () {
      final today = DateTime(2026, 10, 22);
      expect(previousStatementDate(today, 15), DateTime(2026, 10, 15));
      expect(nextStatementDate(today, 15), DateTime(2026, 11, 15));
      expect(previousStatementDate(today, 25), DateTime(2026, 9, 25));
      expect(nextStatementDate(today, 25), DateTime(2026, 10, 25));
    });

    test('statement day 31 lands on each month end', () {
      expect(nextStatementDate(DateTime(2026, 2, 10), 31), DateTime(2026, 2, 28));
      expect(nextStatementDate(DateTime(2028, 2, 10), 31), DateTime(2028, 2, 29));
      expect(nextStatementDate(DateTime(2026, 4, 30), 31), DateTime(2026, 4, 30));
      expect(previousStatementDate(DateTime(2026, 3, 1), 31), DateTime(2026, 2, 28));
      expect(previousStatementDate(DateTime(2026, 5, 15), 31), DateTime(2026, 4, 30));
      expect(previousStatementDate(DateTime(2026, 1, 30), 31), DateTime(2025, 12, 31));
    });

    test('crosses the year boundary', () {
      expect(nextStatementDate(DateTime(2026, 12, 20), 5), DateTime(2027, 1, 5));
      expect(previousStatementDate(DateTime(2027, 1, 3), 5), DateTime(2026, 12, 5));
    });
  });

  group('currentCycle', () {
    test('runs from the day after one statement to the next statement inclusive', () {
      final cycle = currentCycle(DateTime(2026, 10, 22), 15);
      expect(cycle.start, DateTime(2026, 10, 16));
      expect(cycle.end, DateTime(2026, 11, 16));
      expect(cycle.contains(DateTime(2026, 11, 15, 23, 59)), isTrue);
      expect(cycle.contains(DateTime(2026, 10, 15, 23, 59)), isFalse);
    });

    test('statement day belongs to the cycle it closes', () {
      final cycle = currentCycle(DateTime(2026, 10, 15, 12), 15);
      expect(cycle.start, DateTime(2026, 9, 16));
      expect(cycle.end, DateTime(2026, 10, 16));
    });

    test('statement day 31 through February in a common year', () {
      final cycle = currentCycle(DateTime(2026, 2, 14), 31);
      expect(cycle.start, DateTime(2026, 2, 1));
      expect(cycle.end, DateTime(2026, 3, 1));
      final march = currentCycle(DateTime(2026, 3, 1), 31);
      expect(march.start, DateTime(2026, 3, 1));
      expect(march.end, DateTime(2026, 4, 1));
    });

    test('statement day 30 through a leap February', () {
      final cycle = currentCycle(DateTime(2028, 2, 29), 30);
      expect(cycle.start, DateTime(2028, 1, 31));
      expect(cycle.end, DateTime(2028, 3, 1));
      final next = currentCycle(DateTime(2028, 3, 1), 30);
      expect(next.start, DateTime(2028, 3, 1));
      expect(next.end, DateTime(2028, 3, 31));
    });

    test('statement day 29 in a common February closes on the 28th', () {
      final cycle = currentCycle(DateTime(2026, 2, 28), 29);
      expect(cycle.start, DateTime(2026, 1, 30));
      expect(cycle.end, DateTime(2026, 3, 1));
    });

    test('cycles tile the calendar with no gaps or overlaps across a year', () {
      for (final statementDay in [1, 15, 28, 29, 30, 31]) {
        var day = DateTime(2027, 12, 1);
        var cycle = currentCycle(day, statementDay);
        while (day.isBefore(DateTime(2029, 1, 1))) {
          final next = currentCycle(cycle.end, statementDay);
          expect(next.start, cycle.end, reason: 'statement day $statementDay after ${cycle.end}');
          cycle = next;
          day = cycle.end;
        }
      }
    });
  });

  group('dueDateForStatement', () {
    test('due day after the statement day is the same month', () {
      expect(dueDateForStatement(DateTime(2026, 10, 5), 25), DateTime(2026, 10, 25));
    });

    test('due day on or before the statement day is next month', () {
      expect(dueDateForStatement(DateTime(2026, 10, 15), 3), DateTime(2026, 11, 3));
      expect(dueDateForStatement(DateTime(2026, 10, 15), 15), DateTime(2026, 11, 15));
    });

    test('due day 31 clamps in the due month', () {
      expect(dueDateForStatement(DateTime(2026, 1, 31), 31), DateTime(2026, 2, 28));
      expect(dueDateForStatement(DateTime(2028, 1, 31), 31), DateTime(2028, 2, 29));
      expect(dueDateForStatement(DateTime(2026, 4, 10), 31), DateTime(2026, 4, 30));
    });

    test('a statement clamped to 28 Feb with due day 30 is due on 30 Mar, not 28 Feb', () {
      // Statement day 31 in February lands on the 28th; due day 30 > 28 but
      // February has no 30th, so the clamped same-month date is the statement
      // day itself and must roll to March.
      expect(dueDateForStatement(DateTime(2026, 2, 28), 30), DateTime(2026, 3, 30));
    });

    test('December statement is due in January', () {
      expect(dueDateForStatement(DateTime(2026, 12, 20), 8), DateTime(2027, 1, 8));
    });
  });

  group('upcomingDueDate', () {
    test('the billed statement is still due', () {
      expect(upcomingDueDate(DateTime(2026, 10, 22), statementDay: 15, dueDay: 3), DateTime(2026, 11, 3));
    });

    test('due today is still upcoming', () {
      expect(upcomingDueDate(DateTime(2026, 11, 3), statementDay: 15, dueDay: 3), DateTime(2026, 11, 3));
    });

    test('after the due date moves to the next bill', () {
      expect(upcomingDueDate(DateTime(2026, 11, 4), statementDay: 15, dueDay: 3), DateTime(2026, 12, 3));
    });

    test('same-month due day', () {
      expect(upcomingDueDate(DateTime(2026, 10, 3), statementDay: 5, dueDay: 25), DateTime(2026, 10, 25));
      expect(upcomingDueDate(DateTime(2026, 10, 26), statementDay: 5, dueDay: 25), DateTime(2026, 11, 25));
    });

    test('statement 31 / due 20 through a leap February', () {
      expect(upcomingDueDate(DateTime(2028, 2, 29), statementDay: 31, dueDay: 20), DateTime(2028, 3, 20));
      expect(upcomingDueDate(DateTime(2028, 2, 21), statementDay: 31, dueDay: 20), DateTime(2028, 3, 20));
      expect(upcomingDueDate(DateTime(2028, 2, 20), statementDay: 31, dueDay: 20), DateTime(2028, 2, 20));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/domain/budget/safe_to_spend.dart';

void main() {
  final october = monthRange(DateTime(2026, 10, 15));
  final salaryMonth = monthRange(DateTime(2026, 10, 24), startDay: 25); // 25 Sep to 24 Oct

  test('remaining budget spread over the days left, today included', () {
    final safe = safeToSpend(limitMinor: 3000000, spentMinor: 1400000, cycle: october, now: DateTime(2026, 10, 24, 9))!;
    expect(safe.daysLeft, 8); // 24th to 31st
    expect(safe.perDayMinor, 200000);
    expect(safe.isOver, isFalse);
    expect(safe.overByMinor, 0);
  });

  test('rounds down so the daily figure never overshoots the budget', () {
    final safe = safeToSpend(limitMinor: 1000, spentMinor: 0, cycle: october, now: DateTime(2026, 10, 29))!;
    expect(safe.daysLeft, 3);
    expect(safe.perDayMinor, 333);
  });

  test('cycle edges: first and last day of a month starting on the 1st', () {
    final first = safeToSpend(limitMinor: 3100000, spentMinor: 0, cycle: october, now: DateTime(2026, 10, 1))!;
    expect(first.daysLeft, 31);
    expect(first.perDayMinor, 100000);
    final last = safeToSpend(limitMinor: 3100000, spentMinor: 3000000, cycle: october, now: DateTime(2026, 10, 31, 23, 59))!;
    expect(last.daysLeft, 1);
    expect(last.perDayMinor, 100000);
  });

  test('respects the month-start day: 25th to 24th cycle', () {
    expect(salaryMonth.start, DateTime(2026, 9, 25));
    final lastDay = safeToSpend(limitMinor: 500000, spentMinor: 400000, cycle: salaryMonth, now: DateTime(2026, 10, 24, 20))!;
    expect(lastDay.daysLeft, 1);
    expect(lastDay.perDayMinor, 100000);
    final firstDay = safeToSpend(limitMinor: 600000, spentMinor: 0, cycle: salaryMonth, now: DateTime(2026, 9, 25))!;
    expect(firstDay.daysLeft, 30);
    expect(firstDay.perDayMinor, 20000);
    // The 25th belongs to the next cycle, so this one no longer applies.
    expect(safeToSpend(limitMinor: 500000, spentMinor: 0, cycle: salaryMonth, now: DateTime(2026, 10, 25)), isNull);
  });

  test('overspent shows zero per day and how far over', () {
    final safe = safeToSpend(limitMinor: 1000000, spentMinor: 1250000, cycle: october, now: DateTime(2026, 10, 20))!;
    expect(safe.perDayMinor, 0);
    expect(safe.isOver, isTrue);
    expect(safe.overByMinor, 250000);
  });

  test('exactly on budget is zero per day but not over', () {
    final safe = safeToSpend(limitMinor: 1000000, spentMinor: 1000000, cycle: october, now: DateTime(2026, 10, 20))!;
    expect(safe.perDayMinor, 0);
    expect(safe.isOver, isFalse);
  });

  test('no monthly budget hides the line', () {
    expect(safeToSpend(limitMinor: null, spentMinor: 5000, cycle: october, now: DateTime(2026, 10, 20)), isNull);
  });

  test('a past month on Home hides the line', () {
    expect(safeToSpend(limitMinor: 1000000, spentMinor: 0, cycle: october, now: DateTime(2026, 11, 3)), isNull);
  });
}

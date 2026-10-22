import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/domain/ledger/personal_totals.dart';
import 'package:hisab/domain/stats/spend_series.dart';

LedgerLine _expense(DateTime at, int minor, {String? category}) => LedgerLine(kind: 'expense', amountMinor: minor, occurredAt: at, categoryId: category);
LedgerLine _income(DateTime at, int minor) => LedgerLine(kind: 'income', amountMinor: minor, occurredAt: at);

void main() {
  final october = DateRange(DateTime(2026, 10, 1), DateTime(2026, 11, 1));
  final september = DateRange(DateTime(2026, 9, 1), DateTime(2026, 10, 1));

  group('month progress', () {
    test('counts days and elapsed days, with today in progress', () {
      expect(daysInRange(october), 31);
      expect(daysInRange(september), 30);
      expect(daysElapsedInRange(october, DateTime(2026, 10, 21, 18)), 21);
      expect(daysElapsedInRange(october, DateTime(2026, 10, 1, 0, 5)), 1);
      expect(daysElapsedInRange(october, DateTime(2026, 9, 30)), 0);
      expect(daysElapsedInRange(october, DateTime(2026, 12, 25)), 31);
    });

    test('daily average divides by elapsed days and never by zero', () {
      expect(dailyAverage(expenseMinor: 2894000, daysElapsed: 21), 137809);
      expect(dailyAverage(expenseMinor: 5000, daysElapsed: 0), 5000);
    });
  });

  group('cumulative daily series', () {
    test('runs a monotonic total with flat days in between', () {
      final series = cumulativeByDay(
        expenseByDay: {DateTime(2026, 10, 1): 100, DateTime(2026, 10, 3): 250, DateTime(2026, 10, 3, 9): 50, DateTime(2026, 11, 2): 999},
        range: october,
        days: 5,
      );
      expect(series, [100, 100, 400, 400, 400]);
    });

    test('ignores spend outside the range', () {
      final series = cumulativeByDay(expenseByDay: {DateTime(2026, 9, 30): 700}, range: october, days: 3);
      expect(series, [0, 0, 0]);
    });
  });

  group('last-month alignment', () {
    test('a shorter month holds its final total flat', () {
      expect(alignSeries([10, 20, 30], 5), [10, 20, 30, 30, 30]);
    });
    test('a longer month is cut to the current month length', () {
      expect(alignSeries([10, 20, 30, 40, 50], 3), [10, 20, 30]);
    });
    test('empty input pads with zeros', () {
      expect(alignSeries(const [], 2), [0, 0]);
      expect(alignSeries([5], 0), isEmpty);
    });
  });

  group('comparison', () {
    test('percent change rounds and hides when there is no previous month', () {
      expect(percentChange(current: 1120, previous: 1000), 12);
      expect(percentChange(current: 800, previous: 1000), -20);
      expect(percentChange(current: 1000, previous: 1000), 0);
      expect(percentChange(current: 500, previous: 0), isNull);
    });
  });

  group('trailing months', () {
    test('six ranges end with the current month and honour the start day', () {
      final current = monthRange(DateTime(2026, 10, 21), startDay: 25);
      final ranges = trailingMonthRanges(current, count: 6, startDay: 25);
      expect(ranges.length, 6);
      expect(ranges.last.start, DateTime(2026, 9, 25));
      expect(ranges.first.start, DateTime(2026, 4, 25));
      expect(ranges[4].end, ranges[5].start);
      expect(previousMonthRange(october, startDay: 1).start, september.start);
      expect(previousMonthRange(october, startDay: 1).end, september.end);
    });

    test('totals are bucketed per range by kind', () {
      final totals = totalsByRange([
        _expense(DateTime(2026, 9, 10), 300),
        _income(DateTime(2026, 9, 1), 1000),
        _expense(DateTime(2026, 10, 2), 50),
        _expense(DateTime(2026, 8, 2), 999),
      ], [september, october]);
      expect(totals.map((t) => t.expense), [300, 50]);
      expect(totals.map((t) => t.income), [1000, 0]);
    });
  });

  test('day axis labels step by a week and clamp to the month', () {
    expect(dayAxisLabels(31), [1, 8, 15, 22, 29]);
    expect(dayAxisLabels(28), [1, 8, 15, 22]);
  });
}

/// Data behind the spending trend card: this month's cumulative daily spend,
/// last month's curve aligned to the same day count, and six monthly totals.
library;

import '../../core/dates.dart';
import '../ledger/personal_totals.dart';
import 'spend_series.dart';

/// Below this many expenses in the window the trend card is not shown.
const int kTrendMinimumExpenses = 3;

class TrendData {
  const TrendData({
    required this.current,
    required this.previous,
    required this.daysInMonth,
    required this.daysElapsed,
    required this.months,
    required this.expenseCount,
  });

  /// Cumulative spend for each elapsed day of the selected month.
  final List<int> current;

  /// Last month's cumulative spend aligned to [daysInMonth] points.
  final List<int> previous;
  final int daysInMonth;
  final int daysElapsed;

  /// Trailing months, oldest first; the last one is the selected month.
  final List<PeriodTotal> months;
  final int expenseCount;

  bool get hasEnoughData => expenseCount >= kTrendMinimumExpenses;
  bool get hasPrevious => previous.isNotEmpty && previous.last > 0;
  int get currentTotal => current.isEmpty ? 0 : current.last;
  int get maxValue {
    return [...current, ...previous].fold(0, (maximum, value) => value > maximum ? value : maximum);
  }
}

TrendData buildTrend({
  required Iterable<LedgerLine> lines,
  required List<DateRange> monthRanges,
  required DateTime now,
}) {
  final range = monthRanges.last;
  final previousRange = monthRanges.length > 1 ? monthRanges[monthRanges.length - 2] : null;
  final days = daysInRange(range);
  final elapsed = daysElapsedInRange(range, now);
  final currentLines = linesWithin(lines, range);
  final currentSeries = cumulativeByDay(expenseByDay: expenseByDay(currentLines), range: range, days: days);
  final previousSeries = previousRange == null
      ? const <int>[]
      : alignSeries(cumulativeByDay(expenseByDay: expenseByDay(linesWithin(lines, previousRange)), range: previousRange, days: daysInRange(previousRange)), days);
  return TrendData(
    current: currentSeries.sublist(0, elapsed),
    previous: previousSeries,
    daysInMonth: days,
    daysElapsed: elapsed,
    months: totalsByRange(lines, monthRanges),
    expenseCount: lines.where((line) => line.kind == 'expense').length,
  );
}

/// What the Home-screen widget shows: this month's spend against last
/// month's, worked out the way the dashboard hero does. Pure.
library;

import '../../core/dates.dart';
import '../ledger/personal_totals.dart';
import '../stats/month_summary.dart';
import '../stats/spend_series.dart';

class SpendWidgetFigures {
  const SpendWidgetFigures({required this.range, required this.previousRange, required this.summary});

  /// The month containing "now", honouring the custom month start day.
  final DateRange range;
  final DateRange previousRange;
  final MonthSummary summary;

  int get spentMinor => summary.expense;
  int get previousSpentMinor => summary.previousExpense;

  /// Change against last month; null when last month had no spend.
  int? get percentVsPrevious => summary.percentVsPrevious;
}

/// The two months the widget compares, previous first: the window
/// [spendWidgetFigures] needs lines for.
List<DateRange> spendWidgetRanges(DateTime now, {required int monthStartDay}) =>
    trailingMonthRanges(monthRange(now, startDay: monthStartDay), count: 2, startDay: monthStartDay);

/// This month's and last month's spend from my ledger [lines] (lines outside
/// the two months are ignored).
SpendWidgetFigures spendWidgetFigures({required Iterable<LedgerLine> lines, required DateTime now, required int monthStartDay}) {
  final ranges = spendWidgetRanges(now, monthStartDay: monthStartDay);
  final previousRange = ranges.first;
  final range = ranges.last;
  return SpendWidgetFigures(
    range: range,
    previousRange: previousRange,
    summary: summariseMonth(current: linesWithin(lines, range), previous: linesWithin(lines, previousRange), range: range, now: now),
  );
}

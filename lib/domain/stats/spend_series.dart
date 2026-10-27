/// Pure spending statistics behind the dashboard charts: cumulative daily
/// series, last-month alignment, trailing month buckets and comparisons.
/// Widgets only render what these functions return.
library;

import 'dart:math';

import '../../core/dates.dart';
import '../../core/money.dart';
import '../ledger/personal_totals.dart';

/// Whole days a range spans.
int daysInRange(DateRange range) => range.end.difference(range.start).inDays;

/// Days of [range] that have started by [now]: 0 before the range, the full
/// length after it, otherwise today counts as a day in progress.
int daysElapsedInRange(DateRange range, DateTime now) {
  if (now.isBefore(range.start)) return 0;
  final elapsed = startOfDay(now).difference(startOfDay(range.start)).inDays + 1;
  return min(elapsed, daysInRange(range));
}

/// Running total of expense per day of [range], one value per day in
/// `0..<days`. Days without spend repeat the previous total, so the series
/// is monotonic and can be drawn as a line.
List<int> cumulativeByDay({required Map<DateTime, int> expenseByDay, required DateRange range, required int days}) {
  final perDay = List<int>.filled(max(days, 0), 0);
  for (final entry in expenseByDay.entries) {
    final index = startOfDay(entry.key).difference(startOfDay(range.start)).inDays;
    if (index >= 0 && index < perDay.length) perDay[index] += entry.value;
  }
  var running = 0;
  return [for (final amount in perDay) running += amount];
}

/// Fits a cumulative series to [length] points so two months of different
/// length overlay: a shorter month holds its final total flat, a longer one
/// is cut at [length] days.
List<int> alignSeries(List<int> series, int length) {
  if (length <= 0) return const [];
  if (series.length >= length) return series.sublist(0, length);
  final last = series.isEmpty ? 0 : series.last;
  return [...series, ...List<int>.filled(length - series.length, last)];
}

/// Whole-percent change from [previous] to [current]; null when there is no
/// previous figure to compare against.
int? percentChange({required int current, required int previous}) {
  if (previous <= 0) return null;
  return ((current - previous) * 100 / previous).round();
}

/// Average spend per elapsed day; a month that has not started averages over one day.
int dailyAverage({required int expenseMinor, required int daysElapsed}) => expenseMinor ~/ max(daysElapsed, 1);

/// The [count] month ranges ending with [current], oldest first, each
/// honouring the custom month start day.
List<DateRange> trailingMonthRanges(DateRange current, {required int count, required int startDay}) {
  final ranges = <DateRange>[current];
  while (ranges.length < count) {
    ranges.insert(0, previousMonthRange(ranges.first, startDay: startDay));
  }
  return ranges;
}

/// The month range immediately before [range] with the same start day.
DateRange previousMonthRange(DateRange range, {required int startDay}) =>
    monthRange(range.start.subtract(const Duration(days: 1)), startDay: startDay);

class PeriodTotal {
  const PeriodTotal({required this.range, required this.expense, required this.income});
  final DateRange range;
  final int expense;
  final int income;
}

/// Expense and income totals per range, in the order of [ranges]. Lines
/// outside every range are ignored; ranges must not overlap.
List<PeriodTotal> totalsByRange(Iterable<LedgerLine> lines, List<DateRange> ranges) {
  final expense = List<int>.filled(ranges.length, 0);
  final income = List<int>.filled(ranges.length, 0);
  for (final line in lines) {
    final index = ranges.indexWhere((range) => range.contains(line.occurredAt));
    if (index < 0) continue;
    if (line.kind == 'expense') expense[index] += line.amountMinor;
    if (line.kind == 'income') income[index] += line.amountMinor;
  }
  return [for (var i = 0; i < ranges.length; i++) PeriodTotal(range: ranges[i], expense: expense[i], income: income[i])];
}

/// Lines that fall inside [range].
List<LedgerLine> linesWithin(Iterable<LedgerLine> lines, DateRange range) => [for (final line in lines) if (range.contains(line.occurredAt)) line];

/// Evenly spaced x-axis day labels for a month: 1, 8, 15, 22, 29 (clamped to the month length).
List<int> dayAxisLabels(int days, {int step = 7}) => [for (var day = 1; day <= days; day += step) day];

/// Smallest "round" value (1, 2 or 5 times a power of ten) at or above
/// [value], so a chart's top gridline lands on a readable number.
double niceCeiling(double value) {
  if (value <= 0) return 1;
  final magnitude = pow(10, (log(value) / ln10).floor()).toDouble();
  final normalised = value / magnitude;
  final step = normalised <= 1 ? 1 : normalised <= 2 ? 2 : normalised <= 5 ? 5 : 10;
  return step * magnitude;
}

/// Short axis label for an amount in whole units: 1,00,000 -> "1L",
/// 50,000 -> "50K", 2,500 -> "2.5K", 800 -> "800" (K / M / B and the
/// format's decimal separator for Western formats). Trailing ".0" is dropped
/// so gridline labels stay narrow enough for a 40dp axis column. [symbol],
/// when given, replaces the format's symbol; with neither there is none.
String axisAmountLabel(double amount, {MoneyFormat? format, String? symbol}) {
  final style = format ?? MoneyFormat.inr;
  String trimmed(double value) {
    final text = value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
    final short = text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
    return short.replaceAll('.', style.decimalSeparator);
  }

  final abs = amount.abs();
  final (divisor, suffix) = compactUnit(abs, style.grouping);
  return withCurrencySymbol('${trimmed(abs / divisor)}$suffix', symbol: symbol ?? format?.symbol ?? '', negative: amount < 0, after: style.symbolAfter);
}

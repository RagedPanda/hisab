/// What the hero card shows for a month, derived from ledger lines. Pure.
library;

import '../../core/dates.dart';
import '../budget/budget_math.dart';
import '../ledger/personal_totals.dart';
import 'spend_series.dart';

class MonthSummary {
  const MonthSummary({
    required this.expense,
    required this.income,
    required this.previousExpense,
    required this.daysElapsed,
    required this.daysInMonth,
    required this.elapsedFraction,
  });
  final int expense;
  final int income;
  final int previousExpense;
  final int daysElapsed;
  final int daysInMonth;
  final double elapsedFraction;

  int get net => income - expense;
  bool get isEmpty => expense == 0 && income == 0;

  /// Change against last month; null hides the comparison pill.
  int? get percentVsPrevious => percentChange(current: expense, previous: previousExpense);
  int get dailyAverageMinor => dailyAverage(expenseMinor: expense, daysElapsed: daysElapsed);
}

MonthSummary summariseMonth({
  required Iterable<LedgerLine> current,
  required Iterable<LedgerLine> previous,
  required DateRange range,
  required DateTime now,
}) {
  final totals = totalsByKind(current);
  return MonthSummary(
    expense: totals.expense,
    income: totals.income,
    previousExpense: totalsByKind(previous).expense,
    daysElapsed: daysElapsedInRange(range, now),
    daysInMonth: daysInRange(range),
    elapsedFraction: elapsedFraction(start: range.start, end: range.end, now: now),
  );
}

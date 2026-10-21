/// Budget progress arithmetic. Pure.
library;

enum BudgetPeriod { weekly, monthly, yearly }

class BudgetProgress {
  const BudgetProgress({
    required this.limitMinor,
    required this.spentMinor,
    required this.elapsedFraction,
  });

  final int limitMinor;
  final int spentMinor;

  /// How far through the period we are, 0..1.
  final double elapsedFraction;

  int get remainingMinor => limitMinor - spentMinor;
  double get usedFraction => limitMinor == 0 ? 0 : spentMinor / limitMinor;
  bool get isOver => spentMinor > limitMinor;

  /// Straight-line projection of spend at period end.
  int get projectedMinor =>
      elapsedFraction <= 0 ? spentMinor : (spentMinor / elapsedFraction).round();

  /// Spending faster than the calendar: used% > elapsed% by a margin.
  bool get isAheadOfPace => usedFraction > elapsedFraction + 0.05;
}

double elapsedFraction({
  required DateTime start,
  required DateTime end,
  required DateTime now,
}) {
  final total = end.difference(start).inMinutes;
  if (total <= 0) return 1;
  final elapsed = now.difference(start).inMinutes;
  return (elapsed / total).clamp(0, 1).toDouble();
}

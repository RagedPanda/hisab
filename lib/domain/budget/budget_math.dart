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

  /// Whole-percent usage for display, never negative.
  int get usedPercent => (usedFraction * 100).round().clamp(0, 999);

  /// Semantic state of the budget, independent of the category colour (P2-13).
  BudgetBand get band {
    if (isOver) return BudgetBand.over;
    if (usedFraction >= kBudgetNearLimitFraction) return BudgetBand.nearLimit;
    return BudgetBand.onTrack;
  }
}

/// From this share of the limit a budget is shown as "near its limit".
const double kBudgetNearLimitFraction = 0.75;

enum BudgetBand { onTrack, nearLimit, over }

/// Whole days remaining in a period that ends at [end] (exclusive), counting
/// today as a full day. Never negative.
int daysLeftInPeriod({required DateTime end, required DateTime now}) {
  final today = DateTime(now.year, now.month, now.day);
  final endDay = DateTime(end.year, end.month, end.day);
  final days = endDay.difference(today).inDays;
  return days < 0 ? 0 : days;
}

/// Spend charged against a budget: the category plus its subcategories, or the
/// whole month for an overall budget (null category).
int spentForBudget({
  required String? categoryId,
  required Map<String, int> expenseByCategory,
  required int monthExpenseMinor,
  required Iterable<String> childCategoryIds,
}) {
  if (categoryId == null) return monthExpenseMinor;
  return childCategoryIds.fold(expenseByCategory[categoryId] ?? 0, (sum, id) => sum + (expenseByCategory[id] ?? 0));
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

/// Order for a budgets overview: the overall budget first, then by limit
/// descending; at most [max] rows with the rest counted for an "N more" link.
({List<T> shown, int more}) budgetOverviewRows<T>(List<T> budgets, {required bool Function(T) isOverall, required int Function(T) limitOf, int max = 4}) {
  final sorted = [...budgets]..sort((a, b) {
      final overall = (isOverall(b) ? 1 : 0) - (isOverall(a) ? 1 : 0);
      return overall != 0 ? overall : limitOf(b).compareTo(limitOf(a));
    });
  return (shown: sorted.take(max).toList(), more: sorted.length > max ? sorted.length - max : 0);
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../domain/budget/budget_math.dart';

/// A budget joined with its category and this month's progress; shared by the
/// dashboard overview and the Budgets screen so both show the same numbers.
class BudgetView {
  const BudgetView({required this.budget, required this.category, required this.progress, required this.daysLeft});
  final Budget budget;
  final Category? category;
  final BudgetProgress progress;
  final int daysLeft;

  bool get isOverall => budget.categoryId == null;
}

/// Monthly budgets with their progress over [range]. Pure, so the dashboard
/// and the Budgets screen can feed it from different streams.
List<BudgetView> buildBudgetViews({
  required List<Budget> budgets,
  required List<Category> categories,
  required Map<String, int> expenseByCategory,
  required int monthExpenseMinor,
  required DateRange range,
  required DateTime now,
}) {
  final byId = {for (final category in categories) category.id: category};
  final elapsed = elapsedFraction(start: range.start, end: range.end, now: now);
  final daysLeft = daysLeftInPeriod(end: range.end, now: now);
  return [
    for (final budget in budgets.where((b) => b.period == 'month'))
      BudgetView(
        budget: budget,
        category: byId[budget.categoryId],
        progress: BudgetProgress(
          limitMinor: budget.amountMinor,
          spentMinor: spentForBudget(
            categoryId: budget.categoryId,
            expenseByCategory: expenseByCategory,
            monthExpenseMinor: monthExpenseMinor,
            childCategoryIds: categories.where((c) => c.parentId == budget.categoryId).map((c) => c.id),
          ),
          elapsedFraction: elapsed,
        ),
        daysLeft: daysLeft,
      ),
  ];
}

final budgetViewsProvider = Provider<List<BudgetView>>((ref) => buildBudgetViews(
      budgets: ref.watch(budgetsProvider).value ?? const <Budget>[],
      categories: ref.watch(allCategoriesProvider).value ?? const <Category>[],
      expenseByCategory: ref.watch(monthCategoryTotalsProvider).value ?? const <String, int>{},
      monthExpenseMinor: ref.watch(monthTotalsProvider).value?.expense ?? 0,
      range: ref.watch(selectedRangeProvider),
      now: DateTime.now(),
    ));

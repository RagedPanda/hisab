import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

final budgetViewsProvider = Provider<List<BudgetView>>((ref) {
  final budgets = ref.watch(budgetsProvider).value ?? const <Budget>[];
  final totals = ref.watch(monthCategoryTotalsProvider).value ?? const <String, int>{};
  final monthExpense = ref.watch(monthTotalsProvider).value?.expense ?? 0;
  final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
  final range = ref.watch(selectedRangeProvider);
  final now = DateTime.now();
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
            expenseByCategory: totals,
            monthExpenseMinor: monthExpense,
            childCategoryIds: categories.where((c) => c.parentId == budget.categoryId).map((c) => c.id),
          ),
          elapsedFraction: elapsed,
        ),
        daysLeft: daysLeft,
      ),
  ];
});

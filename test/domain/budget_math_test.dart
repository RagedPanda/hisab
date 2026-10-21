import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/budget/budget_math.dart';

void main() {
  group('budget band (P2-13)', () {
    BudgetProgress progress(int spent) => BudgetProgress(limitMinor: 100000, spentMinor: spent, elapsedFraction: 0.5);
    test('colour band follows the used ratio, not the category', () {
      expect(progress(63000).band, BudgetBand.onTrack);
      expect(progress(75000).band, BudgetBand.nearLimit);
      expect(progress(100000).band, BudgetBand.nearLimit);
      expect(progress(100001).band, BudgetBand.over);
    });
    test('used percent rounds and clamps', () {
      expect(progress(63400).usedPercent, 63);
      expect(progress(250000).usedPercent, 250);
      expect(const BudgetProgress(limitMinor: 0, spentMinor: 10, elapsedFraction: 0).usedPercent, 0);
    });
  });

  group('days left', () {
    test('counts whole days up to the exclusive period end', () {
      expect(daysLeftInPeriod(end: DateTime(2026, 11, 1), now: DateTime(2026, 10, 21, 18, 30)), 11);
      expect(daysLeftInPeriod(end: DateTime(2026, 11, 1), now: DateTime(2026, 10, 31, 23)), 1);
      expect(daysLeftInPeriod(end: DateTime(2026, 10, 1), now: DateTime(2026, 10, 21)), 0);
    });
  });

  group('spent for budget', () {
    const totals = {'food': 10000, 'groceries': 5000, 'fuel': 2000};
    test('category budget includes its subcategories', () {
      expect(spentForBudget(categoryId: 'food', expenseByCategory: totals, monthExpenseMinor: 17000, childCategoryIds: ['groceries']), 15000);
    });
    test('overall budget uses the month total', () {
      expect(spentForBudget(categoryId: null, expenseByCategory: totals, monthExpenseMinor: 17000, childCategoryIds: const []), 17000);
    });
  });
}

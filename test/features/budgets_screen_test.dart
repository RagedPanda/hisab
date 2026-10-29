import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/budgets/budget_views.dart';

import '../support/app_harness.dart' show enter, settle;
import '../support/screen_harness.dart';
import '../support/app_harness.dart' show createContainer;

/// Live budgets, as the screen sees them.
Future<List<Budget>> _liveBudgets(WidgetTester tester, ProviderContainer container) async =>
    (await tester.runAsync(() => container.read(databaseProvider).select(container.read(databaseProvider).budgets).get()))!.where((budget) => budget.deletedAt == null).toList();

/// Types [amount] into the open amount dialog and saves it.
Future<void> _saveAmount(WidgetTester tester, String amount) async {
  await enter(tester, find.byType(TextField).last, amount);
  await tapAndSettle(tester, find.text('Save'));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('an overall budget is set from the empty state, edited, removed and restored', (tester) async {
    final container = await createContainer();
    await pumpAt(tester, container, '/budgets');
    expect(find.text('No budgets yet'), findsOneWidget);

    await tapAndSettle(tester, find.text('Set a budget'));
    await tapAndSettle(tester, find.text('Overall monthly budget'));
    expect(find.text('Overall monthly limit'), findsOneWidget);
    await _saveAmount(tester, '20000');
    var budgets = await _liveBudgets(tester, container);
    expect((budgets.single.categoryId, budgets.single.amountMinor, budgets.single.period), (null, 2000000, 'month'));

    await tapAndSettle(tester, find.byTooltip('Edit'));
    await tapAndSettle(tester, find.text('Edit').last);
    await _saveAmount(tester, '25000');
    budgets = await _liveBudgets(tester, container);
    expect(budgets.single.amountMinor, 2500000, reason: 'the same budget is updated');

    await tapAndSettle(tester, find.byTooltip('Edit'));
    await tapAndSettle(tester, find.text('Remove'));
    expect(await _liveBudgets(tester, container), isEmpty);
    expect(find.text('Budget removed'), findsOneWidget);
    await tapAndSettle(tester, find.text('Undo'));
    expect(await _liveBudgets(tester, container), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a category budget picks its category, and tapping the row edits it', (tester) async {
    final container = await createContainer();
    await pumpAt(tester, container, '/budgets');

    await tapAndSettle(tester, find.byType(FloatingActionButton));
    await tapAndSettle(tester, find.text('Budget for a category'));
    await tapAndSettle(tester, find.text('Transport'));
    expect(find.text('Transport monthly limit'), findsOneWidget);
    await _saveAmount(tester, '3000');
    final budget = (await _liveBudgets(tester, container)).single;
    final transport = (await tester.runAsync(() => container.read(categoriesRepositoryProvider).findBySeedKey('transport')))!;
    expect((budget.categoryId, budget.amountMinor), (transport.id, 300000));

    await tapAndSettle(tester, find.text('Transport'));
    expect(find.text('Transport monthly limit'), findsOneWidget);
    await tapAndSettle(tester, find.text('Cancel'));
    expect((await _liveBudgets(tester, container)).single.amountMinor, 300000, reason: 'a cancelled edit changes nothing');
  });

  testWidgets('dismissing the type sheet or the category picker saves nothing', (tester) async {
    final container = await createContainer();
    await pumpAt(tester, container, '/budgets');

    await tapAndSettle(tester, find.byType(FloatingActionButton));
    await tester.tapAt(const Offset(200, 40));
    await settle(tester);
    expect(find.text('Overall monthly budget'), findsNothing);

    await tapAndSettle(tester, find.byType(FloatingActionButton));
    await tapAndSettle(tester, find.text('Budget for a category'));
    await tester.tapAt(const Offset(200, 40));
    await settle(tester);
    expect(await _liveBudgets(tester, container), isEmpty);
  });

  testWidgets('swiping a budget away removes it', (tester) async {
    final container = await createContainer();
    await tester.runAsync(() => container.read(budgetsRepositoryProvider).save(period: 'month', amountMinor: 100000));
    await pumpAt(tester, container, '/budgets');

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await settle(tester);
    expect(await _liveBudgets(tester, container), isEmpty);
    expect(find.text('Budget removed'), findsOneWidget);
  });

  test('budget views keep monthly budgets only and count child categories toward their parent', () {
    final now = DateTime(2026, 10, 15);
    Category category(String id, {String? parentId}) => Category(
          id: id,
          name: id,
          kind: 'expense',
          icon: 'category',
          color: 0,
          parentId: parentId,
          sortOrder: 0,
          isArchived: false,
          units: '',
          updatedAt: now,
        );
    Budget budget(String id, {String? categoryId, String period = 'month'}) => Budget(id: id, categoryId: categoryId, period: period, amountMinor: 10000, updatedAt: now);
    final views = buildBudgetViews(
      budgets: [budget('overall'), budget('food', categoryId: 'food'), budget('weekly', period: 'week')],
      categories: [category('food'), category('lunch', parentId: 'food')],
      expenseByCategory: {'food': 2000, 'lunch': 3000},
      monthExpenseMinor: 9000,
      range: DateRange(DateTime(2026, 10, 1), DateTime(2026, 11, 1)),
      now: now,
    );
    expect([for (final view in views) view.budget.id], ['overall', 'food']);
    expect(views.first.isOverall, isTrue);
    expect(views.first.progress.spentMinor, 9000);
    expect(views.last.category!.id, 'food');
    expect(views.last.progress.spentMinor, 5000);
    expect(views.last.daysLeft, greaterThan(0));
  });
}

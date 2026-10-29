import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/money.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/projects_repository.dart';
import 'package:hisab/domain/budget/budget_math.dart';
import 'package:hisab/domain/projects/project_math.dart';
import 'package:hisab/features/budgets/budget_views.dart';
import 'package:hisab/features/dashboard/dashboard_keys.dart';
import 'package:hisab/features/dashboard/dashboard_providers.dart';
import 'package:hisab/features/dashboard/widgets/budgets_card.dart';
import 'package:hisab/features/dashboard/widgets/projects_card.dart';
import 'package:hisab/features/shell/widgets/budget_row.dart';

import '../support/app_harness.dart';

final _updated = DateTime(2026, 10, 1);

final _food = Category(updatedAt: _updated, id: 'food', name: 'Food', icon: 'restaurant', color: 0xFF4CAF50, kind: 'expense', sortOrder: 0, isArchived: false, units: '');

BudgetView _budget(String id, {Category? category, String? categoryId, required int limit, required int spent, double elapsed = 0.5}) => BudgetView(
      budget: Budget(updatedAt: _updated, id: id, categoryId: categoryId ?? category?.id, period: 'monthly', amountMinor: limit),
      category: category,
      progress: BudgetProgress(limitMinor: limit, spentMinor: spent, elapsedFraction: elapsed),
      daysLeft: 7,
    );

ProjectView _project(String name, {required int spent, int? budget}) => ProjectView(
      project: Project(updatedAt: _updated, id: name, name: name, icon: 'flight', color: 0xFF2196F3, status: 'active', budgetMinor: budget, currency: 'INR', notes: '', createdAt: _updated),
      totals: ProjectTotals(
        spentMinor: spent,
        incomeMinor: 0,
        byCategory: const {},
        byMonth: const {},
        entryCount: 1,
        budget: budget == null ? null : BudgetProgress(limitMinor: budget, spentMinor: spent, elapsedFraction: 1),
      ),
    );

Future<void> _pumpCard(WidgetTester tester, Widget card, List<Override> overrides) async {
  final container = await createContainer(overrides: overrides);
  await pumpScreen(tester, container, Scaffold(body: SingleChildScrollView(child: card)), size: const Size(430, 1200));
  await tester.pumpAndSettle();
}

Future<void> _tapAndExpect(WidgetTester tester, Finder target, String location) async {
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(find.text(openedLocation(location)), findsOneWidget);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('budgets card', () {
    final overview = BudgetsOverview(shown: [
      _budget('overall', limit: 3000000, spent: 1000000),
      _budget('food', category: _food, limit: 1000000, spent: 800000),
      _budget('gone', categoryId: 'deleted', limit: 100000, spent: 150000, elapsed: 1),
    ], more: 2);

    testWidgets('names each budget and says what is left or how far over it is', (tester) async {
      await _pumpCard(tester, const BudgetsCard(), [budgetsOverviewProvider.overrideWithValue(AsyncData(overview))]);
      expect(find.text('Overall'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget, reason: 'a budget whose category is gone');
      expect(find.text('₹20,000 of ₹30,000 left · 7 days'), findsOneWidget);
      expect(find.text('Over ₹1,000 by ₹500'), findsOneWidget);
      for (final percent in ['33%', '80%', '150%']) {
        expect(find.text(percent), findsOneWidget);
      }
      expect(find.text('and 2 more'), findsOneWidget);
    });

    for (final (label, target) in [('Manage', 'Manage'), ('a row', 'Food'), ('and more', 'and 2 more')]) {
      testWidgets('$label opens Budgets', (tester) async {
        await _pumpCard(tester, const BudgetsCard(), [budgetsOverviewProvider.overrideWithValue(AsyncData(overview))]);
        await _tapAndExpect(tester, find.text(target), '/budgets');
      });
    }

    testWidgets('with no budgets the card is hidden', (tester) async {
      await _pumpCard(tester, const BudgetsCard(), [budgetsOverviewProvider.overrideWithValue(const AsyncData(BudgetsOverview(shown: [], more: 0)))]);
      expect(find.byKey(kBudgetsCardKey), findsNothing);
    });

    testWidgets('a row shows its trailing widget and a pace tick only mid-period', (tester) async {
      await _pumpCard(tester, Column(children: [
        BudgetRow(view: _budget('food', category: _food, limit: 1000000, spent: 100000), moneyFormat: MoneyFormat.inr, trailing: const Icon(Icons.chevron_right)),
      ]), const []);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.descendant(of: find.byType(BudgetProgressBar), matching: find.byType(Align)), findsOneWidget);
    });
  });

  group('projects card', () {
    final overview = ProjectsOverview(shown: [_project('Goa trip', spent: 2500000, budget: 5000000), _project('Wedding', spent: 1200000)], more: 3);

    testWidgets('lists each project with its spend, against its budget when it has one', (tester) async {
      await _pumpCard(tester, const ProjectsCard(), [projectsOverviewProvider.overrideWithValue(AsyncData(overview))]);
      expect(find.text('Goa trip'), findsOneWidget);
      expect(find.text('Wedding'), findsOneWidget);
      expect(find.text('₹12,000'), findsOneWidget);
      expect(find.byType(BudgetProgressBar), findsOneWidget, reason: 'only the project with a budget has a bar');
      expect(find.text('and 3 more'), findsOneWidget);
    });

    for (final (label, target) in [('See all', 'See all'), ('the card', 'Wedding'), ('and more', 'and 3 more')]) {
      testWidgets('$label opens Projects', (tester) async {
        await _pumpCard(tester, const ProjectsCard(), [projectsOverviewProvider.overrideWithValue(AsyncData(overview))]);
        await _tapAndExpect(tester, find.text(target), '/projects');
      });
    }

    testWidgets('with no active projects the card is hidden', (tester) async {
      await _pumpCard(tester, const ProjectsCard(), [projectsOverviewProvider.overrideWithValue(const AsyncData(ProjectsOverview(shown: [], more: 0)))]);
      expect(find.byKey(kProjectsCardKey), findsNothing);
    });
  });
}

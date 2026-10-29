import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/features/shell/router.dart';

import '../support/app_harness.dart';
import '../support/seed.dart';

/// The Entries filter sheet and the removable chips it leaves on the list.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final filtersButton = find.byKey(const ValueKey('entries.filters'));
  final applyButton = find.byKey(const ValueKey('filter.apply'));
  final sheet = find.byKey(const ValueKey('filter.sheet'));

  /// Chai Point (₹50, restaurants, cash, #office, in Trip), Landlord (₹20,000, cash), Acme Corp (₹50,000 income).
  Future<({String cashId, String projectId})> pumpEntries(WidgetTester tester) async {
    late final String cashId;
    late final String projectId;
    await pumpApp(tester, seed: (container) async {
      cashId = await cashAccountId(container);
      projectId = await container.read(projectsRepositoryProvider).create(name: 'Trip', icon: 'flight', color: 0xFF1E88E5);
      await seedEntry(container, id: 'chai', payee: 'Chai Point', amountMinor: 5000, categoryId: await seededCategoryId(container, 'restaurants'), accountId: cashId, tags: '#office', projectId: projectId);
      await seedEntry(container, id: 'rent', payee: 'Landlord', amountMinor: 2000000, accountId: cashId);
      await seedEntry(container, id: 'salary', payee: 'Acme Corp', amountMinor: 5000000, kind: 'income', categoryId: await seededCategoryId(container, 'salary'));
    });
    appRouter.go('/transactions');
    await settle(tester);
    return (cashId: cashId, projectId: projectId);
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(filtersButton);
    await settle(tester);
    expect(find.text('Filter entries'), findsOneWidget);
  }

  Future<void> tapInSheet(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(target, 100, scrollable: find.descendant(of: sheet, matching: find.byType(Scrollable)).first);
    await tester.tap(target);
    await settle(tester);
  }

  Future<void> apply(WidgetTester tester) async {
    await tester.tap(applyButton);
    await settle(tester);
  }

  /// Taps the cross of the list chip keyed `entries.filter.<name>`.
  Future<void> deleteFilterChip(WidgetTester tester, String name) async {
    final chip = find.byKey(ValueKey('entries.filter.$name'));
    await revealInChipRow(tester, chip);
    await tester.tap(find.descendant(of: chip, matching: find.byIcon(Icons.close)));
    await settle(tester);
  }

  bool listed(String payee) => find.text(payee).evaluate().isNotEmpty;

  testWidgets('an account and an amount range narrow the list, and each chip removes its own filter', (tester) async {
    final seeded = await pumpEntries(tester);
    await openSheet(tester);

    await tapInSheet(tester, find.byKey(ValueKey('filter.account.${seeded.cashId}')));
    await enter(tester, find.byKey(const ValueKey('filter.minAmount')), '40');
    await enter(tester, find.byKey(const ValueKey('filter.maxAmount')), '100');
    await apply(tester);

    expect(listed('Chai Point'), isTrue);
    expect(listed('Landlord'), isFalse, reason: 'above the max');
    expect(listed('Acme Corp'), isFalse, reason: 'not on Cash');
    expect(find.text('2'), findsOneWidget, reason: 'the filter button badge counts the active filters');
    expect(find.descendant(of: find.byKey(const ValueKey('entries.filter.account')), matching: find.text('Cash')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('entries.filter.amount')), matching: find.text('₹40 – ₹100')), findsOneWidget);

    await deleteFilterChip(tester, 'amount');
    expect(listed('Landlord'), isTrue);
    expect(find.byKey(const ValueKey('entries.filter.amount')), findsNothing);

    await deleteFilterChip(tester, 'account');
    expect(listed('Acme Corp'), isTrue);
  });

  testWidgets('a min above the max blocks Show results until it is fixed', (tester) async {
    await pumpEntries(tester);
    await openSheet(tester);

    await enter(tester, find.byKey(const ValueKey('filter.minAmount')), '500');
    await enter(tester, find.byKey(const ValueKey('filter.maxAmount')), '100');
    expect(find.text('Min is more than max'), findsOneWidget);
    expect(tester.widget<FilledButton>(applyButton).onPressed, isNull);

    await enter(tester, find.byKey(const ValueKey('filter.maxAmount')), '');
    expect(find.text('Min is more than max'), findsNothing);
    await apply(tester);
    expect(find.descendant(of: find.byKey(const ValueKey('entries.filter.amount')), matching: find.text('From ₹500')), findsOneWidget);
    expect(listed('Landlord'), isTrue);
    expect(listed('Chai Point'), isFalse);
  });

  testWidgets('reopening the sheet shows the amounts already set, and an only-max range reads Up to', (tester) async {
    await pumpEntries(tester);
    await openSheet(tester);
    await enter(tester, find.byKey(const ValueKey('filter.maxAmount')), '50.5');
    await apply(tester);
    expect(find.descendant(of: find.byKey(const ValueKey('entries.filter.amount')), matching: find.text('Up to ₹50.50')), findsOneWidget);
    expect(listed('Chai Point'), isTrue);
    expect(listed('Landlord'), isFalse);

    await openSheet(tester);
    expect(tester.widget<TextField>(find.byKey(const ValueKey('filter.maxAmount'))).controller!.text, '50.50');
  });

  testWidgets('a category picked in the sheet can be cleared there or from its chip', (tester) async {
    await pumpEntries(tester);
    await openSheet(tester);

    await tapInSheet(tester, find.byKey(const ValueKey('filter.category')));
    await enter(tester, find.widgetWithText(TextField, 'Search categories'), 'food');
    await settle(tester);
    await tester.tap(find.text('Food & Dining').first);
    await settle(tester);
    final categoryTile = find.byKey(const ValueKey('filter.category'));
    expect(find.descendant(of: categoryTile, matching: find.text('Food & Dining')), findsOneWidget);

    await tester.tap(find.descendant(of: categoryTile, matching: find.byTooltip('Clear')));
    await settle(tester);
    expect(find.descendant(of: categoryTile, matching: find.text('Any category')), findsOneWidget);

    await tapInSheet(tester, categoryTile);
    await enter(tester, find.widgetWithText(TextField, 'Search categories'), 'food');
    await settle(tester);
    await tester.tap(find.text('Food & Dining').first);
    await settle(tester);
    await apply(tester);

    expect(listed('Chai Point'), isTrue, reason: 'restaurants sit under Food & Dining');
    expect(listed('Landlord'), isFalse);
    expect(find.descendant(of: find.byKey(const ValueKey('entries.filter.category')), matching: find.text('Food & Dining')), findsOneWidget);

    await deleteFilterChip(tester, 'category');
    expect(listed('Landlord'), isTrue);
  });

  testWidgets('with the Income chip on, the category picker offers income categories', (tester) async {
    await pumpEntries(tester);
    final incomeChip = find.widgetWithText(ChoiceChip, 'Income');
    await revealInChipRow(tester, incomeChip);
    await tester.tap(incomeChip);
    await settle(tester);
    await openSheet(tester);

    await tapInSheet(tester, find.byKey(const ValueKey('filter.category')));
    await enter(tester, find.widgetWithText(TextField, 'Search categories'), 'food');
    await settle(tester);
    expect(find.text('No matching category'), findsOneWidget, reason: 'food is an expense category');
  });

  testWidgets('a tag chip in the sheet filters by that tag and toggles off again', (tester) async {
    await pumpEntries(tester);
    await openSheet(tester);

    final officeTag = find.byKey(const ValueKey('filter.tag.office'));
    await tapInSheet(tester, officeTag);
    await tapInSheet(tester, officeTag);
    expect(tester.widget<ChoiceChip>(officeTag).selected, isFalse, reason: 'a second tap lets go of the tag');
    await tapInSheet(tester, officeTag);
    await apply(tester);

    expect(listed('Chai Point'), isTrue);
    expect(listed('Landlord'), isFalse);
    expect(find.text('#office'), findsOneWidget);

    await deleteFilterChip(tester, 'tag');
    expect(listed('Landlord'), isTrue);
  });

  testWidgets('a project picked in the sheet shows on the project chip, which can repick or clear it', (tester) async {
    final seeded = await pumpEntries(tester);
    await openSheet(tester);

    final projectTile = find.byKey(const ValueKey('filter.project'));
    await tapInSheet(tester, projectTile);
    await tester.tap(find.byKey(ValueKey('project.option.${seeded.projectId}')));
    await settle(tester);
    expect(find.descendant(of: projectTile, matching: find.text('Trip')), findsOneWidget);

    await tester.tap(find.descendant(of: projectTile, matching: find.byTooltip('Clear')));
    await settle(tester);
    expect(find.descendant(of: projectTile, matching: find.text('Any project')), findsOneWidget);

    await tapInSheet(tester, projectTile);
    await tester.tap(find.byKey(ValueKey('project.option.${seeded.projectId}')));
    await settle(tester);
    await apply(tester);

    final projectChip = find.byKey(const ValueKey('entries.projectFilter'));
    expect(find.descendant(of: projectChip, matching: find.text('Trip')), findsOneWidget);
    expect(listed('Chai Point'), isTrue);
    expect(listed('Landlord'), isFalse);

    await tester.tap(find.descendant(of: projectChip, matching: find.byIcon(Icons.close)));
    await settle(tester);
    expect(find.descendant(of: projectChip, matching: find.text('Project')), findsOneWidget);
    expect(listed('Landlord'), isTrue);
  });

  testWidgets('the project chip on the list picks a project directly, and Any project lifts it', (tester) async {
    final seeded = await pumpEntries(tester);
    final projectChip = find.byKey(const ValueKey('entries.projectFilter'));

    await tester.tap(projectChip);
    await settle(tester);
    await tester.tap(find.byKey(ValueKey('project.option.${seeded.projectId}')));
    await settle(tester);
    expect(listed('Landlord'), isFalse);

    await tester.tap(projectChip);
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('project.none')));
    await settle(tester);
    expect(listed('Landlord'), isTrue);
    expect(find.descendant(of: projectChip, matching: find.text('Project')), findsOneWidget);
  });

  testWidgets('dates picked in the range picker narrow the list and can be cleared', (tester) async {
    await pumpEntries(tester);
    await openSheet(tester);

    await tapInSheet(tester, find.byKey(const ValueKey('filter.dates')));
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Start Date'), '01/01/2025');
    await tester.enterText(find.widgetWithText(TextField, 'End Date'), '01/31/2025');
    await tester.pump();
    await tester.tap(find.text('OK'));
    await settle(tester);

    final datesButton = find.byKey(const ValueKey('filter.dates'));
    expect(find.descendant(of: datesButton, matching: find.text('1 Jan 2025 – 31 Jan 2025')), findsOneWidget);
    await tester.tap(find.descendant(of: find.ancestor(of: datesButton, matching: find.byType(Row)).first, matching: find.byTooltip('Clear')));
    await settle(tester);
    expect(find.descendant(of: datesButton, matching: find.text('Any date')), findsOneWidget);

    await tapInSheet(tester, datesButton);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Start Date'), '01/01/2025');
    await tester.enterText(find.widgetWithText(TextField, 'End Date'), '01/31/2025');
    await tester.tap(find.text('OK'));
    await settle(tester);
    await apply(tester);

    expect(find.text('Nothing here yet'), findsOneWidget, reason: 'every entry is from this month');
    expect(find.byKey(const ValueKey('entries.filter.dates')), findsOneWidget);
    await openSheet(tester);
    await tapInSheet(tester, find.byKey(const ValueKey('filter.dates')));
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await settle(tester);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(find.descendant(of: find.byKey(const ValueKey('filter.dates')), matching: find.text('1 Jan 2025 – 31 Jan 2025')), findsOneWidget, reason: 'cancelling the picker keeps the range');
    await tester.tapAt(const Offset(200, 20));
    await settle(tester);

    await deleteFilterChip(tester, 'dates');
    expect(listed('Landlord'), isTrue);
  });

  testWidgets('Clear all in the sheet empties every field, and dismissing keeps the old filter', (tester) async {
    final seeded = await pumpEntries(tester);
    await openSheet(tester);
    await tapInSheet(tester, find.byKey(ValueKey('filter.account.${seeded.cashId}')));
    await enter(tester, find.byKey(const ValueKey('filter.minAmount')), '40');
    await apply(tester);
    expect(listed('Acme Corp'), isFalse);

    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('filter.clearAll')));
    await settle(tester);
    expect(tester.widget<TextField>(find.byKey(const ValueKey('filter.minAmount'))).controller!.text, isEmpty);
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('filter.account.any'))).selected, isTrue);
    await tapInSheet(tester, find.byKey(ValueKey('filter.account.${seeded.cashId}')));
    await tapInSheet(tester, find.byKey(const ValueKey('filter.account.any')));

    await tester.tapAt(const Offset(200, 20));
    await settle(tester);
    expect(find.text('Filter entries'), findsNothing);
    expect(listed('Acme Corp'), isFalse, reason: 'dismissing the sheet changes nothing');

    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('filter.clearAll')));
    await settle(tester);
    await apply(tester);
    expect(listed('Acme Corp'), isTrue);
    expect(find.byKey(const ValueKey('entries.resultsCount')), findsNothing);
  });
}

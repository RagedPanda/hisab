import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:hisab/features/transactions/transactions_screen.dart';

import '../support/app_harness.dart';
import '../support/seed.dart';

/// The Entries list: search, kind chips, route filters from other screens and
/// the chips they leave behind. Rows are found by payee text only; how a row
/// looks is not asserted here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final resultsCount = find.byKey(const ValueKey('entries.resultsCount'));
  final clearAll = find.byKey(const ValueKey('entries.clearAll'));
  final searchField = find.byKey(const ValueKey('entries.search'));

  /// Chai Point (₹50, food, cash, #office), Landlord (₹20,000, cash), Acme Corp (₹50,000 income).
  Future<void> seedThree(ProviderContainer container) async {
    final cashId = await cashAccountId(container);
    await seedEntry(container, id: 'chai', payee: 'Chai Point', amountMinor: 5000, categoryId: await seededCategoryId(container, 'restaurants'), accountId: cashId, tags: '#office');
    await seedEntry(container, id: 'rent', payee: 'Landlord', amountMinor: 2000000, accountId: cashId);
    await seedEntry(container, id: 'salary', payee: 'Acme Corp', amountMinor: 5000000, kind: 'income');
  }

  Future<ProviderContainer> pumpEntries(WidgetTester tester, {String location = '/transactions'}) async {
    final container = await pumpApp(tester, seed: seedThree);
    appRouter.go(location);
    await settle(tester);
    return container;
  }

  Future<void> tapChip(WidgetTester tester, Finder chip) async {
    await revealInChipRow(tester, chip);
    await tester.tap(chip);
    await settle(tester);
  }

  /// Taps the delete cross of the input chip labelled [label].
  Future<void> deleteChip(WidgetTester tester, String label) async {
    final chip = find.widgetWithText(InputChip, label);
    await revealInChipRow(tester, chip);
    await tester.tap(find.descendant(of: chip, matching: find.byType(Icon)).last);
    await settle(tester);
  }

  String currentLocation() => appRouter.routerDelegate.currentConfiguration.uri.toString();

  testWidgets('every entry of the month is listed until something narrows it', (tester) async {
    await pumpEntries(tester);

    expect(find.text('Chai Point'), findsOneWidget);
    expect(find.text('Landlord'), findsOneWidget);
    expect(find.text('Acme Corp'), findsOneWidget);
    expect(resultsCount, findsNothing, reason: 'no count while nothing narrows the list');
    expect(clearAll, findsNothing);
  });

  testWidgets('search narrows the list and its clear button brings everything back', (tester) async {
    await pumpEntries(tester);

    await enter(tester, searchField, 'chai');
    await settle(tester);
    expect(find.text('Chai Point'), findsOneWidget);
    expect(find.text('Landlord'), findsNothing);
    expect(find.text('1 result'), findsOneWidget);

    await tester.tap(find.descendant(of: searchField, matching: find.byIcon(Icons.clear)));
    await settle(tester);
    expect(find.text('Landlord'), findsOneWidget);
    expect(resultsCount, findsNothing);
  });

  testWidgets('Clear all empties the search box and lifts every filter', (tester) async {
    await pumpEntries(tester);

    await enter(tester, searchField, 'landlord');
    await tapChip(tester, find.widgetWithText(ChoiceChip, 'Expenses'));
    expect(find.text('1 result'), findsOneWidget);

    await tester.tap(clearAll);
    await settle(tester);
    expect(tester.widget<TextField>(searchField).controller!.text, isEmpty, reason: 'the box follows the cleared search');
    expect(find.text('Acme Corp'), findsOneWidget);
    expect(resultsCount, findsNothing);
  });

  testWidgets('kind chips list one kind at a time', (tester) async {
    await pumpEntries(tester);

    await tapChip(tester, find.widgetWithText(ChoiceChip, 'Income'));
    expect(find.text('Acme Corp'), findsOneWidget);
    expect(find.text('Chai Point'), findsNothing);

    await tapChip(tester, find.widgetWithText(ChoiceChip, 'Transfers'));
    expect(find.text('Nothing here yet'), findsOneWidget, reason: 'no transfers were recorded');
    expect(find.text('0 results'), findsOneWidget);

    await tapChip(tester, find.widgetWithText(ChoiceChip, 'All'));
    expect(find.text('Landlord'), findsOneWidget);
  });

  testWidgets('tapping a row opens it in the editor', (tester) async {
    await pumpEntries(tester);

    await tester.tap(find.text('Landlord'));
    await settle(tester);
    expect(find.text('Edit entry'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Landlord'), findsOneWidget, reason: 'the tapped entry is the one loaded');
  });

  group('route filters', () {
    testWidgets('category, account and today chips narrow the list and each cross drops only its own', (tester) async {
      late final String foodId;
      late final String cashId;
      await pumpApp(tester, seed: (container) async {
        foodId = await seededCategoryId(container, 'food');
        cashId = await cashAccountId(container);
        await seedEntry(container, id: 'chai', payee: 'Chai Point', amountMinor: 5000, categoryId: await seededCategoryId(container, 'restaurants'), accountId: cashId);
        await seedEntry(container, id: 'rent', payee: 'Landlord', amountMinor: 2000000, accountId: cashId);
      });
      final today = isoDay(DateTime.now());
      appRouter.go('/transactions?category=$foodId&account=$cashId&day=$today');
      await settle(tester);

      expect(find.widgetWithText(InputChip, 'Food & Dining'), findsOneWidget, reason: 'a parent category also lists its subcategories');
      expect(find.widgetWithText(InputChip, 'Cash'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'Today'), findsOneWidget);
      expect(find.text('Chai Point'), findsOneWidget);
      expect(find.text('Landlord'), findsNothing);
      expect(find.text('1 result'), findsOneWidget);

      await deleteChip(tester, 'Today');
      expect(currentLocation(), '/transactions?category=$foodId&account=$cashId');

      await deleteChip(tester, 'Cash');
      expect(currentLocation(), '/transactions?category=$foodId');

      await deleteChip(tester, 'Food & Dining');
      expect(currentLocation(), '/transactions');
      expect(find.text('Landlord'), findsOneWidget);
    });

    testWidgets('Clear all also leaves the route filters', (tester) async {
      late final String cashId;
      await pumpApp(tester, seed: (container) async {
        await seedThree(container);
        cashId = await cashAccountId(container);
      });
      appRouter.go('/transactions?account=$cashId');
      await settle(tester);
      expect(find.text('Acme Corp'), findsNothing, reason: 'the salary went to no account');

      await tester.tap(clearAll);
      await settle(tester);
      expect(currentLocation(), '/transactions');
      expect(find.text('Acme Corp'), findsOneWidget);
    });

    testWidgets('an empty category id reads Uncategorised and an unknown one reads Category', (tester) async {
      await pumpEntries(tester, location: '/transactions?category=');
      expect(find.widgetWithText(InputChip, 'Uncategorised'), findsOneWidget);
      expect(find.text('Landlord'), findsOneWidget, reason: 'Landlord has no category');
      expect(find.text('Chai Point'), findsNothing);

      appRouter.go('/transactions?category=missing&account=missing');
      await settle(tester);
      expect(find.widgetWithText(InputChip, 'Category'), findsOneWidget);
      expect(find.text('Nothing here yet'), findsOneWidget);
    });

    testWidgets('a past day shows its date and loads that day only', (tester) async {
      final pastDay = DateTime(2025, 3, 14);
      await pumpApp(tester, seed: (container) async {
        await seedEntry(container, id: 'pi', payee: 'Pie Shop', amountMinor: 31400, occurredAt: pastDay.add(const Duration(hours: 9)));
        await seedEntry(container, id: 'now', payee: 'Today Shop', amountMinor: 1000);
      });
      appRouter.go(entriesForDayLocation(pastDay));
      await settle(tester);

      expect(find.widgetWithText(InputChip, '14 Mar 2025 – 14 Mar 2025'), findsOneWidget);
      expect(find.text('Pie Shop'), findsOneWidget);
      expect(find.text('Today Shop'), findsNothing);
      expect(find.text('₹314'), findsWidgets, reason: 'the day header carries the day total of expenses');
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/shell/router.dart';

import 'support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dashboard renders with seeded cash account', (tester) async {
    await pumpApp(tester);
    expect(find.text('Hisab'), findsOneWidget);
    expect(find.text('Spent in ${DateFormat('MMMM').format(DateTime.now())}'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Cash'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Cash'), findsOneWidget);
  });

  testWidgets('multi-item expense is saved and totals update', (tester) async {
    final container = await pumpApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    expect(find.text('New entry'), findsOneWidget);

    await tester.tap(find.text('Uncategorised'));
    await settle(tester);
    await enter(tester, find.widgetWithText(TextField, 'Search categories'), 'milk');
    await settle(tester);
    await tester.tap(find.textContaining('Milk').first);
    await settle(tester);

    // Line items live behind "More details" now; open it first.
    await tester.ensureVisible(find.text('More details'));
    await tester.tap(find.text('More details'));
    await settle(tester);

    await tester.tap(find.text('Add item'));
    await settle(tester);
    await enter(tester, find.widgetWithText(TextField, 'Item name').first, 'Buffalo milk');
    await enter(tester, find.widgetWithText(TextField, 'Qty').first, '1');
    await enter(tester, find.ancestor(of: find.textContaining('Price per').first, matching: find.byType(TextField)).first, '70');

    await tester.tap(find.text('Add item'));
    await settle(tester);
    await enter(tester, find.widgetWithText(TextField, 'Item name').last, 'Cow milk');
    await enter(tester, find.widgetWithText(TextField, 'Qty').last, '0.5');
    await enter(tester, find.ancestor(of: find.textContaining('Price per').last, matching: find.byType(TextField)).first, '60');
    await settle(tester);

    expect(find.textContaining('Save ₹100'), findsOneWidget);
    await tester.ensureVisible(find.textContaining('Save ₹'));
    await tester.tap(find.textContaining('Save ₹'));
    await settle(tester);

    final totals = await tester.runAsync(
      () => container.read(entriesRepositoryProvider).watchTotals(container.read(selectedRangeProvider)).first,
    );
    expect(totals?.expense, 10000);
    final suggestions = await container.read(entriesRepositoryProvider).itemSuggestions(
          (await container.read(categoriesRepositoryProvider).getAll()).firstWhere((c) => c.name.contains('Milk')).id,
        );
    expect(suggestions.map((s) => s.name), containsAll(['Buffalo milk', 'Cow milk']));
    expect(find.textContaining('₹100'), findsWidgets);
  });

  testWidgets('expense saves without a category and persists as uncategorised', (tester) async {
    final container = await pumpApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    expect(find.text('New entry'), findsOneWidget);
    // The category control reads as optional, not as a required field to fill.
    expect(find.text('Uncategorised'), findsOneWidget);
    expect(find.text('Required'), findsNothing);

    // Enter an amount and save straight away, never opening the picker.
    await enter(tester, find.byType(TextField).first, '40');
    await settle(tester);
    await tester.ensureVisible(find.textContaining('Save ₹'));
    await tester.tap(find.textContaining('Save ₹'));
    await settle(tester);

    final db = container.read(databaseProvider);
    await settle(tester, 2);
    final entries = await db.select(db.entries).get();
    expect(entries.single.categoryId, isNull, reason: 'a skipped category persists as null');
    expect(entries.single.amountMinor, 4000);

    // The saved entry shows as Uncategorised in the recent list.
    await tester.scrollUntilVisible(find.text('Uncategorised'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Uncategorised'), findsWidgets);
  });

  testWidgets('group with members is created and opened', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Groups'));
    await settle(tester);
    await tester.tap(find.text('New group'));
    await settle(tester);
    await enter(tester, find.widgetWithText(TextField, 'Group name'), 'Goa trip');
    await enter(tester, find.widgetWithText(TextField, 'Members (comma separated)'), 'Rahul, Priya');
    await tester.tap(find.text('Create group'));
    await settle(tester);
    expect(find.text('Goa trip'), findsWidgets);
    await tester.tap(find.text('Goa trip').first);
    await settle(tester);
    await tester.tap(find.text('Members'));
    await settle(tester);
    expect(find.text('Rahul'), findsOneWidget);
    expect(find.text('Priya'), findsOneWidget);
  });

  testWidgets('dark theme toggle switches brightness', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Settings'));
    await settle(tester);
    await tester.tap(find.text('Dark'));
    await settle(tester);
    final context = tester.element(find.text('Settings').first);
    expect(Theme.of(context).brightness, Brightness.dark);
    await tester.tap(find.text('Light'));
    await settle(tester);
    expect(Theme.of(tester.element(find.text('Settings').first)).brightness, Brightness.light);
  });

  testWidgets('subscription added from a template shows monthly and yearly totals', (tester) async {
    final container = await pumpApp(tester);
    appRouter.push('/subscriptions');
    await settle(tester);
    expect(find.text('No subscriptions yet'), findsOneWidget);

    await tester.tap(find.text('Add subscription'));
    await settle(tester);
    await tester.tap(find.text('JioHotstar'));
    await settle(tester);
    expect(find.text('Every 3 months'), findsOneWidget);
    await enter(tester, find.byKey(const Key('subscriptionPrice')), '299');
    await tester.tap(find.text('Save'));
    await settle(tester);

    final rules = await container.read(databaseProvider).select(container.read(databaseProvider).recurringRules).get();
    expect(rules.single.isSubscription, isTrue);
    expect(rules.single.interval, 3);
    expect(find.text('JioHotstar'), findsOneWidget);
    expect(find.text('₹100'), findsOneWidget);
    expect(find.text('₹1,196'), findsOneWidget);
    expect(find.text('₹100/month'), findsOneWidget);

    await tester.tap(find.text('JioHotstar'));
    await settle(tester);
    await tester.tap(find.text('Pause'));
    await settle(tester);
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('₹0'), findsNWidgets(2));
  });

  group('entry editor accounts', () {
    /// Writes run on the test clock, so pump while they complete.
    Future<T> onTestClock<T>(WidgetTester tester, Future<T> work) async {
      await settle(tester, 2);
      return work;
    }

    Future<void> addBanks(WidgetTester tester, ProviderContainer container) async {
      final db = container.read(databaseProvider);
      await onTestClock(tester, db.into(db.accounts).insert(AccountsCompanion.insert(id: 'hdfc', name: 'HDFC', type: 'bank', color: 1)));
      await onTestClock(tester, db.into(db.accounts).insert(AccountsCompanion.insert(id: 'sbi', name: 'SBI', type: 'bank', color: 3)));
    }

    Finder inPicker(String pickerKey, Finder target) => find.descendant(of: find.byKey(ValueKey(pickerKey)), matching: target);

    Future<void> tapIn(WidgetTester tester, String pickerKey, Finder target) async {
      final finder = inPicker(pickerKey, target);
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await settle(tester, 4);
    }

    Future<List<Entry>> savedEntries(WidgetTester tester, ProviderContainer container) async {
      final db = container.read(databaseProvider);
      return onTestClock(tester, db.select(db.entries).get());
    }

    testWidgets('tapping a type with several accounts still saves with an account (#110)', (tester) async {
      final container = await pumpApp(tester);
      await addBanks(tester, container);
      await tester.tap(find.byType(FloatingActionButton));
      await settle(tester);

      await tester.tap(find.text('Uncategorised'));
      await settle(tester);
      await enter(tester, find.widgetWithText(TextField, 'Search categories'), 'milk');
      await settle(tester);
      await tester.tap(find.textContaining('Milk').first);
      await settle(tester);
      await enter(tester, find.byType(TextField).first, '50');
      await tapIn(tester, 'from-account', find.byKey(const ValueKey('account-type-bank')));

      await tester.ensureVisible(find.textContaining('Save ₹'));
      await tester.tap(find.textContaining('Save ₹'));
      await settle(tester);
      expect((await savedEntries(tester, container)).single.accountId, 'hdfc', reason: 'the bank type picks an account, never none');
    });

    testWidgets('From becoming the To account clears To, and a same-account transfer never saves (#111)', (tester) async {
      final container = await pumpApp(tester);
      await addBanks(tester, container);
      await tester.tap(find.byType(FloatingActionButton));
      await settle(tester);
      await tester.tap(find.text('Transfer'));
      await settle(tester, 4);
      await enter(tester, find.byType(TextField).first, '500');

      await tapIn(tester, 'from-account', find.byKey(const ValueKey('account-type-bank')));
      await tapIn(tester, 'to-account', find.byKey(const ValueKey('account-type-bank')));
      bool toBankSelected() => tester.widget<ChoiceChip>(inPicker('to-account', find.byKey(const ValueKey('account-type-bank')))).selected;
      expect(toBankSelected(), isTrue, reason: 'To is SBI, the only bank left');

      await tapIn(tester, 'from-account', find.text('SBI'));
      expect(inPicker('to-account', find.byKey(const ValueKey('account-type-bank'))), findsOneWidget);
      expect(toBankSelected(), isFalse, reason: 'To no longer shows a bank once From took SBI');

      await tester.ensureVisible(find.textContaining('Save ₹'));
      await tester.tap(find.textContaining('Save ₹'));
      await settle(tester, 4);
      expect(find.text('Pick both accounts for a transfer'), findsOneWidget);
      expect(await savedEntries(tester, container), isEmpty);
    });
  });
}

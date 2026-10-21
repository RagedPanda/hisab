import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the real app on an in-memory database through the main journeys.
Future<ProviderContainer> pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({'onboarded': true});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    databaseProvider.overrideWithValue(db),
  ]);
  addTearDown(container.dispose);
  await tester.binding.setSurfaceSize(const Size(430, 932));
  appRouter.go('/home');
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
  await settle(tester);
  return container;
}

/// Text fields keep the cursor blinking, so pumpAndSettle never settles on
/// screens with an autofocused field. Pump a fixed number of frames instead.
Future<void> settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> enter(WidgetTester tester, Finder field, String text) async {
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

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

    await tester.tap(find.text('Choose category'));
    await settle(tester);
    await enter(tester, find.widgetWithText(TextField, 'Search categories'), 'milk');
    await settle(tester);
    await tester.tap(find.textContaining('Milk').first);
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
}

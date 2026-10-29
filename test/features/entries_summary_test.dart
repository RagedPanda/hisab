import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/fake_notification_gateway.dart';

Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _milk(AppDatabase db, DateTime day, List<(String, double, int)> items) {
  final entryId = newId();
  final rows = [
    for (final (index, (name, quantity, price)) in items.indexed)
      EntryItemsCompanion.insert(
        id: newId(),
        entryId: entryId,
        name: name,
        quantity: Value(quantity),
        unit: const Value('L'),
        unitPriceMinor: price * 100,
        amountMinor: (quantity * price * 100).round(),
        sortOrder: Value(index),
      ),
  ];
  final amount = rows.fold(0, (sum, row) => sum + row.amountMinor.value);
  return EntriesRepository(db).saveEntry(EntriesRepository.newExpense(id: entryId, amountMinor: amount, occurredAt: day, payee: 'Doodhwala'), items: rows);
}

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  testWidgets('searching Entries shows the total and litres of each item', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true, 'currencyCode': 'INR'});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
      notificationGatewayProvider.overrideWithValue(FakeNotificationGateway()),
    ]);
    addTearDown(container.dispose);
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final today = DateTime.now();
    final day = DateTime(today.year, today.month, 1, 7);
    await _milk(db, day, [('Buffalo milk', 1, 75), ('Cow milk', 0.5, 60)]);
    await _milk(db, day.add(const Duration(hours: 1)), [('Buffalo milk', 1.5, 75)]);
    await EntriesRepository(db).saveEntry(EntriesRepository.newExpense(amountMinor: 50000, occurredAt: day, payee: 'Cinema'));

    appRouter.go('/transactions');
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
    await _settle(tester);
    expect(find.byKey(const ValueKey('entries.summary')), findsNothing, reason: 'no summary on the unfiltered list');

    await tester.enterText(find.byType(TextField).first, 'milk');
    await _settle(tester, 4);

    expect(find.byKey(const ValueKey('entries.summary')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const ValueKey('entries.summary.spent'))).data, '₹217.50', reason: 'milk only, not the cinema');
    expect(find.text('2.5 L · 2 times'), findsOneWidget);
    expect(find.text('0.5 L · 1 time'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

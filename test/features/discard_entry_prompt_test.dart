import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/features/shell/router.dart';

import '../support/app_harness.dart';

/// #82: leaving the expense editor with unsaved input asks first.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final discardDialog = find.text('Discard this entry?');
  final editorTitle = find.text('New entry');
  final amountField = find.byType(TextField).first;
  final noteField = find.widgetWithText(TextField, 'Note');

  Future<void> openNewEntry(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    expect(editorTitle, findsOneWidget);
  }

  Future<void> pickMilkCategory(WidgetTester tester) async {
    await tester.tap(find.text('Uncategorised'));
    await settle(tester);
    await enter(tester, find.widgetWithText(TextField, 'Search categories'), 'milk');
    await settle(tester);
    await tester.tap(find.textContaining('Milk').first);
    await settle(tester);
  }

  Future<void> openMoreDetails(WidgetTester tester) async {
    final header = find.text('More details');
    await tester.ensureVisible(header);
    await tester.tap(header);
    await settle(tester);
  }

  Future<void> systemBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await settle(tester);
  }

  Future<int> entryCount(ProviderContainer container) async => (await container.read(entriesRepositoryProvider).watchEntries().first).length;

  testWidgets('Back on an untouched new entry leaves without asking', (tester) async {
    await pumpApp(tester);
    await openNewEntry(tester);
    await systemBack(tester);
    expect(discardDialog, findsNothing);
    expect(editorTitle, findsNothing);
  });

  testWidgets('Back after typing an amount asks; Keep editing stays, Discard leaves without saving', (tester) async {
    final container = await pumpApp(tester);
    await openNewEntry(tester);
    await enter(tester, amountField, '250');

    await systemBack(tester);
    expect(discardDialog, findsOneWidget);
    expect(find.text('Keep editing'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await settle(tester);
    expect(discardDialog, findsNothing);
    expect(editorTitle, findsOneWidget);
    expect(find.text('250'), findsOneWidget, reason: 'the amount is still there');

    await systemBack(tester);
    await tester.tap(find.text('Discard'));
    await settle(tester);
    expect(editorTitle, findsNothing);
    expect(await tester.runAsync(() => entryCount(container)), 0);
  });

  testWidgets('the close button asks too, here after only a note', (tester) async {
    await pumpApp(tester);
    await openNewEntry(tester);
    await openMoreDetails(tester);
    await enter(tester, noteField, 'chai');
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(discardDialog, findsOneWidget);
  });

  testWidgets('choosing a category counts as input', (tester) async {
    await pumpApp(tester);
    await openNewEntry(tester);
    await pickMilkCategory(tester);
    await systemBack(tester);
    expect(discardDialog, findsOneWidget);
  });

  testWidgets('clearing what was typed leaves without asking again', (tester) async {
    await pumpApp(tester);
    await openNewEntry(tester);
    await enter(tester, amountField, '40');
    await enter(tester, amountField, '');
    await systemBack(tester);
    expect(discardDialog, findsNothing);
    expect(editorTitle, findsNothing);
  });

  testWidgets('saving leaves without asking', (tester) async {
    final container = await pumpApp(tester);
    await openNewEntry(tester);
    await pickMilkCategory(tester);
    await enter(tester, amountField, '120');
    await tester.ensureVisible(find.textContaining('Save ₹'));
    await tester.tap(find.textContaining('Save ₹'));
    await settle(tester);
    expect(discardDialog, findsNothing);
    expect(editorTitle, findsNothing);
    expect(await tester.runAsync(() => entryCount(container)), 1);
  });

  testWidgets('editing an entry asks only once something changed', (tester) async {
    final container = await pumpApp(tester);
    await tester.runAsync(() => container.read(entriesRepositoryProvider).saveEntry(
          EntriesRepository.newExpense(id: 'lunch', amountMinor: 30000, occurredAt: DateTime(2026, 10, 20), note: 'Lunch'),
        ));
    appRouter.push('/entry?id=lunch');
    await settle(tester);
    expect(find.text('Edit entry'), findsOneWidget);
    await systemBack(tester);
    expect(discardDialog, findsNothing, reason: 'nothing changed');
    expect(find.text('Edit entry'), findsNothing);

    appRouter.push('/entry?id=lunch');
    await settle(tester);
    await enter(tester, noteField, 'Lunch with Rahul');
    await systemBack(tester);
    expect(discardDialog, findsOneWidget);
    await tester.tap(find.text('Discard'));
    await settle(tester);
    expect(find.text('Edit entry'), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/features/shell/router.dart';

import '../support/app_harness.dart';

/// Progressive disclosure (#collapse-entry-form): a fresh entry shows only
/// amount/category/account/date; everything else hides behind "More details",
/// which opens itself only when a tucked-away field already has a value.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final noteField = find.widgetWithText(TextField, 'Note');
  final payeeField = find.widgetWithText(TextField, 'Paid to / received from');
  final dateButton = find.byIcon(Icons.calendar_today_outlined);
  final moreDetails = find.text('More details');

  Future<void> openNewEntry(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    expect(find.text('New entry'), findsOneWidget);
  }

  testWidgets('a fresh entry shows amount/category/account/date but hides note and payee', (tester) async {
    await pumpApp(tester);
    await openNewEntry(tester);

    // Always visible: amount field, the category tile and the account picker.
    expect(find.byType(TextField), findsOneWidget, reason: 'only the amount field is a text field while collapsed');
    expect(find.text('Uncategorised'), findsOneWidget, reason: 'category tile');
    expect(find.text('Account'), findsOneWidget, reason: 'account label');
    expect(dateButton, findsOneWidget, reason: 'the date is always on the main form');

    // Tucked away until "More details" opens.
    expect(moreDetails, findsOneWidget);
    expect(noteField, findsNothing);
    expect(payeeField, findsNothing);

    await tester.ensureVisible(moreDetails);
    await tester.tap(moreDetails);
    await settle(tester);

    expect(noteField, findsOneWidget);
    expect(payeeField, findsOneWidget);
  });

  testWidgets('a new entry defaults to today on the main form', (tester) async {
    await pumpApp(tester);
    await openNewEntry(tester);
    expect(find.descendant(of: find.byKey(const ValueKey('editor.date')), matching: find.text('Today')), findsOneWidget);
  });

  testWidgets('editing a plain entry keeps More details collapsed', (tester) async {
    final container = await pumpApp(tester);
    await tester.runAsync(() => container.read(entriesRepositoryProvider).saveEntry(
          EntriesRepository.newExpense(id: 'coffee', amountMinor: 5000, occurredAt: DateTime.now()),
        ));
    appRouter.push('/entry?id=coffee');
    await settle(tester);

    expect(find.text('Edit entry'), findsOneWidget);
    expect(noteField, findsNothing);
    expect(dateButton, findsOneWidget, reason: 'the date stays visible while More details is collapsed');
  });

  testWidgets('editing an entry that has a note starts with More details open', (tester) async {
    final container = await pumpApp(tester);
    await tester.runAsync(() => container.read(entriesRepositoryProvider).saveEntry(
          EntriesRepository.newExpense(id: 'lunch', amountMinor: 30000, occurredAt: DateTime.now(), note: 'Lunch'),
        ));
    appRouter.push('/entry?id=lunch');
    await settle(tester);

    expect(find.text('Edit entry'), findsOneWidget);
    // No tap on "More details" — it auto-expanded because the note is set.
    expect(find.widgetWithText(TextField, 'Lunch'), findsOneWidget, reason: 'the note field is visible without opening anything');
    expect(payeeField, findsOneWidget);
    expect(dateButton, findsOneWidget);
  });

  testWidgets('saving a collapsed entry stores today as the date', (tester) async {
    final container = await pumpApp(tester);
    await openNewEntry(tester);
    await enter(tester, find.byType(TextField).first, '250');

    final save = find.byKey(const ValueKey('editor.save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await settle(tester);
    expect(find.text('New entry'), findsNothing, reason: 'the editor closed after saving');

    final entries = await tester.runAsync(() => container.read(entriesRepositoryProvider).watchEntries().first);
    expect(entries, hasLength(1));
    expect(isSameDay(entries!.single.entry.occurredAt, DateTime.now()), isTrue, reason: 'a collapsed save keeps the default of today');
  });

  testWidgets('the category picker can clear a category back to Uncategorised', (tester) async {
    await pumpApp(tester);
    await openNewEntry(tester);

    // Assign a category.
    await tester.tap(find.text('Uncategorised'));
    await settle(tester);
    await enter(tester, find.widgetWithText(TextField, 'Search categories'), 'rent');
    await settle(tester);
    await tester.tap(find.text('Rent'));
    await settle(tester);
    expect(find.text('Rent'), findsOneWidget, reason: 'the tile now shows the chosen category');

    // Reopen the picker and clear it.
    await tester.tap(find.text('Rent'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('category.clear')));
    await settle(tester);

    expect(find.text('Rent'), findsNothing);
    expect(find.text('Uncategorised'), findsOneWidget, reason: 'the category reverted to Uncategorised');
  });
}

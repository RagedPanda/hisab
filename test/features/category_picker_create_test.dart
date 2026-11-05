import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/shell/router.dart';

import '../support/app_harness.dart';
import '../support/editor_harness.dart';
import '../support/seed.dart';

/// Making a category straight from the shared category picker: the "Add" row
/// a search offers, the sheet it opens and the pick it hands back.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final searchField = find.widgetWithText(TextField, 'Search categories');
  final addRow = find.byKey(const ValueKey('category.addNamed'));
  final newRow = find.byKey(const ValueKey('category.new'));
  final nameField = find.byKey(const ValueKey('categoryForm.name'));
  final parentChoice = find.byKey(const ValueKey('categoryForm.parent'));
  final saveButton = find.byKey(const ValueKey('categoryForm.save'));

  Future<List<Category>> categories(WidgetTester tester, ProviderContainer container) async =>
      (await tester.runAsync(() => container.read(categoriesRepositoryProvider).getAll(includeArchived: true)))!;

  Future<void> openPicker(WidgetTester tester) => tapInEditor(tester, find.text('Uncategorised'));

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(searchField, query);
    await settle(tester);
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await settle(tester);
  }

  testWidgets('a search with no exact match offers to add it, under a suggested parent, and picks it', (tester) async {
    final container = await openEditor(tester);
    final foodId = await readDb(tester, () => seededCategoryId(container, 'food'));
    await enterEditorAmount(tester, '80');
    await openPicker(tester);

    await search(tester, 'ice  cream ');
    expect(find.text('Add "Ice cream"'), findsOneWidget);
    expect(find.text('No matching category'), findsNothing, reason: 'the add row replaces the empty state');

    await tapAndSettle(tester, addRow);
    expect(tester.widget<TextField>(nameField).controller!.text, 'Ice cream');
    expect(find.descendant(of: parentChoice, matching: find.text('Food & Dining (suggested)')), findsOneWidget, reason: 'ice cream is a sweets keyword');

    await tapAndSettle(tester, saveButton);
    expect(searchField, findsNothing, reason: 'the picker closes with the new category');
    expect(find.descendant(of: editorScreen, matching: find.text('Ice cream')), findsOneWidget);

    final iceCream = (await categories(tester, container)).singleWhere((category) => category.name == 'Ice cream');
    final food = (await categories(tester, container)).singleWhere((category) => category.id == foodId);
    expect((iceCream.parentId, iceCream.kind, iceCream.icon, iceCream.color), (foodId, 'expense', food.icon, food.color));

    // From now on it is an ordinary category: found by search, no add row.
    await tapInEditor(tester, find.descendant(of: editorScreen, matching: find.text('Ice cream')));
    await search(tester, 'ice cream');
    expect(addRow, findsNothing);
    await tapAndSettle(tester, find.text('Ice cream').last);

    await saveEditor(tester);
    expect((await readDb(tester, () => liveEntries(container))).single.categoryId, iceCream.id);
  });

  testWidgets('partial matches keep the add row, below them; an exact match hides it', (tester) async {
    await openEditor(tester);
    await openPicker(tester);

    await search(tester, 'food');
    expect(addRow, findsOneWidget);
    expect(find.text('Food & Dining'), findsWidgets);
    expect(tester.getTopLeft(addRow).dy, greaterThan(tester.getTopLeft(find.text('Food & Dining').first).dy));

    await search(tester, 'GROCERIES ');
    expect(addRow, findsNothing);
    expect(find.text('Groceries'), findsOneWidget);
  });

  testWidgets('the new category can go top level, taking its own colour', (tester) async {
    final container = await openEditor(tester);
    await openPicker(tester);
    await search(tester, 'qqq xyz');
    await tapAndSettle(tester, addRow);
    expect(find.descendant(of: parentChoice, matching: find.text('Its own category (top level)')), findsOneWidget, reason: 'nothing to suggest');

    await tapAndSettle(tester, saveButton);
    final hobby = (await categories(tester, container)).singleWhere((category) => category.name == 'Qqq xyz');
    expect((hobby.parentId, hobby.icon), (null, 'category'));
  });

  testWidgets('choosing another parent moves the new category there', (tester) async {
    final container = await openEditor(tester);
    final transportId = await readDb(tester, () => seededCategoryId(container, 'transport'));
    await openPicker(tester);
    await search(tester, 'ice cream');
    await tapAndSettle(tester, addRow);

    await tapAndSettle(tester, parentChoice);
    await tester.tap(find.text('Transport').last);
    await settle(tester);
    await tapAndSettle(tester, saveButton);
    expect((await categories(tester, container)).singleWhere((category) => category.name == 'Ice cream').parentId, transportId);
  });

  testWidgets('"New category" ends the list, and a name that already exists there picks the existing one', (tester) async {
    final container = await openEditor(tester);
    final before = (await categories(tester, container)).length;
    final transportId = await readDb(tester, () => seededCategoryId(container, 'transport'));
    await openPicker(tester);

    await tester.scrollUntilVisible(newRow, 300, scrollable: find.byType(Scrollable).last);
    await tapAndSettle(tester, newRow);
    expect(tester.widget<TextField>(nameField).controller!.text, isEmpty);
    await tester.enterText(nameField, ' transport ');
    await tapAndSettle(tester, saveButton);

    expect((await categories(tester, container)).length, before, reason: 'no duplicate made');
    expect(find.descendant(of: editorScreen, matching: find.text('Transport')), findsOneWidget);
    await enterEditorAmount(tester, '40');
    await saveEditor(tester);
    expect((await readDb(tester, () => liveEntries(container))).single.categoryId, transportId);
  });

  testWidgets('choosing a category to filter by does not offer to create one', (tester) async {
    await pumpApp(tester);
    appRouter.go('/transactions');
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('entries.filters')));
    await settle(tester);
    final categoryTile = find.byKey(const ValueKey('filter.category'));
    await tester.scrollUntilVisible(categoryTile, 100, scrollable: find.descendant(of: find.byKey(const ValueKey('filter.sheet')), matching: find.byType(Scrollable)).first);
    await tapAndSettle(tester, categoryTile);

    await search(tester, 'ice cream');
    expect(addRow, findsNothing);
    expect(find.text('No matching category'), findsOneWidget);
    await search(tester, '');
    expect(newRow, findsNothing);
  });
}

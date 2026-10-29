import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/shell/router.dart';

import '../support/app_harness.dart';

/// Settings > Categories: the expense/income/transfer lists, the add/edit
/// sheet and each row's menu, plus Settings > Categories > Add a pack.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> openCategories(WidgetTester tester, {Future<void> Function(ProviderContainer container)? seed}) async {
    final container = await pumpApp(tester, seed: seed);
    appRouter.push('/categories');
    await settle(tester);
    expect(find.text('Categories'), findsWidgets);
    return container;
  }

  Future<List<Category>> allCategories(WidgetTester tester, ProviderContainer container) async =>
      (await tester.runAsync(() => container.read(categoriesRepositoryProvider).getAll(includeArchived: true)))!;

  Future<Category> categoryNamed(WidgetTester tester, ProviderContainer container, String name) async =>
      (await allCategories(tester, container)).singleWhere((category) => category.name == name);

  Future<void> tapAndSettle(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await settle(tester);
  }

  /// Opens the row menu of the card whose title is [name] and picks [item].
  Future<void> pickFromMenu(WidgetTester tester, String name, String item) async {
    final card = find.ancestor(of: find.text(name), matching: find.byType(Card)).first;
    // The last card can sit under the add button, so open the menu directly rather than tapping its icon.
    tester.state<PopupMenuButtonState<String>>(find.descendant(of: card, matching: find.byType(PopupMenuButton<String>)).first).showButtonMenu();
    await settle(tester);
    await tester.tap(find.text(item).last);
    await settle(tester);
  }

  Finder sheetField(String label) => find.widgetWithText(TextField, label);
  final saveButton = find.widgetWithText(FilledButton, 'Save');

  group('categories screen', () {
    testWidgets('lists each kind on its own segment with a preview of subcategories', (tester) async {
      await openCategories(tester);

      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.textContaining('Groceries, Milk & Dairy, Vegetables & Fruits, +'), findsOneWidget, reason: 'three children then an overflow count');
      expect(find.text('Salary'), findsNothing);

      await tapAndSettle(tester, find.text('Income'));
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('Food & Dining'), findsNothing);
    });

    testWidgets('expanding a parent lists its children with their units', (tester) async {
      await openCategories(tester);

      await tapAndSettle(tester, find.text('Food & Dining'));
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Units: kg, g, pcs, pack'), findsOneWidget);
      expect(find.text('Add subcategory'), findsOneWidget);
    });

    testWidgets('the add button creates a category of the shown kind with tidied units, colour and icon', (tester) async {
      final container = await openCategories(tester);
      await tapAndSettle(tester, find.text('Income'));

      await tapAndSettle(tester, find.byType(FloatingActionButton));
      expect(find.text('New category'), findsOneWidget);

      await tapAndSettle(tester, saveButton);
      expect(find.text('New category'), findsOneWidget, reason: 'an empty name does not save');

      await enter(tester, sheetField('Name'), '  Rent received ');
      await enter(tester, sheetField('Units for items (comma separated)'), ' kg , , pcs');
      await tapAndSettle(tester, find.byType(CircleAvatar).at(2));
      final iconButtons = find.descendant(of: find.byType(GridView), matching: find.byType(IconButton));
      await tester.tap(iconButtons.at(3));
      await settle(tester);
      await tapAndSettle(tester, saveButton);

      expect(find.text('New category'), findsNothing, reason: 'the sheet closes after saving');
      final created = await categoryNamed(tester, container, 'Rent received');
      expect(created.kind, 'income');
      expect(created.units, 'kg,pcs');
      expect(created.parentId, isNull);
      await tester.scrollUntilVisible(find.text('Rent received'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Rent received'), findsOneWidget);
    });

    testWidgets('Add subcategory creates a child under that parent', (tester) async {
      final container = await openCategories(tester);
      final food = await categoryNamed(tester, container, 'Food & Dining');

      await tapAndSettle(tester, find.text('Food & Dining'));
      await tapAndSettle(tester, find.text('Add subcategory').first);
      expect(find.text('New subcategory of Food & Dining'), findsOneWidget);

      await enter(tester, sheetField('Name'), 'Biryani');
      await tapAndSettle(tester, saveButton);

      final created = await categoryNamed(tester, container, 'Biryani');
      expect(created.parentId, food.id);
      expect(created.icon, food.icon, reason: 'a new child starts with its parent icon');
      expect(created.color, food.color);
    });

    testWidgets('Edit renames a category and keeps its id', (tester) async {
      final container = await openCategories(tester);
      final food = await categoryNamed(tester, container, 'Food & Dining');

      await pickFromMenu(tester, 'Food & Dining', 'Edit');
      expect(find.text('Edit Food & Dining'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Food & Dining'), findsOneWidget, reason: 'the name field starts filled');

      await enter(tester, find.widgetWithText(TextField, 'Food & Dining'), 'Eating');
      await tapAndSettle(tester, saveButton);

      final renamed = (await allCategories(tester, container)).singleWhere((category) => category.id == food.id);
      expect(renamed.name, 'Eating');
    });

    testWidgets('Archive hides a category from pickers and Unarchive brings it back', (tester) async {
      final container = await openCategories(tester);

      await pickFromMenu(tester, 'Food & Dining', 'Archive (hide from picker)');
      expect((await categoryNamed(tester, container, 'Food & Dining')).isArchived, isTrue);
      expect(find.text('Food & Dining'), findsOneWidget, reason: 'archived rows stay listed here');

      await pickFromMenu(tester, 'Food & Dining', 'Unarchive');
      expect((await categoryNamed(tester, container, 'Food & Dining')).isArchived, isFalse);
    });

    testWidgets('only categories the user made can be deleted, after a confirm', (tester) async {
      final container = await openCategories(tester, seed: (container) => container.read(categoriesRepositoryProvider).create(name: 'Aquarium', icon: 'pets', color: 0xFF8D6E63, kind: 'expense'));

      await tester.scrollUntilVisible(find.text('Aquarium'), 200, scrollable: find.byType(Scrollable).first);
      await pickFromMenu(tester, 'Aquarium', 'Delete');
      expect(find.text('Delete Aquarium?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect((await allCategories(tester, container)).where((category) => category.name == 'Aquarium'), hasLength(1));

      await pickFromMenu(tester, 'Aquarium', 'Delete');
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await settle(tester);
      expect((await allCategories(tester, container)).where((category) => category.name == 'Aquarium'), isEmpty);
      expect(find.text('Aquarium'), findsNothing);

      await tester.scrollUntilVisible(find.text('Food & Dining'), -200, scrollable: find.byType(Scrollable).first);
      final foodCard = find.ancestor(of: find.text('Food & Dining'), matching: find.byType(Card)).first;
      tester.state<PopupMenuButtonState<String>>(find.descendant(of: foodCard, matching: find.byType(PopupMenuButton<String>)).first).showButtonMenu();
      await settle(tester);
      expect(find.text('Archive (hide from picker)'), findsOneWidget);
      expect(find.text('Delete'), findsNothing, reason: 'built-in categories can only be archived');
    });

    testWidgets('Add a pack opens the pack list', (tester) async {
      await openCategories(tester);
      await tapAndSettle(tester, find.byKey(const ValueKey('categories.addPack')));
      expect(find.text('Category packs'), findsOneWidget);
    });
  });

  group('category packs', () {
    Future<ProviderContainer> openPacks(WidgetTester tester) async {
      final container = await pumpApp(tester);
      appRouter.push('/categories/packs');
      await settle(tester);
      return container;
    }

    final vehiclePack = find.byKey(const ValueKey('pack.vehicle'));

    testWidgets('adding a pack creates its categories, reuses the ones already there and marks it Added', (tester) async {
      final container = await openPacks(tester);
      final before = (await allCategories(tester, container)).length;

      expect(find.descendant(of: vehiclePack, matching: find.text('Added')), findsNothing);
      await tapAndSettle(tester, vehiclePack);
      expect(find.text('Add pack'), findsOneWidget);
      expect(find.textContaining('already in your list'), findsOneWidget, reason: 'fuel and servicing come from the built-in list');
      expect(find.textContaining('new categor'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('pack.add')));
      await settle(tester);

      expect(find.byKey(const ValueKey('pack.add')), findsNothing, reason: 'the preview closes');
      expect(find.textContaining('Pack added with'), findsOneWidget);
      expect(find.descendant(of: vehiclePack, matching: find.text('Added')), findsOneWidget);
      expect((await allCategories(tester, container)).length, greaterThan(before));
    });

    testWidgets('removing an added pack asks first and archives its unused categories', (tester) async {
      final container = await openPacks(tester);
      await tapAndSettle(tester, vehiclePack);
      await tester.tap(find.byKey(const ValueKey('pack.add')));
      await settle(tester);
      await tester.pump(const Duration(seconds: 5));
      await settle(tester);

      await tapAndSettle(tester, vehiclePack);
      expect(find.text('Remove pack'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pack.remove')));
      await settle(tester);
      expect(find.text('Remove Vehicle?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(find.byKey(const ValueKey('pack.remove')), findsOneWidget, reason: 'cancel keeps the preview open and the pack on');

      await tester.tap(find.byKey(const ValueKey('pack.remove')));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
      await settle(tester);

      expect(find.text('Pack removed'), findsOneWidget);
      expect(find.descendant(of: vehiclePack, matching: find.text('Added')), findsNothing);
      final parts = (await allCategories(tester, container)).singleWhere((category) => category.seedKey == 'vehicle_parts');
      expect(parts.isArchived, isTrue);
    });
  });
}

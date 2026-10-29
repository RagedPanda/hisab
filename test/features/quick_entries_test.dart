import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/dashboard/dashboard_keys.dart';
import 'package:hisab/features/quick_entries/quick_entries_screen.dart';
import 'package:hisab/features/shell/router.dart';

import '../support/app_harness.dart';
import '../support/editor_harness.dart';
import '../support/seed.dart';

/// Adds quick entries named [labels], ₹32 each unless [amountMinor] says otherwise.
Future<void> _seedQuickEntries(ProviderContainer container, List<String> labels, {int? amountMinor = 3200}) async {
  for (final label in labels) {
    await container.read(quickEntriesRepositoryProvider).add(label: label, amountMinor: amountMinor, accountId: await cashAccountId(container));
  }
}

Future<List<QuickEntry>> _quickEntries(WidgetTester tester, ProviderContainer container) =>
    readDb(tester, () => container.read(quickEntriesRepositoryProvider).watchAll().first);

Finder _chip(String label) => find.ancestor(of: find.textContaining(label), matching: find.byType(ActionChip));

Future<void> _nameQuickEntry(WidgetTester tester, String label) async {
  await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), label);
  await tester.tap(find.text('Save'));
  await settle(tester);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('Home', () {
    testWidgets('there is no quick entries card until one is saved', (tester) async {
      await pumpApp(tester);
      expect(find.byKey(kQuickEntriesCardKey), findsNothing);
    });

    testWidgets('tapping a chip adds the entry at once, and Undo takes it back', (tester) async {
      final container = await pumpApp(tester, seed: (container) => _seedQuickEntries(container, ['Milk']));
      await tester.ensureVisible(_chip('Milk'));
      await tester.tap(_chip('Milk'));
      await settle(tester);

      final added = (await readDb(tester, () => liveEntries(container))).single;
      expect((added.amountMinor, added.kind), (3200, 'expense'));
      expect(find.textContaining('Added Milk'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(await readDb(tester, () => liveEntries(container)), isEmpty);
    });

    testWidgets('a chip with no amount opens the editor prefilled instead', (tester) async {
      final container = await pumpApp(tester, seed: (container) => _seedQuickEntries(container, ['Auto'], amountMinor: null));
      await tester.ensureVisible(_chip('Auto'));
      await tester.tap(_chip('Auto'));
      await settle(tester);
      expect(editorScreen, findsOneWidget);
      expect(await readDb(tester, () => liveEntries(container)), isEmpty);
    });

    testWidgets('past the chosen count the rest sit behind +N more', (tester) async {
      await pumpApp(tester, seed: (container) => _seedQuickEntries(container, ['A1', 'A2', 'A3', 'A4', 'A5', 'A6']));
      expect(_chip('A4'), findsOneWidget);
      expect(_chip('A5'), findsNothing);
      final more = find.byKey(const ValueKey('quick.more'));
      expect(find.descendant(of: more, matching: find.text('+2 more')), findsOneWidget);

      await tester.ensureVisible(more);
      await tester.tap(more);
      await settle(tester);
      expect(find.descendant(of: find.byType(BottomSheet), matching: find.byType(ActionChip)), findsNWidgets(6));
    });
  });

  group('editor', () {
    testWidgets('the bolt saves the form as a quick entry named after the payee', (tester) async {
      final container = await openEditor(tester);
      await enterEditorAmount(tester, '32');
      await tapEditorMenu(tester, 'editor.saveAsQuick');
      await _nameQuickEntry(tester, 'Milk');

      final saved = (await _quickEntries(tester, container)).single;
      expect((saved.label, saved.amountMinor), ('Milk', 3200));
      expect(await readDb(tester, () => liveEntries(container)), isEmpty, reason: 'saving a quick entry does not add an entry');
    });

    testWidgets('opening a quick entry prefills the editor with it', (tester) async {
      late String quickId;
      final container = await openEditor(
        tester,
        seed: (container) async => quickId = await container.read(quickEntriesRepositoryProvider).add(label: 'Milk', amountMinor: 3200, payee: 'Gwala Ji'),
        location: () => '/entry?quick=$quickId',
      );
      expect(await editorAmountText(tester), '32');
      await saveEditor(tester);
      final saved = (await readDb(tester, () => liveEntries(container))).single;
      expect((saved.amountMinor, saved.payee), (3200, 'Gwala Ji'));
    });

    testWidgets('"New quick entry" saves only the quick entry and goes back', (tester) async {
      final container = await openEditor(tester, location: () => '/entry?saveAs=quick');
      expect(find.text('New quick entry'), findsOneWidget);
      await enterEditorAmount(tester, '15');
      await tester.tap(find.byKey(const ValueKey('editor.saveQuick')));
      await settle(tester);
      await _nameQuickEntry(tester, 'Tea');

      expect((await _quickEntries(tester, container)).single.label, 'Tea');
      expect(await readDb(tester, () => liveEntries(container)), isEmpty);
      expect(editorScreen, findsNothing);
    });
  });

  group('Settings → Quick entries', () {
    testWidgets('shows the empty state, and the stepper sets how many chips Home shows', (tester) async {
      final container = await pumpApp(tester);
      appRouter.push(kQuickEntriesLocation);
      await settle(tester);
      expect(find.textContaining('No quick entries yet'), findsOneWidget);

      await tester.tap(find.byKey(const Key('quickEntries.more')));
      await settle(tester);
      expect(container.read(settingsProvider).quickEntriesShown, 5);
      await tester.tap(find.byKey(const Key('quickEntries.fewer')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('quickEntries.fewer')));
      await settle(tester);
      expect(container.read(settingsProvider).quickEntriesShown, 3);
    });

    testWidgets('rename and delete from a row menu', (tester) async {
      final container = await pumpApp(tester, seed: (container) => _seedQuickEntries(container, ['Milk', 'Tea']));
      appRouter.push(kQuickEntriesLocation);
      await settle(tester);
      final milk = (await _quickEntries(tester, container)).first;

      await tester.tap(find.byKey(Key('quickEntries.menu.${milk.id}')));
      await settle(tester);
      await tester.tap(find.text('Rename'));
      await settle(tester);
      await _nameQuickEntry(tester, 'Buffalo milk');
      expect((await _quickEntries(tester, container)).map((quick) => quick.label), ['Buffalo milk', 'Tea']);

      await tester.tap(find.byKey(Key('quickEntries.menu.${milk.id}')));
      await settle(tester);
      await tester.tap(find.text('Delete').last);
      await settle(tester);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Delete')));
      await settle(tester);
      expect((await _quickEntries(tester, container)).map((quick) => quick.label), ['Tea']);
    });
  });
}

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/dashboard/dashboard_keys.dart';
import 'package:hisab/features/groups/split_this_screen.dart';

import '../support/app_harness.dart';
import '../support/editor_harness.dart';
import '../support/seed.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late String groupId;

  /// A personal ₹900 dinner paid from Cash, and a group of me and Amit.
  Future<ProviderContainer> openDinner(WidgetTester tester) => openEditor(
        tester,
        location: () => '/entry?id=dinner',
        seed: (container) async {
          groupId = await container.read(groupsRepositoryProvider).createGroup(name: 'Goa', icon: 'beach', myName: 'Me', otherMembers: ['Amit']);
          await seedEntry(container, id: 'dinner', payee: 'Fisherman’s Wharf', note: 'Beach dinner', amountMinor: 90000, accountId: await cashAccountId(container));
        },
      );

  Future<List<Entry>> saved(WidgetTester tester, ProviderContainer container) async => (await tester.runAsync(() => liveEntries(container)))!;
  Future<int> spentThisMonth(WidgetTester tester, ProviderContainer container) => readDb(tester, () async {
        final now = DateTime.now();
        return (await container.read(entriesRepositoryProvider).watchTotals(DateRange(DateTime(now.year, now.month), DateTime(now.year, now.month + 1))).first).expense;
      });
  Future<int> cashBalance(WidgetTester tester, ProviderContainer container) =>
      readDb(tester, () async => (await container.read(accountsRepositoryProvider).getAll()).single.balanceMinor);

  /// ⋮ > Split this > Goa, landing on the prefilled group expense.
  Future<void> splitIntoGoa(WidgetTester tester) async {
    await tapEditorMenu(tester, 'editor.splitThis');
    expect(find.text('Split with which group?'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('splitThis.group.$groupId')));
    await settle(tester);
  }

  test('the location picks a group first, then opens the prefilled form', () {
    expect(splitThisLocation('e1'), '/split/e1');
    expect(splitThisLocation('e1', groupId: 'g1'), '/entry?splitFrom=e1&group=g1');
  });

  testWidgets('opens a group expense prefilled from the entry', (tester) async {
    await openDinner(tester);
    await splitIntoGoa(tester);

    expect(find.text('Group expense'), findsOneWidget);
    expect(find.text('Saving moves this entry into the group. Only your share counts as spent.'), findsOneWidget);
    expect(await editorAmountText(tester), '900');
    expect(find.text('Fisherman’s Wharf'), findsOneWidget);
    expect(find.text('Beach dinner'), findsOneWidget);
    expect(find.byKey(const ValueKey('editor.saveAndAddAnother')), findsNothing);
  });

  testWidgets('saving converts the entry, so Home counts only my share', (tester) async {
    final container = await openDinner(tester);
    final cashBefore = await cashBalance(tester, container);
    expect(await spentThisMonth(tester, container), 90000);
    await splitIntoGoa(tester);
    await saveEditor(tester);

    final entries = await saved(tester, container);
    expect(entries.map((entry) => entry.id), ['dinner'], reason: 'the entry became the group expense, no second one');
    expect((entries.single.groupId, entries.single.payee, entries.single.note), (groupId, 'Fisherman’s Wharf', 'Beach dinner'));
    expect(await spentThisMonth(tester, container), 45000);
    expect(find.descendant(of: find.byKey(kHeroCardKey), matching: find.textContaining('450')), findsWidgets);
    expect(await cashBalance(tester, container), cashBefore, reason: 'the cash really left; splitting does not refund it');
    expect(find.text('Moved to Goa. Only your share counts as spent.'), findsOneWidget);
  });

  testWidgets('Undo turns it back into the personal entry', (tester) async {
    final container = await openDinner(tester);
    final cashBefore = await cashBalance(tester, container);
    await splitIntoGoa(tester);
    await saveEditor(tester);
    await tester.tap(find.text('Undo'));
    await settle(tester);

    final entry = (await saved(tester, container)).single;
    expect((entry.id, entry.groupId, entry.accountId), ('dinner', null, await readDb(tester, () => cashAccountId(container))));
    expect(await spentThisMonth(tester, container), 90000);
    expect(await cashBalance(tester, container), cashBefore);
  });

  testWidgets('is offered only on personal expenses', (tester) async {
    await openEditor(
      tester,
      location: () => '/entry?id=salary',
      seed: (container) => seedEntry(container, id: 'salary', payee: 'Acme', amountMinor: 100000, kind: 'income'),
    );
    await tester.tap(find.byKey(const Key('editor.more')));
    await settle(tester);
    expect(find.byKey(const Key('editor.again')), findsOneWidget);
    expect(find.byKey(const Key('editor.splitThis')), findsNothing);
  });

  testWidgets('with no group to split into, offers to start one', (tester) async {
    await openEditor(
      tester,
      location: () => '/split/dinner',
      seed: (container) => seedEntry(container, id: 'dinner', payee: 'Wharf', amountMinor: 90000),
    );
    expect(find.text('Split with which group?'), findsOneWidget);
    expect(find.text('Split bills with friends'), findsOneWidget);
  });
}

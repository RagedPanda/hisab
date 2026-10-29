import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/features/expense_editor/item_row.dart';
import 'package:hisab/features/shell/router.dart';

import '../support/app_harness.dart';
import '../support/editor_harness.dart';
import '../support/seed.dart';

/// The entry editor inside a group: who paid, how the bill is split, items
/// assigned to people, and what a group expense saves, deletes and repeats.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final everyonePaysChip = find.widgetWithText(ChoiceChip, '2+ people');
  final splitMethodPicker = find.byKey(const ValueKey('split-method-picker'));

  /// The group made by [seedTrip]: You, Asha and Ravi, by name.
  late String groupId;
  late Map<String, String> memberIds;

  Future<void> seedTrip(ProviderContainer container) async {
    final groups = container.read(groupsRepositoryProvider);
    groupId = await groups.createGroup(name: 'Goa trip', icon: 'flight', myName: 'You', otherMembers: ['Asha', 'Ravi']);
    memberIds = {for (final member in await groups.getMembers(groupId)) member.name: member.id};
  }

  Future<ProviderContainer> openGroupEditor(WidgetTester tester, {Future<void> Function(ProviderContainer container)? seed}) => openEditor(
        tester,
        location: () => '/entry?group=$groupId',
        seed: (container) async {
          await seedTrip(container);
          if (seed != null) await seed(container);
        },
      );

  Future<void> pickSplitMethod(WidgetTester tester, String method) async {
    await tapInEditor(tester, splitMethodPicker);
    await tester.tap(find.byKey(ValueKey('split-method-$method')));
    await settle(tester);
  }

  Future<void> enterPayerAmount(WidgetTester tester, String member, String amount) async {
    final field = find.byKey(ValueKey('payer-amount-${memberIds[member]}'));
    await revealInEditor(tester, field);
    await enter(tester, field, amount);
  }

  Future<Entry> savedEntry(WidgetTester tester, ProviderContainer container) async => (await readDb(tester, () => liveEntries(container))).single;

  Future<EntryDetails> detailsOf(WidgetTester tester, ProviderContainer container, String entryId) async => (await readDb<EntryDetails?>(tester, () => container.read(entriesRepositoryProvider).getEntry(entryId)))!;

  /// Finds the assign chip of [member] on whichever item row shows it.
  Finder assignChip(String member) => find.byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> && key.value.startsWith('assign-') && key.value.endsWith('-${memberIds[member]}');
      });

  group('paid by and split', () {
    testWidgets('a new group expense is paid by you, split equally and kept off every account', (tester) async {
      final container = await openGroupEditor(tester);
      await enterEditorAmount(tester, '300');
      await saveEditor(tester);

      final saved = await savedEntry(tester, container);
      expect(saved.groupId, groupId);
      expect(saved.paidByMemberId, memberIds['You']);
      expect(saved.splitMethod, 'equal');
      expect(saved.accountId, isNull);
      final details = await detailsOf(tester, container, saved.id);
      expect({for (final split in details.splits) split.memberId: split.amountMinor}, {for (final id in memberIds.values) id: 10000});
      expect(await readDb(tester, () => container.read(entriesRepositoryProvider).getPayers(saved.id)), isEmpty);
    });

    testWidgets('a split with nobody in it or money left over does not save', (tester) async {
      final container = await openGroupEditor(tester);
      await enterEditorAmount(tester, '300');
      await revealInEditor(tester, find.byType(Checkbox).last);
      for (var index = 0; index < 3; index++) {
        await tester.tap(find.byType(Checkbox).at(index));
        await tester.pump();
      }
      await saveEditor(tester);
      expect(find.text('Select at least one person'), findsWidgets);

      await pickSplitMethod(tester, 'exact');
      await saveEditor(tester);
      expect(find.text('₹300 left to assign'), findsWidgets);
      expect(await readDb(tester, () => liveEntries(container)), isEmpty);
    });

    testWidgets('several payers must cover the bill, reload on edit, and one tap goes back to a single payer', (tester) async {
      final container = await openGroupEditor(tester);
      await enterEditorAmount(tester, '300');
      await tapInEditor(tester, everyonePaysChip);
      expect(tester.widget<ChoiceChip>(everyonePaysChip).selected, isTrue);

      await enterPayerAmount(tester, 'You', '100');
      await saveEditor(tester);
      expect(find.text('Amounts paid must add up to ₹300'), findsWidgets);
      expect(await readDb(tester, () => liveEntries(container)), isEmpty);

      await enterPayerAmount(tester, 'Asha', '200');
      await saveEditor(tester);
      final saved = await savedEntry(tester, container);
      expect(saved.paidByMemberId, memberIds['Asha'], reason: 'the biggest payer is the main one');
      final payers = await readDb(tester, () => container.read(entriesRepositoryProvider).getPayers(saved.id));
      expect({for (final payer in payers) payer.memberId: payer.amountMinor}, {memberIds['You']: 10000, memberIds['Asha']: 20000});

      appRouter.push('/entry?id=${saved.id}');
      await settle(tester);
      await revealInEditor(tester, everyonePaysChip);
      expect(tester.widget<ChoiceChip>(everyonePaysChip).selected, isTrue, reason: 'the payers come back on edit');

      await tapInEditor(tester, find.widgetWithText(ChoiceChip, 'Ravi'));
      expect(find.byKey(ValueKey('payer-amount-${memberIds['You']}')), findsNothing);
      await saveEditor(tester);
      final edited = await savedEntry(tester, container);
      expect(edited.paidByMemberId, memberIds['Ravi']);
      expect(await readDb(tester, () => container.read(entriesRepositoryProvider).getPayers(saved.id)), isEmpty);
    });

    testWidgets('a group whose members were all removed asks who paid', (tester) async {
      final container = await openGroupEditor(tester, seed: (container) async {
        for (final id in memberIds.values) {
          await container.read(groupsRepositoryProvider).removeMember(id);
        }
      });
      await enterEditorAmount(tester, '300');
      await saveEditor(tester);
      expect(find.text('Choose who paid'), findsOneWidget);
      expect(await readDb(tester, () => liveEntries(container)), isEmpty);
    });
  });

  group('by item', () {
    Future<void> addItem(WidgetTester tester, String name, String price) async {
      await tapInEditor(tester, find.text('Add item'));
      await revealInEditor(tester, find.widgetWithText(TextField, 'Item name'));
      await enter(tester, find.widgetWithText(TextField, 'Item name'), name);
      await enter(tester, find.widgetWithText(TextField, 'Price per unit'), price);
    }

    testWidgets('the first item splits by item; assignments and shared extras are saved', (tester) async {
      final container = await openGroupEditor(tester);
      await addItem(tester, 'Pizza', '300');
      await revealInEditor(tester, splitMethodPicker);
      expect(find.descendant(of: splitMethodPicker, matching: find.text('By item')), findsOneWidget);

      await tapInEditor(tester, assignChip('Ravi'));
      await tapInEditor(tester, find.byKey(const ValueKey('byItem.addExtras')));
      await revealInEditor(tester, find.widgetWithText(TextField, 'Price per unit').last);
      await enter(tester, find.widgetWithText(TextField, 'Price per unit').last, '30');
      expect(await editorAmountText(tester), '330');

      await saveEditor(tester);
      final saved = await savedEntry(tester, container);
      expect(saved.splitMethod, 'byItem');
      expect(saved.amountMinor, 33000);
      final details = await detailsOf(tester, container, saved.id);
      final pizza = details.items.firstWhere((item) => item.name == 'Pizza');
      final extras = details.items.firstWhere((item) => item.name == 'Delivery, tax or tip');
      expect(extras.isShared, isTrue);
      final assignments = await readDb(tester, () => container.read(entriesRepositoryProvider).getItemAssignments(saved.id));
      expect(assignments[pizza.id]?.toSet(), {memberIds['You'], memberIds['Asha']});
      final shares = {for (final split in details.splits) split.memberId: split.amountMinor};
      expect(shares[memberIds['Ravi']] ?? 0, 0, reason: 'extras follow the item shares, and Ravi had no items');
      expect(shares.values.fold<int>(0, (sum, share) => sum + share), 33000);
    });

    testWidgets('leaving by item after custom assignments asks first', (tester) async {
      final container = await openGroupEditor(tester);
      await addItem(tester, 'Pizza', '300');
      await tapInEditor(tester, assignChip('Ravi'));

      await pickSplitMethod(tester, 'equal');
      expect(find.text('Item assignments will be cleared'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      await revealInEditor(tester, splitMethodPicker);
      expect(find.descendant(of: splitMethodPicker, matching: find.text('By item')), findsOneWidget);

      await pickSplitMethod(tester, 'equal');
      await tester.tap(find.byKey(const ValueKey('byItem.clearConfirm')));
      await settle(tester);
      expect(find.byKey(const ValueKey('byItem.addExtras')), findsNothing);
      await saveEditor(tester);
      final saved = await savedEntry(tester, container);
      expect(saved.splitMethod, 'equal');
      final details = await detailsOf(tester, container, saved.id);
      expect(details.splits.map((split) => split.amountMinor), everyElement(10000));
    });

    testWidgets('removing the last item goes back to an equal split', (tester) async {
      await openGroupEditor(tester);
      await addItem(tester, 'Pizza', '300');
      await tapInEditor(tester, find.descendant(of: find.byType(ItemRow), matching: find.byTooltip('Remove')));
      await revealInEditor(tester, splitMethodPicker);
      expect(find.descendant(of: splitMethodPicker, matching: find.text('Equally')), findsOneWidget);
    });
  });

  group('saved group expenses', () {
    late String entryId;

    Future<void> seedExpense(ProviderContainer container) async {
      entryId = newId();
      await container.read(groupsRepositoryProvider).saveGroupExpense(
            EntriesRepository.newExpense(id: entryId, amountMinor: 30000, occurredAt: DateTime.now(), note: 'Dinner', groupId: groupId, paidByMemberId: memberIds['You'], splitMethod: 'equal'),
            splits: [for (final id in memberIds.values) SplitsCompanion.insert(id: newId(), entryId: entryId, memberId: id, amountMinor: 10000)],
          );
    }

    testWidgets('deleting one closes the editor and offers Undo', (tester) async {
      final container = await openEditor(tester, location: () => '/entry?id=$entryId', seed: (container) async {
        await seedTrip(container);
        await seedExpense(container);
      });
      await tester.tap(find.byTooltip('Delete'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await settle(tester);

      expect(editorScreen, findsNothing);
      expect(await readDb(tester, () => liveEntries(container)), isEmpty);
      expect(find.text('Expense deleted'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect((await savedEntry(tester, container)).id, entryId);
    });

    testWidgets('a repeat on a new group expense keeps its split and payer in the rule', (tester) async {
      final container = await openGroupEditor(tester);
      await enterEditorAmount(tester, '300');
      await tapInEditor(tester, find.byKey(const ValueKey('editor.repeat')));
      await tester.tap(find.byKey(const ValueKey('repeat.done')));
      await settle(tester);
      await saveEditor(tester);

      final saved = await savedEntry(tester, container);
      final rule = await readDb(tester, () => container.read(recurringRepositoryProvider).getRule(saved.recurringId!));
      expect(rule!.groupId, groupId);
      expect(rule.amountMinor, 30000);
    });
  });
}

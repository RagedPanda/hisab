import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/group_recurring_repository.dart';
import 'package:hisab/data/repositories/recurring_repository.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/split/group_recurring.dart';
import 'package:hisab/domain/split/split_calculator.dart';
import 'package:hisab/features/expense_editor/expense_editor_screen.dart';
import 'package:hisab/features/groups/group_settings_screen.dart';
import 'package:hisab/features/shell/widgets/common.dart';

import '../support/group_harness.dart';

/// "Flat" with Amit and Priya: settled up 19 days ago (Old rent, then Amit paid
/// me back), and since then Priya's lunch (not mine), my coffee (only mine) and
/// Amit paying Priya.
Future<String> seedSettledThenNewFlat(ProviderContainer container) async {
  final groups = container.read(groupsRepositoryProvider);
  final groupId = await groups.createGroup(name: 'Flat', icon: 'home', myName: 'You', otherMembers: ['Amit', 'Priya']);
  final members = await memberIdsByName(container, groupId);
  final now = DateTime.now();
  await addEqualExpense(container, groupId, paidBy: members['You']!, totalMinor: 20000, sharedBy: [members['You']!, members['Amit']!], note: 'Old rent', occurredAt: now.subtract(const Duration(days: 20)));
  await groups.addSettlement(groupId: groupId, fromMemberId: members['Amit']!, toMemberId: members['You']!, amountMinor: 10000, occurredAt: now.subtract(const Duration(days: 19)));
  await addEqualExpense(container, groupId, paidBy: members['Priya']!, totalMinor: 6000, sharedBy: [members['Priya']!], note: "Priya's lunch");
  await addEqualExpense(container, groupId, paidBy: members['You']!, totalMinor: 3000, sharedBy: [members['You']!], note: 'My coffee');
  await groups.addSettlement(groupId: groupId, fromMemberId: members['Amit']!, toMemberId: members['Priya']!, amountMinor: 2000, note: 'via GPay');
  return groupId;
}

/// Saves a monthly group expense [name] split equally, starting next month.
Future<String> addRepeatingExpense(ProviderContainer container, String groupId, String name) async {
  final members = await container.read(groupsRepositoryProvider).getMembers(groupId);
  final template = GroupExpenseTemplate(method: SplitMethod.equal, paidByMemberId: members.firstWhere((member) => member.isMe).id, inputs: [for (final member in members) SplitInput(memberId: member.id)]);
  final start = DateTime.now().add(const Duration(days: 40));
  return container.read(recurringRepositoryProvider).saveRule(GroupRecurringRepository.asGroupRule(
    RecurringRepository.newRule(name: name, kind: 'expense', amountMinor: 120000, frequency: RecurrenceFrequency.monthly, dayOfMonth: start.day, startDate: start),
    groupId: groupId,
    template: template,
  ));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('an empty group still shows its notes, which open settings', (tester) async {
    final container = await createContainer();
    final groupId = (await tester.runAsync(() async {
      final groups = container.read(groupsRepositoryProvider);
      final groupId = await groups.createGroup(name: 'Flat', icon: 'home', myName: 'You', otherMembers: ['Amit']);
      await groups.updateGroup(GroupsCompanion(id: Value(groupId), notes: const Value('  Rent is due on the 5th  ')));
      return groupId;
    }))!;
    await openAppAt(tester, container, '/groups/$groupId?tab=expenses');

    expect(find.text('Rent is due on the 5th'), findsOneWidget, reason: 'notes are trimmed');
    expect(find.byType(EmptyState), findsOneWidget);
    await tapVisible(tester, find.text('Rent is due on the 5th'));
    expect(find.byType(GroupSettingsScreen), findsOneWidget);
    await leaveApp(tester);
  });

  testWidgets('after a settle-up, older rows fold behind the divider and the filters pick rows', (tester) async {
    final container = await createContainer();
    final groupId = (await tester.runAsync(() => seedSettledThenNewFlat(container)))!;
    await openAppAt(tester, container, '/groups/$groupId?tab=expenses');

    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Unsettled')).selected, isTrue, reason: 'a settled-up group starts on Unsettled');
    expect(find.text('Old rent'), findsNothing);
    expect(find.text('not involved'), findsNWidgets(2), reason: "Priya's lunch and Amit paying Priya");
    expect(find.text('Amit paid Priya'), findsOneWidget);
    expect(find.textContaining('· via GPay'), findsOneWidget);
    expect(find.text('you paid'), findsOneWidget, reason: 'my coffee was only my share');

    await tapVisible(tester, find.text('Show 2 older entries'));
    expect(find.text('Old rent'), findsOneWidget);
    await tapVisible(tester, find.text('Hide older entries'));
    expect(find.text('Old rent'), findsNothing);

    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Mine'));
    expect(find.text("Priya's lunch"), findsNothing);
    expect(find.text('Amit paid Priya'), findsNothing);
    expect(find.text('My coffee'), findsOneWidget);

    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'All'));
    expect(find.text("Priya's lunch"), findsOneWidget);

    await tapVisible(tester, find.text('My coffee'));
    expect(find.byType(ExpenseEditorScreen), findsOneWidget);
    await leaveApp(tester);
  });

  testWidgets('notes sit above the rows, and a fully settled group says so under Unsettled', (tester) async {
    final container = await createContainer();
    final groupId = (await tester.runAsync(() async {
      final groups = container.read(groupsRepositoryProvider);
      final groupId = await groups.createGroup(name: 'Flat', icon: 'home', myName: 'You', otherMembers: ['Amit', 'Priya']);
      final members = await memberIdsByName(container, groupId);
      await groups.updateGroup(GroupsCompanion(id: Value(groupId), notes: const Value('Wifi is in Amit\'s name')));
      await addEqualExpense(container, groupId, paidBy: members['You']!, totalMinor: 10000, sharedBy: [members['You']!, members['Amit']!], note: 'Groceries', occurredAt: DateTime.now().subtract(const Duration(days: 3)));
      await groups.addSettlement(groupId: groupId, fromMemberId: members['Amit']!, toMemberId: members['You']!, amountMinor: 5000);
      return groupId;
    }))!;
    await openAppAt(tester, container, '/groups/$groupId?tab=expenses');

    expect(tester.getTopLeft(find.text("Wifi is in Amit's name")).dy, lessThan(tester.getTopLeft(find.widgetWithText(ChoiceChip, 'All')).dy));
    expect(find.text('All settled up. New expenses will show here.'), findsOneWidget, reason: 'Amit paid me back, so every row is before the settle-up');
    expect(find.text('Groceries'), findsNothing);

    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'All'));
    expect(find.text('Groceries'), findsOneWidget, reason: 'All shows the settled rows under the divider');
    await leaveApp(tester);
  });

  testWidgets('Mine says so when nothing involves me', (tester) async {
    final container = await createContainer();
    final groupId = (await tester.runAsync(() async {
      final groupId = await container.read(groupsRepositoryProvider).createGroup(name: 'Trip', icon: 'flight', myName: 'You', otherMembers: ['Amit', 'Priya']);
      final members = await memberIdsByName(container, groupId);
      await addEqualExpense(container, groupId, paidBy: members['Priya']!, totalMinor: 4000, sharedBy: [members['Amit']!, members['Priya']!], note: 'Their movie');
      return groupId;
    }))!;
    await openAppAt(tester, container, '/groups/$groupId?tab=expenses');

    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Mine'));
    expect(find.text('Nothing involving you yet.'), findsOneWidget);
    expect(find.text('Their movie'), findsNothing);
    await leaveApp(tester);
  });

  testWidgets('repeating expenses list active ones first, then a Paused section', (tester) async {
    final container = await createContainer();
    final (groupId, wifiId) = (await tester.runAsync(() async {
      final groupId = await seedGroupOwingMe(container, 'Flat', 20000);
      await addRepeatingExpense(container, groupId, 'Maid');
      final wifiId = await addRepeatingExpense(container, groupId, 'Wifi');
      await container.read(recurringRepositoryProvider).setPaused(wifiId, true, now: DateTime.now());
      return (groupId, wifiId);
    }))!;
    await openAppAt(tester, container, '/groups/$groupId?tab=expenses');

    expect(find.text('Repeating'), findsOneWidget);
    final pausedHeader = find.byType(SectionHeader);
    expect(pausedHeader, findsOneWidget, reason: 'active rules need no label');
    expect(tester.getTopLeft(pausedHeader).dy, lessThan(tester.getTopLeft(find.byKey(ValueKey('group.recurring.$wifiId'))).dy));
    expect(tester.getTopLeft(find.text('Maid')).dy, lessThan(tester.getTopLeft(pausedHeader).dy));
    await leaveApp(tester);
  });
}

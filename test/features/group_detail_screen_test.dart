import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/features/expense_editor/expense_editor_screen.dart';
import 'package:hisab/features/groups/activity_screen.dart';
import 'package:hisab/features/groups/group_detail_screen.dart';
import 'package:hisab/features/groups/group_settings_screen.dart';
import 'package:hisab/features/groups/group_totals_screen.dart';
import 'package:hisab/features/groups/groups_screen.dart';
import 'package:hisab/features/shell/router.dart';

import '../support/app_harness.dart' show settle;
import '../support/group_harness.dart';

/// Opens the group's share options from the app bar and taps [option].
Future<void> shareOption(WidgetTester tester, String option) async {
  await tapVisible(tester, find.byTooltip('Share summary'));
  await tapVisible(tester, find.text(option));
}

/// Opens the group's overflow menu and taps [item].
Future<void> menuItem(WidgetTester tester, String item) async {
  await tapVisible(tester, find.byType(PopupMenuButton<String>));
  await tapVisible(tester, find.text(item).last);
}

/// A group of me and [otherMembers] with no expenses, opened on [tab].
Future<(ProviderContainer, String, FakeOutsideWorld)> openEmptyGroup(WidgetTester tester, {List<String> otherMembers = const ['Amit'], String tab = 'balances'}) async {
  final world = FakeOutsideWorld();
  final container = await createContainer(overrides: world.overrides);
  final groupId = (await tester.runAsync(() => container.read(groupsRepositoryProvider).createGroup(name: 'Book club', icon: 'school', myName: 'You', otherMembers: otherMembers)))!;
  await openAppAt(tester, container, '/groups/$groupId?tab=$tab');
  return (container, groupId, world);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('the ?tab= query picks the first tab', () {
    expect([for (final tab in [null, 'balances', 'members', 'nonsense']) groupDetailInitialTab(tab)], [0, 1, 2, 0]);
  });

  testWidgets('the share menu shares the summary, copies it, and exports a CSV', (tester) async {
    final (_, _, world) = await openBalances(tester);
    world.fakeClipboard(tester);

    await shareOption(tester, 'Share balances summary');
    expect(world.sharedTexts.single, contains('Goa'));

    await shareOption(tester, 'Copy as text');
    expect(world.copiedTexts.single, world.sharedTexts.single, reason: 'the copied text is the same summary');
    expect(find.text('Copied'), findsOneWidget);

    await shareOption(tester, 'Export as CSV');
    expect(world.exportedFiles.single, endsWith('.csv'));

    world.exportThrows = true;
    await shareOption(tester, 'Export as CSV');
    expect(find.text("Couldn't export the CSV"), findsOneWidget);
    await leaveApp(tester);
  });

  testWidgets('remind everyone shares one message and logs a reminder per debtor, unless dismissed', (tester) async {
    final (container, groupId, world) = await openBalances(tester);

    world.shareCompletes = false;
    await shareOption(tester, 'Remind everyone who owes you');
    expect(world.sharedTexts.single, contains('Amit'));
    expect((await savedDetail(tester, container, groupId)).lastRemindedAt, isEmpty, reason: 'a dismissed share is not a reminder');

    world.shareCompletes = true;
    await shareOption(tester, 'Remind everyone who owes you');
    final members = (await tester.runAsync(() => memberIdsByName(container, groupId)))!;
    expect((await savedDetail(tester, container, groupId)).lastRemindedAt.keys, [members['Amit']], reason: 'only Amit owes me; I owe Priya');
    await leaveApp(tester);
  });

  testWidgets('a settled group offers to share the summary anyway, and no Remind everyone', (tester) async {
    final (_, _, world) = await openEmptyGroup(tester);

    expect(find.text('Everyone is settled up. Nothing to remind or pay.'), findsOneWidget);
    await tapVisible(tester, find.text('Share the summary anyway'));
    expect(world.sharedTexts.single, contains('Book club'));

    await tapVisible(tester, find.byTooltip('Share summary'));
    expect(find.text('Remind everyone who owes you'), findsNothing);
    await leaveApp(tester);
  });

  testWidgets('the menu opens activity and settings', (tester) async {
    await openBalances(tester);

    await menuItem(tester, 'Activity');
    expect(find.byType(ActivityScreen), findsOneWidget);
    appRouter.pop();
    await settle(tester);

    await menuItem(tester, 'Group settings');
    expect(find.byType(GroupSettingsScreen), findsOneWidget);
    await leaveApp(tester);
  });

  testWidgets('archiving shows a banner without Add expense, and both the banner and menu unarchive', (tester) async {
    final (container, groupId, _) = await openBalances(tester);
    Future<bool> isArchived() async => (await savedDetail(tester, container, groupId)).group.archivedAt != null;

    await menuItem(tester, 'Archive group');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Archive'));
    expect(await isArchived(), isTrue);
    expect(find.text('This group is archived. Unarchive it to add expenses.'), findsOneWidget);
    expect(find.text('Add expense'), findsNothing);

    await tapVisible(tester, find.widgetWithText(TextButton, 'Unarchive'));
    expect(await isArchived(), isFalse);

    await tester.runAsync(() => container.read(groupsRepositoryProvider).archiveGroup(groupId));
    await settle(tester);
    await menuItem(tester, 'Unarchive');
    expect(await isArchived(), isFalse);
    await leaveApp(tester);
  });

  testWidgets('a group I left says so in the banner', (tester) async {
    final container = await createContainer();
    final groupId = (await tester.runAsync(() async {
      final groupId = await container.read(groupsRepositoryProvider).createGroup(name: 'Old flat', icon: 'home', myName: 'You', otherMembers: ['Amit']);
      await container.read(groupsRepositoryProvider).leaveGroup(groupId);
      return groupId;
    }))!;
    await openAppAt(tester, container, '/groups/$groupId');
    expect(find.text('You left this group. Its history stays here.'), findsOneWidget);
    await leaveApp(tester);
  });

  testWidgets('deleting from the menu goes back to the groups list', (tester) async {
    final container = await createContainer();
    final groupId = (await tester.runAsync(() => seedSettleUpGroup(container)))!;
    await openAppAt(tester, container, '/groups');
    appRouter.push('/groups/$groupId');
    await settle(tester);

    await menuItem(tester, 'Delete group');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Delete'));
    expect(find.byType(GroupsScreen), findsOneWidget);
    expect(find.byType(GroupDetailScreen), findsNothing);
    expect(await tester.runAsync(() => container.read(groupsRepositoryProvider).getGroup(groupId)), isNull);
    await leaveApp(tester);
  });

  testWidgets('Add expense needs a second member, then opens the editor for the group', (tester) async {
    final (container, groupId, _) = await openEmptyGroup(tester, otherMembers: const []);

    await tapVisible(tester, find.text('Add expense'));
    expect(find.text('Add at least one more member first'), findsOneWidget);

    await tester.runAsync(() => container.read(groupsRepositoryProvider).addMember(groupId, 'Amit'));
    await settle(tester);
    await tapVisible(tester, find.text('Add expense'));
    expect(find.byType(ExpenseEditorScreen), findsOneWidget);
    await leaveApp(tester);
  });

  testWidgets('the totals card opens the group totals screen', (tester) async {
    await openBalances(tester);

    await tapVisible(tester, find.byKey(kGroupTotalsCardKey));
    expect(find.byType(GroupTotalsScreen), findsOneWidget);
    await leaveApp(tester);
  });

  testWidgets('a payment on the expenses tab opens it for editing', (tester) async {
    final (container, groupId, _) = await openBalances(tester, tab: 'expenses');
    final members = (await tester.runAsync(() => memberIdsByName(container, groupId)))!;
    await tester.runAsync(() => container.read(groupsRepositoryProvider).addSettlement(groupId: groupId, fromMemberId: members['Amit']!, toMemberId: members['You']!, amountMinor: 5000));
    await settle(tester);

    await tapVisible(tester, find.textContaining('· Cash'));
    expect(find.text('Edit payment'), findsOneWidget);
    await leaveApp(tester);
  });

  testWidgets('the members tab shows contacts, adds and edits members, and removes only settled ones', (tester) async {
    final (container, groupId, _) = await openBalances(tester, tab: 'members');
    Future<Map<String, String>> members() async => (await tester.runAsync(() => memberIdsByName(container, groupId)))!;

    expect(find.text('98765 43210 · amit@upi'), findsOneWidget);
    expect(find.text('priya@upi'), findsOneWidget);

    await tapVisible(tester, find.byTooltip('Remove Amit?'));
    expect(find.text("Settle this member's balance before removing them"), findsOneWidget);
    expect(await members(), contains('Amit'));

    await tapVisible(tester, find.text('Add member'));
    await tester.enterText(find.widgetWithText(TextField, 'Member name'), 'Rohan');
    await settle(tester);
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save'));
    expect(await members(), contains('Rohan'));

    await tapVisible(tester, find.text('Rohan'));
    expect(find.text('Edit member'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Member name'), 'Rohan Mehta');
    await settle(tester);
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save'));
    expect(await members(), contains('Rohan Mehta'));

    await tapVisible(tester, find.text('Rohan Mehta'));
    await tester.tapAt(const Offset(20, 20));
    await settle(tester);
    expect(await members(), contains('Rohan Mehta'), reason: 'closing the sheet changes nothing');

    await tapVisible(tester, find.byTooltip('Remove Rohan Mehta?'));
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Remove'));
    expect(await members(), isNot(contains('Rohan Mehta')));
    await leaveApp(tester);
  });
}

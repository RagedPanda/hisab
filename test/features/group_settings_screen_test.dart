import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/groups/group_form.dart';
import 'package:hisab/features/groups/groups_screen.dart';
import 'package:hisab/features/shell/router.dart';

import '../support/app_harness.dart' show settle;
import '../support/group_harness.dart';

/// A fresh group with Amit, opened on its settings page.
Future<(ProviderContainer, String)> openSettings(WidgetTester tester) async {
  final container = await createContainer();
  final groupId = (await tester.runAsync(() => container.read(groupsRepositoryProvider).createGroup(name: 'Flat', icon: 'home', myName: 'You', otherMembers: ['Amit'])))!;
  await openAppAt(tester, container, '/groups/$groupId/settings');
  return (container, groupId);
}

Future<Group> savedGroup(WidgetTester tester, ProviderContainer container, String groupId) async => (await savedGroupOrNull(tester, container, groupId))!;

Future<double> memberWeight(WidgetTester tester, ProviderContainer container, String groupId, String name) async =>
    (await tester.runAsync(() => container.read(groupsRepositoryProvider).getMembers(groupId)))!.firstWhere((member) => member.name == name).weight;

Future<Group?> savedGroupOrNull(WidgetTester tester, ProviderContainer container, String groupId) async =>
    await tester.runAsync<Group?>(() => container.read(groupsRepositoryProvider).getGroup(groupId));

/// Types [text] into the open text prompt and saves it.
Future<void> answerPrompt(WidgetTester tester, String text) async {
  await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), text);
  await tester.tap(find.widgetWithText(FilledButton, 'Save'));
  await settle(tester);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('renaming the group saves the new name, and cancelling keeps the old one', (tester) async {
    final (container, groupId) = await openSettings(tester);

    await tapVisible(tester, find.text('Group name'));
    await answerPrompt(tester, 'Indiranagar flat');
    expect((await savedGroup(tester, container, groupId)).name, 'Indiranagar flat');
    expect(find.text('Indiranagar flat'), findsOneWidget);

    await tapVisible(tester, find.text('Group name'));
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await settle(tester);
    expect((await savedGroup(tester, container, groupId)).name, 'Indiranagar flat');
    await leaveApp(tester);
  });

  testWidgets('picking a type keeps a chosen icon, and an icon can be picked directly', (tester) async {
    final (container, groupId) = await openSettings(tester);

    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Trip'));
    final retyped = await savedGroup(tester, container, groupId);
    expect(retyped.type, 'trip');
    expect(retyped.icon, 'home', reason: 'home was picked for an "other" group, so the new type does not replace it');

    final iconChips = find.descendant(of: find.byType(GroupIconPicker), matching: find.byType(ChoiceChip));
    await tapVisible(tester, iconChips.at(groupIcons.indexOf('school')));
    expect((await savedGroup(tester, container, groupId)).icon, 'school');
    await leaveApp(tester);
  });

  testWidgets('a shares default split shows per-member steppers that save the weight', (tester) async {
    final (container, groupId) = await openSettings(tester);
    expect(find.text('Shares per member'), findsNothing);

    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Shares / ratio'));
    expect((await savedGroup(tester, container, groupId)).defaultSplitMethod, 'shares');
    expect(find.text('Shares per member'), findsOneWidget);

    await tapVisible(tester, find.byTooltip('More shares for Amit'));
    expect(await memberWeight(tester, container, groupId, 'Amit'), 1.5);
    expect(find.text('1.5 shares'), findsOneWidget);

    await tapVisible(tester, find.byTooltip('Fewer shares for Amit'));
    await tapVisible(tester, find.byTooltip('Fewer shares for Amit'));
    expect(await memberWeight(tester, container, groupId, 'Amit'), 0.5);
    final lessButton = find.ancestor(of: find.byTooltip('Fewer shares for Amit'), matching: find.byType(IconButton));
    expect(tester.widget<IconButton>(lessButton.first).onPressed, isNull, reason: 'the floor weight cannot go lower');
    await leaveApp(tester);
  });

  testWidgets('simplify debts can be turned off, and says how many repayments it saves', (tester) async {
    final container = await createContainer();
    final groupId = (await tester.runAsync(() async {
      final groupId = await container.read(groupsRepositoryProvider).createGroup(name: 'Trip', icon: 'flight', myName: 'You', otherMembers: ['Amit', 'Priya']);
      final members = await memberIdsByName(container, groupId);
      // Amit owes me and Priya owes Amit: simplified, Priya pays me once.
      await addEqualExpense(container, groupId, paidBy: members['You']!, totalMinor: 10000, sharedBy: [members['Amit']!]);
      await addEqualExpense(container, groupId, paidBy: members['Amit']!, totalMinor: 10000, sharedBy: [members['Priya']!]);
      return groupId;
    }))!;
    await openAppAt(tester, container, '/groups/$groupId/settings');
    expect(find.text('Saves 1 repayment right now'), findsOneWidget);

    await tapVisible(tester, find.byType(SwitchListTile));
    expect((await savedGroup(tester, container, groupId)).simplifyDebts, isFalse);
    await leaveApp(tester);
  });

  testWidgets('the currency label is picked from the list, typed, or reset to the app default', (tester) async {
    final (container, groupId) = await openSettings(tester);

    await tapVisible(tester, find.text('Same as app (₹)'));
    await tapVisible(tester, find.text(r'$  ·  USD'));
    expect((await savedGroup(tester, container, groupId)).currencyLabel, r'$');
    expect(find.text(r'$'), findsOneWidget, reason: 'the tile shows the chosen symbol');

    await tapVisible(tester, find.text(r'$'));
    await tapVisible(tester, find.text('Other symbol'));
    await answerPrompt(tester, 'AED');
    expect((await savedGroup(tester, container, groupId)).currencyLabel, 'AED');

    await tapVisible(tester, find.text('AED'));
    await tapVisible(tester, find.text('Same as app (₹)'));
    expect((await savedGroup(tester, container, groupId)).currencyLabel, isNull);
    await leaveApp(tester);
  });

  testWidgets('a group note is added from the notes tile', (tester) async {
    final (container, groupId) = await openSettings(tester);

    await tapVisible(tester, find.text('Add a note for this group'));
    await answerPrompt(tester, 'Rent is due on the 5th');
    expect((await savedGroup(tester, container, groupId)).notes, 'Rent is due on the 5th');
    expect(find.text('Rent is due on the 5th'), findsOneWidget);
    await leaveApp(tester);
  });

  testWidgets('archiving asks first, and the same tile then unarchives', (tester) async {
    final (container, groupId) = await openSettings(tester);

    await tapVisible(tester, find.text('Archive group'));
    await tester.tap(find.widgetWithText(FilledButton, 'Archive'));
    await settle(tester);
    expect((await savedGroup(tester, container, groupId)).archivedAt, isNotNull);

    await tapVisible(tester, find.text('Unarchive'));
    expect((await savedGroup(tester, container, groupId)).archivedAt, isNull);
    await leaveApp(tester);
  });

  testWidgets('leaving is refused while I am owed, and allowed once settled', (tester) async {
    final container = await createContainer();
    final groupId = (await tester.runAsync(() => seedGroupOwingMe(container, 'Flat', 20000)))!;
    final emptyGroupId = (await tester.runAsync(() => container.read(groupsRepositoryProvider).createGroup(name: 'Book club', icon: 'school', myName: 'You', otherMembers: ['Amit'])))!;
    await openAppAt(tester, container, '/groups/$groupId/settings');

    await tapVisible(tester, find.text('Leave group'));
    expect(find.text('Settle up first. You can leave once nobody owes you and you owe nobody.'), findsOneWidget);

    appRouter.go('/groups/$emptyGroupId/settings');
    await settle(tester);
    await tapVisible(tester, find.text('Leave group'));
    await tester.tap(find.widgetWithText(FilledButton, 'Leave'));
    await settle(tester);
    final detail = (await tester.runAsync(() => container.read(groupsRepositoryProvider).getGroupDetail(emptyGroupId)))!;
    expect(detail.me, isNull, reason: 'I am no longer a member');
    expect(find.text('Leave group'), findsNothing, reason: 'there is nothing left to leave');
    await leaveApp(tester);
  });

  testWidgets('deleting the group from settings goes back to the groups list', (tester) async {
    final (container, groupId) = await openSettings(tester);

    await tapVisible(tester, find.text('Delete group'));
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(tester);
    expect(await savedGroupOrNull(tester, container, groupId), isNull);
    expect(find.byType(GroupsScreen), findsOneWidget);
    await leaveApp(tester);
  });
}

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/domain/split/group_activity.dart';
import 'package:hisab/features/groups/activity_screen.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:hisab/features/shell/widgets/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/group_harness.dart' show addEqualExpense, leaveApp, memberIdsByName, openAppAt, tapVisible;

/// Builds a group whose log has every kind of row, with long names so the
/// narrowest phone width is exercised.
Future<String> seedActivity(ProviderContainer container) async {
  final groups = container.read(groupsRepositoryProvider);
  final groupId = await groups.createGroup(name: 'Goa trip with college friends', icon: 'flight', myName: 'You', otherMembers: ['Rahul Srivastava', 'Priyanka Chaturvedi']);
  final members = await groups.getMembers(groupId);
  final me = members.firstWhere((member) => member.isMe).id;
  final rahul = members.firstWhere((member) => member.name.startsWith('Rahul')).id;
  final priya = members.firstWhere((member) => member.name.startsWith('Priyanka')).id;
  Future<void> expense(String id, String note, int total, {List<(String, int)> payers = const []}) => groups.saveGroupExpense(
        EntriesRepository.newExpense(id: id, amountMinor: total, occurredAt: DateTime.now(), note: note, groupId: groupId, paidByMemberId: me, splitMethod: 'equal'),
        splits: [for (final member in [me, rahul, priya]) SplitsCompanion.insert(id: newId(), entryId: id, memberId: member, amountMinor: total ~/ 3)],
        payers: [for (final (member, amount) in payers) EntryPayersCompanion.insert(id: newId(), entryId: id, memberId: member, amountMinor: amount)],
      );
  await expense('villa', 'Villa near Anjuna beach', 900000);
  await expense('villa', 'Villa near Anjuna beach for two nights', 9600000, payers: [(me, 6000000), (rahul, 3000000), (priya, 600000)]);
  await expense('scooter', 'Scooter rent for the whole week', 240000);
  await groups.deleteGroupExpense('scooter');
  final paymentId = await groups.addSettlement(groupId: groupId, fromMemberId: priya, toMemberId: rahul, amountMinor: 100000);
  await groups.updateSettlement(id: paymentId, fromMemberId: priya, toMemberId: rahul, amountMinor: 120000, occurredAt: DateTime.now(), note: 'GPay', method: 'upi');
  await groups.deleteSettlement(paymentId);
  final flatId = await groups.createGroup(name: 'Flat share in Indiranagar', icon: 'home', myName: 'You', otherMembers: ['Amit']);
  await groups.deleteGroup(flatId);
  return groupId;
}

/// An app container on a fresh in-memory database, disposed after the test.
Future<ProviderContainer> createContainer() async {
  SharedPreferences.setMockInitialValues({'onboarded': true, 'currencyCode': 'INR'});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    databaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory())),
  ]);
  addTearDown(container.dispose);
  return container;
}

/// Pumps fixed frames; text fields and snackbars keep pumpAndSettle busy.
Future<void> settle(WidgetTester tester) async {
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('deleting a group offers an Undo that times out and brings the group back', (tester) async {
    final container = await createContainer();
    final groups = container.read(groupsRepositoryProvider);
    final groupId = (await tester.runAsync(() => groups.createGroup(name: 'Book club', icon: 'book', myName: 'You', otherMembers: ['Rahul'])))!;
    appRouter.go('/groups');
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
    await settle(tester);
    appRouter.push('/groups/$groupId');
    await settle(tester);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await settle(tester);
    await tester.tap(find.text('Delete group'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete').hitTestable().first);
    await settle(tester);
    expect(find.text('Group deleted'), findsOneWidget);
    expect(tester.widget<SnackBar>(find.byType(SnackBar)).persist, isFalse, reason: 'the Undo must time out');
    expect(await tester.runAsync(() => groups.getSummaries()), isEmpty);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    final summaries = (await tester.runAsync(() => groups.getSummaries()))!;
    expect(summaries.map((summary) => summary.group.id), [groupId]);
    final log = (await tester.runAsync(() => groups.getActivityFeed()))!.activities;
    expect([for (final activity in log) (activity.subject, activity.action)], [(ActivitySubject.group, ActivityAction.restored), (ActivitySubject.group, ActivityAction.deleted)]);
    appRouter.go('/home');
    await tester.pump();
  });

  testWidgets('a group expense deleted in the editor offers an Undo that times out, and Restore shows at once (#49)', (tester) async {
    final container = await createContainer();
    final groups = container.read(groupsRepositoryProvider);
    final groupId = (await tester.runAsync(() async {
      final groupId = await groups.createGroup(name: 'QA Dinner', icon: 'home', myName: 'You', otherMembers: ['Rahul']);
      final members = await groups.getMembers(groupId);
      await groups.saveGroupExpense(
        EntriesRepository.newExpense(id: 'dinner', amountMinor: 120000, occurredAt: DateTime.now(), note: 'Dinner', groupId: groupId, paidByMemberId: members.first.id, splitMethod: 'equal'),
        splits: [for (final member in members) SplitsCompanion.insert(id: newId(), entryId: 'dinner', memberId: member.id, amountMinor: 60000)],
      );
      return groupId;
    }))!;
    appRouter.go('/groups/$groupId');
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
    await settle(tester);
    appRouter.push('/entry?id=dinner');
    await settle(tester);

    await tester.tap(find.byTooltip('Delete'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete').hitTestable().first);
    await settle(tester);
    expect(find.text('Expense deleted'), findsOneWidget);
    expect(tester.widget<SnackBar>(find.byType(SnackBar)).persist, isFalse, reason: 'the Undo must time out');

    appRouter.push('/groups/$groupId/activity');
    await settle(tester);
    await tester.tap(find.text('Restore').first);
    await settle(tester);
    expect(find.text('Expense restored'), findsOneWidget, reason: 'the restore message replaces the stale Undo instead of queueing behind it');
    expect(find.text('Expense deleted'), findsNothing);
    appRouter.go('/home');
    await tester.pump();
  });

  testWidgets('activity amounts use each group\'s currency label (#130)', (tester) async {
    final container = await createContainer();
    final groups = container.read(groupsRepositoryProvider);
    Future<String> groupWithRent(String name, String entryId, {String? label}) async {
      final groupId = await groups.createGroup(name: name, icon: 'home', myName: 'You', otherMembers: ['Amit']);
      if (label != null) await groups.setCurrencyLabel((await groups.getGroup(groupId))!, label);
      final members = await groups.getMembers(groupId);
      final me = members.firstWhere((member) => member.isMe).id;
      await groups.saveGroupExpense(
        EntriesRepository.newExpense(id: entryId, amountMinor: 120000, occurredAt: DateTime.now(), note: 'Rent', groupId: groupId, paidByMemberId: me, splitMethod: 'equal'),
        splits: [for (final member in members) SplitsCompanion.insert(id: newId(), entryId: entryId, memberId: member.id, amountMinor: 60000)],
      );
      return groupId;
    }

    final dubaiId = (await tester.runAsync(() => groupWithRent('Dubai flat', 'dubai-rent', label: 'AED')))!;
    await tester.runAsync(() => groupWithRent('Pune flat', 'pune-rent'));

    appRouter.go('/groups/$dubaiId/activity');
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
    await settle(tester);
    expect(find.textContaining('AED 1,200'), findsOneWidget);
    expect(find.textContaining('₹1,200'), findsNothing, reason: 'the AED group must not show the app currency');

    appRouter.go('/activity');
    await settle(tester);
    expect(find.textContaining('AED 1,200'), findsOneWidget);
    expect(find.textContaining('₹1,200'), findsOneWidget, reason: 'a group without a label keeps the app currency');
    appRouter.go('/home');
    await tester.pump();
  });

  for (final locale in ['en', 'hi']) {
    testWidgets('activity screens fit a 360dp phone in $locale', (tester) async {
      final container = await createContainer();
      final groupId = (await tester.runAsync(() => seedActivity(container)))!;
      await container.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: locale));
      await tester.binding.setSurfaceSize(const Size(360, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      appRouter.go('/groups/$groupId/activity');
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
      await settle(tester);
      expect(find.byType(ActivityScreen), findsOneWidget);
      expect(find.byType(ListTile), findsWidgets);

      appRouter.go('/activity');
      await settle(tester);
      expect(find.byType(ListTile), findsWidgets);
      expect(find.byType(TextButton), findsNWidgets(3), reason: 'the scooter, the payment and the deleted group each offer Restore');
      expect(tester.takeException(), isNull);
      appRouter.go('/home');
      await tester.pump();
    });
  }

  testWidgets('with no groups the activity screen says nothing has happened yet', (tester) async {
    final container = await createContainer();
    await openAppAt(tester, container, '/activity');
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('No activity yet'), findsOneWidget);
    await leaveApp(tester);
  });

  testWidgets('a deleted payment and a deleted group can each be restored from the log', (tester) async {
    final container = await createContainer();
    await tester.runAsync(() => seedActivity(container));
    await openAppAt(tester, container, '/activity');
    final groups = container.read(groupsRepositoryProvider);

    final restoreButtons = find.widgetWithText(TextButton, 'Restore');
    final snacks = <String>[];
    while (restoreButtons.evaluate().isNotEmpty) {
      await tapVisible(tester, restoreButtons.first);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await settle(tester);
      snacks.add(tester.widget<Text>(find.descendant(of: find.byType(SnackBar), matching: find.byType(Text)).first).data!);
    }
    expect(snacks, unorderedEquals(['Expense restored', 'Payment restored', 'Group restored']));
    expect((await tester.runAsync(() => groups.watchGroups().first))!.map((group) => group.name), contains('Flat share in Indiranagar'));
    await leaveApp(tester);
  });

  testWidgets('an edit that moves the date or category says from what to what', (tester) async {
    final container = await createContainer();
    final groupId = (await tester.runAsync(() async {
      final groups = container.read(groupsRepositoryProvider);
      final groupId = await groups.createGroup(name: 'Flat', icon: 'home', myName: 'You', otherMembers: ['Amit']);
      final members = await memberIdsByName(container, groupId);
      await addEqualExpense(container, groupId, paidBy: members['You']!, totalMinor: 10000, note: '', occurredAt: DateTime(2026, 10, 1));
      final entry = (await groups.getGroupDetail(groupId))!.entries.single.$1;
      final category = (await container.read(databaseProvider).select(container.read(databaseProvider).categories).get()).first;
      await groups.saveGroupExpense(
        EntriesRepository.newExpense(id: entry.id, amountMinor: 10000, occurredAt: DateTime(2026, 10, 3), note: '', groupId: groupId, paidByMemberId: members['You']!, splitMethod: 'equal', categoryId: category.id),
        splits: [for (final memberId in members.values) SplitsCompanion.insert(id: newId(), entryId: entry.id, memberId: memberId, amountMinor: 5000)],
      );
      return groupId;
    }))!;
    await openAppAt(tester, container, '/groups/$groupId/activity');

    expect(find.textContaining('Date: 1 Oct'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^Category: Expense → \S')), findsOneWidget, reason: 'an expense with no category is called Expense');
    await leaveApp(tester);
  });
}

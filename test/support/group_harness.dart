import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_harness.dart' show settle;

/// An app container on a fresh in-memory database, disposed after the test,
/// with [overrides] on top of the test database and preferences.
Future<ProviderContainer> createContainer({List<Override> overrides = const []}) async {
  SharedPreferences.setMockInitialValues({'onboarded': true, 'currencyCode': 'INR'});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    databaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory())),
    ...overrides,
  ]);
  addTearDown(container.dispose);
  return container;
}

/// A group where I paid [totalMinor] split equally with one other member, so
/// I am owed half of it, labelled [label] (null: the app currency).
Future<String> seedGroupOwingMe(ProviderContainer container, String name, int totalMinor, {String? label}) async {
  final groups = container.read(groupsRepositoryProvider);
  final groupId = await groups.createGroup(name: name, icon: 'home', myName: 'You', otherMembers: ['Amit']);
  if (label != null) await groups.setCurrencyLabel((await groups.getGroup(groupId))!, label);
  final members = await groups.getMembers(groupId);
  final me = members.firstWhere((member) => member.isMe).id;
  await addEqualExpense(container, groupId, paidBy: me, totalMinor: totalMinor, note: 'Rent');
  return groupId;
}

/// Saves an expense of [totalMinor] paid by [paidBy] and split equally across
/// [sharedBy] (null: the group's current members).
Future<void> addEqualExpense(ProviderContainer container, String groupId, {required String paidBy, required int totalMinor, List<String>? sharedBy, String note = 'Dinner'}) async {
  final groups = container.read(groupsRepositoryProvider);
  final memberIds = sharedBy ?? [for (final member in await groups.getMembers(groupId)) member.id];
  final entryId = newId();
  await groups.saveGroupExpense(
    EntriesRepository.newExpense(id: entryId, amountMinor: totalMinor, occurredAt: DateTime.now(), note: note, groupId: groupId, paidByMemberId: paidBy, splitMethod: 'equal'),
    splits: [for (final memberId in memberIds) SplitsCompanion.insert(id: newId(), entryId: entryId, memberId: memberId, amountMinor: totalMinor ~/ memberIds.length)],
  );
}

/// Member ids of [groupId] by name, so tests can say `members['Amit']`.
Future<Map<String, String>> memberIdsByName(ProviderContainer container, String groupId) async =>
    {for (final member in await container.read(groupsRepositoryProvider).getMembers(groupId)) member.name: member.id};

/// Opens [location] in the real app on a phone-sized surface.
Future<void> openAppAt(WidgetTester tester, ProviderContainer container, String location, {Size size = const Size(430, 932)}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  appRouter.go(location);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
  await settle(tester);
}

/// Leaves the router on Home so the next test starts from a clean stack.
Future<void> leaveApp(WidgetTester tester) async {
  appRouter.go('/home');
  await tester.pump();
}

/// Scrolls the page's list until [finder] is built (lazy lists build only what
/// is on screen), brings it into view and taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(finder);
  await settle(tester, 3);
  await tester.tap(finder);
  await settle(tester);
}

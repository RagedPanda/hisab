import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/groups_repository.dart';
import 'package:hisab/features/groups/group_export.dart';
import 'package:hisab/features/groups/settle_up_sheet.dart';
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
/// [sharedBy] (null: the group's current members), dated [occurredAt] (null: now).
Future<void> addEqualExpense(ProviderContainer container, String groupId, {required String paidBy, required int totalMinor, List<String>? sharedBy, String note = 'Dinner', DateTime? occurredAt, String? categoryId}) async {
  final groups = container.read(groupsRepositoryProvider);
  final memberIds = sharedBy ?? [for (final member in await groups.getMembers(groupId)) member.id];
  final entryId = newId();
  await groups.saveGroupExpense(
    EntriesRepository.newExpense(id: entryId, amountMinor: totalMinor, occurredAt: occurredAt ?? DateTime.now(), note: note, groupId: groupId, paidByMemberId: paidBy, splitMethod: 'equal', categoryId: categoryId),
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

/// Scrolls the vertical list on screen until [finder] is built (lazy lists build only what
/// is on screen), brings it into view and taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  final verticalList = find.byWidgetPredicate((widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down).hitTestable();
  if (finder.evaluate().isEmpty) await tester.scrollUntilVisible(finder, 200, scrollable: verticalList.first);
  await tester.ensureVisible(finder);
  await settle(tester, 3);
  await tester.tap(finder);
  await settle(tester);
}

/// Stands in for the share sheet, other apps and CSV export, recording what
/// the app handed them and answering as the test sets.
class FakeOutsideWorld {
  final List<String> sharedTexts = [];
  final List<Uri> launchedUris = [];
  final List<String> exportedFiles = [];
  final List<String> copiedTexts = [];

  /// False: the person dismissed the share sheet.
  bool shareCompletes = true;

  /// False: no app on the phone opened the link.
  bool linkOpens = true;

  /// True: writing the CSV file fails.
  bool exportThrows = false;

  /// Answers clipboard writes, which otherwise never complete in a widget
  /// test, and records the copied text.
  void fakeClipboard(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copiedTexts.add((call.arguments as Map)['text'] as String);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  }

  List<Override> get overrides => [
        textSharerProvider.overrideWithValue((text) async {
          sharedTexts.add(text);
          return shareCompletes;
        }),
        linkLauncherProvider.overrideWithValue((uri) async {
          launchedUris.add(uri);
          return linkOpens;
        }),
        csvFileSharerProvider.overrideWithValue(({required fileName, required csv, required subject}) async {
          if (exportThrows) throw Exception('disk full');
          exportedFiles.add(fileName);
          return true;
        }),
      ];
}

/// "Goa" with simplify off: Amit (phone and UPI ID) owes me ₹150 and I owe
/// Priya (UPI ID only) ₹100, so the Balances tab offers both Remind and Pay.
Future<String> seedSettleUpGroup(ProviderContainer container) async {
  final groups = container.read(groupsRepositoryProvider);
  final groupId = await groups.createGroup(name: 'Goa', icon: 'flight', myName: 'You', otherMembers: ['Amit', 'Priya']);
  await groups.updateGroup(GroupsCompanion(id: Value(groupId), simplifyDebts: const Value(false)));
  final members = await memberIdsByName(container, groupId);
  await groups.editMember(members['Amit']!, name: 'Amit', phone: '98765 43210', upiId: 'amit@upi');
  await groups.editMember(members['Priya']!, name: 'Priya', upiId: 'priya@upi');
  await addEqualExpense(container, groupId, paidBy: members['You']!, totalMinor: 30000, sharedBy: [members['You']!, members['Amit']!], note: 'Villa');
  await addEqualExpense(container, groupId, paidBy: members['Priya']!, totalMinor: 20000, sharedBy: [members['You']!, members['Priya']!], note: 'Scooter');
  return groupId;
}

/// The settle-up group open on [tab] (Balances by default), with the outside
/// world faked.
Future<(ProviderContainer, String, FakeOutsideWorld)> openBalances(WidgetTester tester, {String tab = 'balances'}) async {
  final world = FakeOutsideWorld();
  final container = await createContainer(overrides: world.overrides);
  final groupId = (await tester.runAsync(() => seedSettleUpGroup(container)))!;
  await openAppAt(tester, container, '/groups/$groupId?tab=$tab');
  return (container, groupId, world);
}

Future<GroupDetail> savedDetail(WidgetTester tester, ProviderContainer container, String groupId) async =>
    (await tester.runAsync<GroupDetail?>(() => container.read(groupsRepositoryProvider).getGroupDetail(groupId)))!;

/// Screenshot tour of the group activity screens in every locale and theme.
/// Seeds the log through the groups repository (the same calls the screens
/// make), then only navigates.
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/group_activity_screens_test.dart -d `<device>`
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/features/groups/activity_screen.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:integration_test/integration_test.dart';

import 'harness.dart';

const _configs = [('en', ThemeMode.light), ('en', ThemeMode.dark), ('hi', ThemeMode.light), ('hi', ThemeMode.dark)];

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('group activity screens in every locale and theme', (tester) async {
    final app = await createApp();
    final groupId = await _seedActivity(app);
    await pumpApp(tester, app);

    for (final (locale, mode) in _configs) {
      await app.read(settingsProvider.notifier).update((s) => s.copyWith(localeCode: locale, themeMode: mode));
      final tag = '${locale}_${mode.name}';
      appRouter.go('/groups/$groupId');
      await settle(tester, 10);
      await tapFinder(tester, find.byType(PopupMenuButton<String>), frames: 10);
      await shoot(tester, 'group_menu_$tag');
      await tester.tapAt(const Offset(8, 400));
      await settle(tester, 10);
      appRouter.go('/groups/$groupId/activity');
      await settle(tester, 10);
      expect(find.byType(ActivityScreen), findsOneWidget);
      await shoot(tester, 'group_activity_$tag');
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await settle(tester, 10);
      await shoot(tester, 'group_activity_scrolled_$tag');
      appRouter.go('/groups');
      await settle(tester, 10);
      await shoot(tester, 'groups_list_$tag');
      appRouter.go('/activity');
      await settle(tester, 10);
      await shoot(tester, 'all_activity_$tag');
    }
    appRouter.go('/home');
    await settle(tester, 10);
  });
}

/// Goa trip with every kind of log row: added, edited (amount, payers,
/// shares), deleted (restorable), deleted then restored, and payments.
Future<String> _seedActivity(AppHandle app) async {
  final groups = app.read(groupsRepositoryProvider);
  final groupId = await groups.createGroup(name: 'Goa trip', icon: 'flight', myName: 'You', otherMembers: ['Rahul', 'Priya']);
  final flatId = await groups.createGroup(name: 'Flat', icon: 'home', myName: 'You', otherMembers: ['Amit']);
  final members = await groups.getMembers(groupId);
  final me = members.firstWhere((m) => m.isMe).id;
  final rahul = members.firstWhere((m) => m.name == 'Rahul').id;
  final priya = members.firstWhere((m) => m.name == 'Priya').id;
  Future<void> expense(String id, String note, String payer, int total, List<String> sharers, {List<(String, int)> payers = const []}) => groups.saveGroupExpense(
        EntriesRepository.newExpense(id: id, amountMinor: total, occurredAt: DateTime.now(), note: note, groupId: groupId, paidByMemberId: payer, splitMethod: 'equal'),
        splits: [for (final member in sharers) SplitsCompanion.insert(id: newId(), entryId: id, memberId: member, amountMinor: total ~/ sharers.length)],
        payers: [for (final (member, amount) in payers) EntryPayersCompanion.insert(id: newId(), entryId: id, memberId: member, amountMinor: amount)],
      );

  await expense('villa', 'Villa', me, 900000, [me, rahul, priya]);
  await expense('villa', 'Villa (2 nights)', me, 960000, [me, rahul, priya], payers: [(me, 600000), (rahul, 360000)]);
  await expense('scooter', 'Scooter rent', rahul, 240000, [me, rahul]);
  await groups.deleteGroupExpense('scooter');
  await expense('dinner', 'Dinner at Thalassa', priya, 450000, [me, rahul, priya]);
  await groups.deleteGroupExpense('dinner');
  await groups.restoreGroupExpense('dinner');
  final paymentId = await groups.addSettlement(groupId: groupId, fromMemberId: priya, toMemberId: me, amountMinor: 100000);
  await groups.updateSettlement(id: paymentId, fromMemberId: priya, toMemberId: me, amountMinor: 120000, occurredAt: DateTime.now(), note: 'GPay', method: 'upi');
  final flatMembers = await groups.getMembers(flatId);
  await groups.addSettlement(groupId: flatId, fromMemberId: flatMembers.last.id, toMemberId: flatMembers.first.id, amountMinor: 50000);
  return groupId;
}

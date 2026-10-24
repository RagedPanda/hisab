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
import 'package:hisab/features/groups/activity_screen.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    splits: [
      for (final member in [me, rahul, priya]) SplitsCompanion.insert(id: newId(), entryId: id, memberId: member, amountMinor: total ~/ 3),
    ],
    payers: [for (final (member, amount) in payers) EntryPayersCompanion.insert(id: newId(), entryId: id, memberId: member, amountMinor: amount)],
  );
  await expense('villa', 'Villa near Anjuna beach', 900000);
  await expense('villa', 'Villa near Anjuna beach for two nights', 9600000, payers: [(me, 6000000), (rahul, 3000000), (priya, 600000)]);
  await expense('scooter', 'Scooter rent for the whole week', 240000);
  await groups.deleteGroupExpense('scooter');
  final paymentId = await groups.addSettlement(groupId: groupId, fromMemberId: priya, toMemberId: rahul, amountMinor: 100000);
  await groups.updateSettlement(id: paymentId, fromMemberId: priya, toMemberId: rahul, amountMinor: 120000, occurredAt: DateTime.now(), note: 'GPay', method: 'upi');
  return groupId;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  for (final locale in ['en', 'hi']) {
    testWidgets('activity screens fit a 360dp phone in $locale', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarded': true, 'currencyCode': 'INR'});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), databaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory()))]);
      addTearDown(container.dispose);
      final groupId = (await tester.runAsync(() => seedActivity(container)))!;
      await container.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: locale));
      await tester.binding.setSurfaceSize(const Size(360, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      appRouter.go('/groups/$groupId/activity');
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(ActivityScreen), findsOneWidget);
      expect(find.byType(ListTile), findsWidgets);

      appRouter.go('/activity');
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(ListTile), findsWidgets);
      expect(tester.takeException(), isNull);
      appRouter.go('/home');
      await tester.pump();
    });
  }
}

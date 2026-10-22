import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/data/repositories/groups_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/format.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/features/groups/group_totals_screen.dart';
import 'package:hisab/features/shell/router.dart';

import '../app_flow_test.dart' show settle;

/// Goa trip: Rahul and I paid a 1,000 hotel together (600 + 400) split
/// 500 / 300 / 200, and Priya paid a 300 dinner split equally among three.
Future<String> _seedGoaTrip(AppDatabase db) async {
  final groups = GroupsRepository(db);
  final entries = EntriesRepository(db);
  final groupId = await groups.createGroup(name: 'Goa trip', icon: 'flight', myName: 'Me', otherMembers: const ['Rahul', 'Priya']);
  final members = await groups.getMembers(groupId);
  final me = members.firstWhere((member) => member.isMe).id;
  final rahul = members.firstWhere((member) => member.name == 'Rahul').id;
  final priya = members.firstWhere((member) => member.name == 'Priya').id;
  final now = DateTime.now();
  SplitsCompanion split(String memberId, int amount) => SplitsCompanion.insert(id: newId(), entryId: '', memberId: memberId, amountMinor: amount);
  EntryPayersCompanion payer(String memberId, int amount) => EntryPayersCompanion.insert(id: newId(), entryId: '', memberId: memberId, amountMinor: amount);
  await entries.saveEntry(
    EntriesRepository.newExpense(amountMinor: 100000, occurredAt: now, groupId: groupId, paidByMemberId: me, splitMethod: 'percent', note: 'Hotel'),
    splits: [split(me, 50000), split(rahul, 30000), split(priya, 20000)],
    payers: [payer(me, 60000), payer(rahul, 40000)],
  );
  await entries.saveEntry(
    EntriesRepository.newExpense(amountMinor: 30000, occurredAt: now, groupId: groupId, paidByMemberId: priya, splitMethod: 'equal', note: 'Dinner'),
    splits: [split(me, 10000), split(rahul, 10000), split(priya, 10000)],
  );
  return groupId;
}

/// A member row on the breakdown page, found by its spoken summary.
Finder _memberRow(String label) => find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == label);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('balances tab shows group totals and opens the breakdown page', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    final groupId = (await tester.runAsync(() => _seedGoaTrip(db)))!;
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    await tester.binding.setSurfaceSize(const Size(430, 932));
    appRouter.go('/groups/$groupId');
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
    await settle(tester);
    await tester.tap(find.text('Balances'));
    await settle(tester);

    final card = find.byKey(kGroupTotalsCardKey);
    expect(card, findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('₹1,300')), findsOneWidget);
    // I paid 600 and my share is 500 + 100 = 600, so my balance did not move.
    expect(find.descendant(of: card, matching: find.text('₹600')), findsNWidgets(2));
    expect(find.descendant(of: card, matching: find.text('₹0')), findsOneWidget);

    await tester.tap(card);
    await settle(tester);
    expect(find.text('Group totals'), findsOneWidget);
    expect(find.text('All time'), findsOneWidget);
    expect(find.text('Total group spending'), findsOneWidget);
    expect(find.text('2 expenses'), findsOneWidget);
    expect(find.text('₹1,300'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Paid and share by member'), 200, scrollable: find.byType(Scrollable).last);
    expect(find.text('Paid and share by member'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Priya').last, 200, scrollable: find.byType(Scrollable).last);
    // Rahul paid 400 and owes 300 + 100; Priya paid 300 and owes 200 + 100.
    expect(_memberRow('Rahul: paid ₹400, share ₹400'), findsOneWidget);
    expect(_memberRow('Priya: paid ₹300, share ₹300'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, formatMonthLabel(monthRange(DateTime.now()))));
    await settle(tester);
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'All time')).selected, isFalse);
    expect(find.text('2 expenses'), findsOneWidget);
  });
}

import 'package:drift/drift.dart' show driftRuntimeOptions;
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

import 'package:hisab/features/dashboard/widgets/category_donut.dart';
import 'package:hisab/features/shell/widgets/common.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hisab/core/theme.dart' show kExpenseColor;

import '../support/app_harness.dart' show settle;
import '../support/group_harness.dart' show addEqualExpense, createContainer, leaveApp, memberIdsByName, openAppAt, tapVisible;

/// Goa trip: Rahul and I paid a 1,000 hotel together (600 + 400) split
/// 500 / 300 / 200, and Priya paid a 300 dinner split equally among three.
/// Then I paid Rahul 100 and Priya paid me 40 to settle up.
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
  await groups.addSettlement(groupId: groupId, fromMemberId: me, toMemberId: rahul, amountMinor: 10000, occurredAt: now);
  await groups.addSettlement(groupId: groupId, fromMemberId: priya, toMemberId: me, amountMinor: 4000, occurredAt: now);
  return groupId;
}

/// A member row on the breakdown page, found by its spoken summary.
Finder _memberRow(String label) => find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == label);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('balances tab shows group totals and opens the breakdown page', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true, 'currencyCode': 'INR'});
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
    // The group total and my total share are the two headline figures.
    expect(find.descendant(of: card, matching: find.text('Group total')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('₹1,300')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('Your share')), findsOneWidget);
    // I paid 600 and my share is 500 + 100 = 600; payments then add 100 - 40.
    expect(find.descendant(of: card, matching: find.text('₹600')), findsNWidgets(2));
    expect(find.descendant(of: card, matching: find.text('Payments you made')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('₹100')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('Payments you received')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('₹40')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('+₹60')), findsOneWidget);

    await tester.tap(card);
    await settle(tester);
    expect(find.text('Group totals'), findsOneWidget);
    expect(find.text('All time'), findsOneWidget);
    expect(find.text('Group total'), findsOneWidget);
    expect(find.text('Your share'), findsOneWidget);
    expect(find.text('+₹60'), findsOneWidget);
    expect(find.text('2 expenses'), findsOneWidget);
    expect(find.text('₹1,300'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Paid and share by member'), 200, scrollable: find.byType(Scrollable).last);
    expect(find.text('Paid and share by member'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Priya').last, 200, scrollable: find.byType(Scrollable).last);
    // Rahul paid 400 and owes 300 + 100; Priya paid 300 and owes 200 + 100.
    expect(_memberRow('Rahul: paid ₹400, share ₹400'), findsOneWidget);
    expect(_memberRow('Priya: paid ₹300, share ₹300'), findsOneWidget);

    final monthChip = find.widgetWithText(ChoiceChip, formatMonthLabel(monthRange(DateTime.now())));
    await tester.scrollUntilVisible(monthChip, -200, scrollable: find.byType(Scrollable).last);
    await tester.tap(monthChip);
    await settle(tester);
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'All time')).selected, isFalse);
    expect(find.text('2 expenses'), findsOneWidget);
  });

  testWidgets('the totals page waits for the group, then says when there is nothing to total', (tester) async {
    final container = await createContainer();
    final groupId = (await tester.runAsync(() => container.read(groupsRepositoryProvider).createGroup(name: 'Flat', icon: 'home', myName: 'You', otherMembers: ['Amit'])))!;
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    appRouter.go('/groups/$groupId/totals');
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'the group is still loading');

    await settle(tester);
    expect(find.text('No expenses in this period'), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('Spending by category'), findsNothing);
    await leaveApp(tester);
  });

  testWidgets('a category can be picked from the legend, and a bar shows what that member paid', (tester) async {
    final container = await createContainer();
    final groupId = (await tester.runAsync(() async {
      final groupId = await container.read(groupsRepositoryProvider).createGroup(name: 'Flat', icon: 'home', myName: 'You', otherMembers: ['Priya']);
      final members = await memberIdsByName(container, groupId);
      final database = container.read(databaseProvider);
      final category = (await database.select(database.categories).get()).first;
      await addEqualExpense(container, groupId, paidBy: members['Priya']!, totalMinor: 20000, categoryId: category.id);
      return groupId;
    }))!;
    await openAppAt(tester, container, '/groups/$groupId/totals');

    final net = tester.widget<Text>(find.text('-₹100'));
    expect(net.style?.color, kExpenseColor, reason: 'Priya paid for my half, so I owe more');

    CategoryDonut donut() => tester.widget<CategoryDonut>(find.byType(CategoryDonut));
    final categoryId = (await tester.runAsync(() async {
      final database = container.read(databaseProvider);
      return (await database.select(database.categories).get()).first.id;
    }))!;
    final legendRow = find.descendant(of: find.byType(CategoryDonut), matching: find.byType(InkWell)).last;
    await tapVisible(tester, legendRow);
    expect(donut().selectedId, categoryId);
    await tapVisible(tester, legendRow);
    expect(donut().selectedId, isNull, reason: 'tapping the picked category again clears it');

    final chart = tester.widget<BarChart>(find.byType(BarChart)).data;
    final tooltip = chart.barTouchData.touchTooltipData;
    final tooltips = {
      for (final group in chart.barGroups)
        for (final (rodIndex, rod) in group.barRods.indexed) tooltip.getTooltipItem(group, group.x, rod, rodIndex)!.text,
    };
    expect(tooltips, {'Paid ₹0', 'Share ₹100', 'Paid ₹200'}, reason: 'touching a bar says what it is: I paid nothing, Priya paid 200, each share is 100');
    expect(tooltip.getTooltipColor(chart.barGroups.first), Theme.of(tester.element(find.byType(BarChart))).colorScheme.surfaceContainerHighest);
    await leaveApp(tester);
  });
}

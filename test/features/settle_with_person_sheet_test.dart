import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';

import '../support/app_harness.dart' show settle;
import '../support/group_harness.dart';

Finder inSheet(Finder finder) => find.descendant(of: find.byType(BottomSheet), matching: finder);

/// "Goa" (Amit owes me ₹150, I owe Priya ₹100), plus "Flat" where I owe
/// Amit ₹40 and "Trip" in dollars where Amit owes me $10. Amit has the same
/// email in all three, written differently. Returns the group ids.
Future<({String goa, String flat, String trip})> seedAmitInThreeGroups(ProviderContainer container) async {
  final groups = container.read(groupsRepositoryProvider);
  final goa = await seedSettleUpGroup(container);
  final goaMembers = await memberIdsByName(container, goa);
  await groups.editMember(goaMembers['Amit']!, name: 'Amit', phone: '98765 43210', upiId: 'amit@upi', email: 'amit@x.com');
  Future<String> withAmit(String name, {required bool amitPaid, required int totalMinor, String? label}) async {
    final groupId = await groups.createGroup(name: name, icon: 'home', myName: 'You', otherMembers: ['Amit']);
    if (label != null) await groups.setCurrencyLabel((await groups.getGroup(groupId))!, label);
    final members = await memberIdsByName(container, groupId);
    await groups.editMember(members['Amit']!, name: 'Amit', email: ' Amit@X.com');
    await addEqualExpense(container, groupId, paidBy: members[amitPaid ? 'Amit' : 'You']!, totalMinor: totalMinor);
    return groupId;
  }

  final flat = await withAmit('Flat', amitPaid: true, totalMinor: 8000);
  final trip = await withAmit('Trip', amitPaid: false, totalMinor: 2000, label: r'$');
  return (goa: goa, flat: flat, trip: trip);
}

/// My net balance in each group, by name.
Future<Map<String, int>> myNets(WidgetTester tester, ProviderContainer container) async =>
    {for (final summary in (await tester.runAsync(() => container.read(groupsRepositoryProvider).getSummaries()))!) summary.group.name: summary.myNetMinor};

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('settling with Amit shows this group, then all groups per currency, records one payment per group and undoes them', (tester) async {
    final world = FakeOutsideWorld();
    final container = await createContainer(overrides: world.overrides);
    final ids = (await tester.runAsync(() => seedAmitInThreeGroups(container)))!;
    await openAppAt(tester, container, '/groups/${ids.goa}?tab=balances');
    final netsBefore = await myNets(tester, container);

    await tapVisible(tester, find.text('Amit').first);
    expect(inSheet(find.text('Settle up with Amit')), findsOneWidget);
    expect(inSheet(find.text('This group')), findsOneWidget);
    expect(inSheet(find.text('Goa')), findsOneWidget);
    expect(inSheet(find.text('Flat')), findsNothing, reason: 'this group by default');
    expect(inSheet(find.textContaining('in all')), findsNothing, reason: 'one group has no total to repeat');
    expect(inSheet(find.text('Record 1 payment')), findsOneWidget);
    expect(inSheet(find.text('Pay with UPI')), findsNothing, reason: 'Amit owes me, so there is nothing to pay');

    await tester.tap(inSheet(find.text('All groups')));
    await settle(tester);
    expect(inSheet(find.text('Goa')), findsOneWidget);
    expect(inSheet(find.text('Flat')), findsOneWidget);
    expect(inSheet(find.text('Trip')), findsOneWidget);
    expect(inSheet(find.text('You owe Amit')), findsOneWidget, reason: 'Flat is the one where I owe');
    expect(inSheet(find.text('Amit owes you ₹110 in all')), findsOneWidget, reason: '₹150 owed to me less ₹40 I owe');
    expect(inSheet(find.textContaining(r'$')), findsWidgets, reason: 'dollars are totalled on their own');
    expect(inSheet(find.textContaining('in all')), findsNWidgets(2));

    await tapVisible(tester, inSheet(find.text('Share…')));
    expect(world.sharedTexts.single, allOf(contains('Hi Amit'), contains('Goa: you owe me ₹150'), contains('Flat: I owe you ₹40'), contains('In all, you owe me ₹110.')));

    await tapVisible(tester, inSheet(find.text('Bank')));
    await tapVisible(tester, inSheet(find.text('Record 3 payments')));
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Settled up with Amit in 3 groups'), findsOneWidget);
    final nets = await myNets(tester, container);
    expect((nets['Flat'], nets['Trip']), (0, 0));
    expect(nets['Goa'], -10000, reason: 'only my debt to Priya is left in Goa');
    final goaDetail = await savedDetail(tester, container, ids.goa);
    expect(goaDetail.settlements.single.method, 'bank');
    expect(goaDetail.balances.suggested, hasLength(1));
    expect(goaDetail.entries, hasLength(2), reason: 'a settlement is never an expense');

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(await myNets(tester, container), netsBefore);
    await leaveApp(tester);
  });

  testWidgets('paying Priya with UPI records the payment as UPI, and a square person gets no actions', (tester) async {
    final world = FakeOutsideWorld();
    final container = await createContainer(overrides: world.overrides);
    final goa = (await tester.runAsync(() => seedSettleUpGroup(container)))!;
    await openAppAt(tester, container, '/groups/$goa?tab=balances');

    await tapVisible(tester, find.text('Settle up with one person'));
    expect(find.text('Who are you settling with?'), findsOneWidget);
    await tapVisible(tester, find.descendant(of: find.byType(BottomSheet), matching: find.text('Priya')));
    expect(inSheet(find.text('Settle up with Priya')), findsOneWidget);
    expect(inSheet(find.text('All groups')), findsNothing, reason: 'Priya is in no other group');
    expect(inSheet(find.textContaining('in all')), findsNothing, reason: 'one group has no total to repeat');

    await tapVisible(tester, inSheet(find.text('Pay with UPI')));
    expect(world.launchedUris.single.queryParameters, allOf(containsPair('pa', 'priya@upi'), containsPair('am', '100.00')));
    await tapVisible(tester, find.text('Yes, record it'));
    final settlement = (await savedDetail(tester, container, goa)).settlements.single;
    expect((settlement.amountMinor, settlement.method), (10000, 'upi'));

    await tapVisible(tester, find.text('Priya').first);
    expect(inSheet(find.text('You and Priya are square.')), findsOneWidget);
    expect(inSheet(find.textContaining('with others')), findsNothing, reason: 'Priya is in nobody\'s Settle up row any more');
    expect(inSheet(find.textContaining('Record')), findsNothing);
    await leaveApp(tester);
  });
}

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/repositories/groups_repository.dart';
import 'package:hisab/domain/split/debt_simplifier.dart';
import 'package:hisab/features/groups/record_payment_sheet.dart';

import '../support/app_harness.dart' show settle;
import '../support/group_harness.dart';

Finder inSheet(Finder finder) => find.descendant(of: find.byType(BottomSheet), matching: finder);

Finder get amountField => inSheet(find.byType(TextField)).first;

/// Picks [name] in the payment sheet's From or To dropdown ([fieldIndex] 0 or 1).
Future<void> pickMember(WidgetTester tester, int fieldIndex, String name) async {
  await tester.tap(inSheet(find.byType(DropdownButtonFormField<String>)).at(fieldIndex));
  await settle(tester);
  await tester.tap(find.text(name).last);
  await settle(tester);
}

/// Records Amit paying me [amountMinor] by cash, straight in the repository.
Future<String> seedPaymentFromAmit(WidgetTester tester, ProviderContainer container, String groupId, int amountMinor) async {
  final members = (await tester.runAsync(() => memberIdsByName(container, groupId)))!;
  return (await tester.runAsync(() => container.read(groupsRepositoryProvider).addSettlement(groupId: groupId, fromMemberId: members['Amit']!, toMemberId: members['You']!, amountMinor: amountMinor)))!;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // Rahul owes me 2,200 and Priya 700; Priya owes me 500. Simplified, Rahul
  // pays me 2,700 and Priya 200.
  const balances = GroupBalances(
    net: {'me': 2700, 'priya': 200, 'rahul': -2900},
    pairwise: [Transfer('rahul', 'me', 2200), Transfer('rahul', 'priya', 700), Transfer('priya', 'me', 500)],
    suggested: [Transfer('rahul', 'me', 2700), Transfer('rahul', 'priya', 200)],
  );

  test('a simplified suggestion larger than the direct debt is what is owed', () {
    expect(owedBetween(balances, 'rahul', 'me'), 2700);
  });

  test('a direct debt larger than the suggestion is still owed in full', () {
    expect(owedBetween(balances, 'rahul', 'priya'), 700);
    expect(owedBetween(balances, 'priya', 'me'), 500);
  });

  test('nothing is owed in the reverse direction', () {
    expect(owedBetween(balances, 'me', 'rahul'), 0);
  });

  testWidgets('a new payment warns about overpaying and two of the same person, then saves with method, note and date', (tester) async {
    final (container, groupId, _) = await openBalances(tester);

    await tapVisible(tester, find.text('Record a payment'));
    expect(find.text('Record payment'), findsWidgets);
    await tester.enterText(amountField, '50');
    await settle(tester);
    expect(find.text('You owes Amit nothing right now; this payment becomes a credit'), findsOneWidget, reason: 'I owe Amit nothing');

    await tapVisible(tester, find.byTooltip('Swap'));
    await tester.enterText(amountField, '200');
    await settle(tester);
    expect(find.text('More than the ₹150 owed; the extra becomes a credit'), findsOneWidget);
    await tester.enterText(amountField, '150');
    await settle(tester);
    expect(find.textContaining('credit'), findsNothing);

    await pickMember(tester, 1, 'Amit');
    expect(find.text('Pick two different people'), findsOneWidget);
    expect(tester.widget<FilledButton>(inSheet(find.widgetWithText(FilledButton, 'Save payment'))).onPressed, isNull, reason: 'a payment needs two people');
    await pickMember(tester, 1, 'You');

    await tapVisible(tester, inSheet(find.widgetWithText(ChoiceChip, 'Bank')));
    await tester.enterText(inSheet(find.widgetWithText(TextField, 'Note')), '  paid at dinner ');
    await tapVisible(tester, inSheet(find.byIcon(Icons.event_outlined)));
    await tapVisible(tester, find.text('OK'));
    await tapVisible(tester, inSheet(find.text('Save payment')));

    final saved = (await savedDetail(tester, container, groupId)).settlements.single;
    expect((saved.amountMinor, saved.method, saved.note), (15000, 'bank', 'paid at dinner'));
    expect(find.text('Recorded Amit → You ₹150'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect((await savedDetail(tester, container, groupId)).settlements, isEmpty, reason: 'Undo removes the payment again');
    await leaveApp(tester);
  });

  testWidgets('a cancelled date pick keeps the date, and Record payment on a transfer is prefilled', (tester) async {
    final (container, groupId, _) = await openBalances(tester);

    await tapVisible(tester, find.text('Record payment').first);
    expect(tester.widget<TextField>(amountField).controller!.text, '150', reason: 'prefilled from the Amit → You transfer');
    await tapVisible(tester, inSheet(find.byIcon(Icons.event_outlined)));
    await tapVisible(tester, find.text('Cancel'));
    await tapVisible(tester, inSheet(find.text('Save payment')));
    final saved = (await savedDetail(tester, container, groupId)).settlements.single;
    expect((saved.amountMinor, saved.method), (15000, 'cash'));
    await leaveApp(tester);
  });

  testWidgets('editing a payment counts its own amount as owed and reports the update', (tester) async {
    final (container, groupId, _) = await openBalances(tester);
    await seedPaymentFromAmit(tester, container, groupId, 5000);
    await settle(tester);

    await tapVisible(tester, find.textContaining('· Cash'));
    expect(find.text('Edit payment'), findsOneWidget);
    expect(tester.widget<TextField>(amountField).controller!.text, '50');
    await tester.enterText(amountField, '150');
    await settle(tester);
    expect(find.textContaining('credit'), findsNothing, reason: 'the ₹50 already paid is still owed back while editing it');

    await tapVisible(tester, find.byTooltip('Swap'));
    expect(find.text('You owes Amit nothing right now; this payment becomes a credit'), findsOneWidget, reason: 'reversed, the edited payment no longer counts');
    await tapVisible(tester, find.byTooltip('Swap'));
    await pickMember(tester, 0, 'Priya');
    expect(find.text('Priya owes You nothing right now; this payment becomes a credit'), findsOneWidget);
    await pickMember(tester, 0, 'Amit');
    await tester.enterText(amountField, '120');
    await settle(tester);
    await tapVisible(tester, inSheet(find.text('Save payment')));

    expect(find.text('Payment updated'), findsOneWidget);
    expect((await savedDetail(tester, container, groupId)).settlements.single.amountMinor, 12000);
    await leaveApp(tester);
  });

  testWidgets('a payment is edited or removed from its menu, and removal can be undone', (tester) async {
    final (container, groupId, _) = await openBalances(tester);
    await seedPaymentFromAmit(tester, container, groupId, 5000);
    await settle(tester);

    await tapVisible(tester, find.byTooltip('More options'));
    await tapVisible(tester, find.text('Edit payment'));
    expect(find.text('Edit payment'), findsOneWidget, reason: 'the edit sheet is open');
    await tester.tapAt(const Offset(20, 20));
    await settle(tester);

    await tapVisible(tester, find.byTooltip('More options'));
    await tapVisible(tester, find.text('Remove payment'));
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Remove'));
    expect(find.text('Payment removed'), findsOneWidget);
    expect((await savedDetail(tester, container, groupId)).settlements, isEmpty);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect((await savedDetail(tester, container, groupId)).settlements, hasLength(1));
    await leaveApp(tester);
  });
}

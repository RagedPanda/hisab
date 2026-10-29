import 'package:drift/drift.dart' show OrderingTerm, driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/repositories/groups_repository.dart';

import '../support/group_harness.dart';

/// The settle-up group on its Balances tab, with the outside world faked.
Future<(ProviderContainer, String, FakeOutsideWorld)> openBalances(WidgetTester tester) async {
  final world = FakeOutsideWorld();
  final container = await createContainer(overrides: world.overrides);
  final groupId = (await tester.runAsync(() => seedSettleUpGroup(container)))!;
  await openAppAt(tester, container, '/groups/$groupId?tab=balances');
  return (container, groupId, world);
}

Future<GroupDetail> savedDetail(WidgetTester tester, ProviderContainer container, String groupId) async =>
    (await tester.runAsync<GroupDetail?>(() => container.read(groupsRepositoryProvider).getGroupDetail(groupId)))!;

/// Channels of the reminders logged for the group, oldest first.
Future<List<String>> reminderChannels(WidgetTester tester, ProviderContainer container, String groupId) async {
  final database = container.read(databaseProvider);
  final rows = (await tester.runAsync(() => (database.select(database.reminders)..where((row) => row.groupId.equals(groupId))..orderBy([(row) => OrderingTerm(expression: row.sentAt)])).get()))!;
  return [for (final reminder in rows) reminder.channel];
}

Finder sheetButton(String label) => find.descendant(of: find.byType(BottomSheet), matching: find.text(label));

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('a reminder shares the edited message, logs it, and the row then says when', (tester) async {
    final (container, groupId, world) = await openBalances(tester);

    await tapVisible(tester, find.text('Remind'));
    expect(find.text('Remind Amit'), findsOneWidget);
    expect(find.text('₹150'), findsWidgets);
    expect(find.text('Reminded today'), findsNothing);
    await tester.enterText(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)), 'Amit, villa money please');
    await tapVisible(tester, sheetButton('Share…'));

    expect(world.sharedTexts, ['Amit, villa money please']);
    expect(find.byType(BottomSheet), findsNothing, reason: 'a completed share closes the sheet');
    expect((await savedDetail(tester, container, groupId)).lastRemindedAt.keys, hasLength(1));
    expect(find.text('Remind again'), findsOneWidget);
    expect(find.text('Reminded today'), findsOneWidget);

    await tapVisible(tester, find.text('Remind again'));
    expect(find.descendant(of: find.byType(BottomSheet), matching: find.text('Reminded today')), findsOneWidget, reason: 'the sheet repeats when I last reminded');
    await leaveApp(tester);
  });

  testWidgets('a dismissed share keeps the sheet open and logs nothing', (tester) async {
    final (container, groupId, world) = await openBalances(tester);
    world.shareCompletes = false;

    await tapVisible(tester, find.text('Remind'));
    await tapVisible(tester, sheetButton('Share…'));
    expect(world.sharedTexts, hasLength(1));
    expect(find.byType(BottomSheet), findsOneWidget);
    expect((await savedDetail(tester, container, groupId)).lastRemindedAt, isEmpty);
    await leaveApp(tester);
  });

  testWidgets('copying a reminder confirms and logs it', (tester) async {
    final (container, groupId, world) = await openBalances(tester);
    world.fakeClipboard(tester);

    await tapVisible(tester, find.text('Remind'));
    await tapVisible(tester, sheetButton('Copy'));
    expect(world.copiedTexts.single, contains('Goa'));
    expect(find.text('Copied. Paste it into any chat.'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(await reminderChannels(tester, container, groupId), ['copy']);
    await leaveApp(tester);
  });

  testWidgets('WhatsApp and SMS open the app with the message, and say so when no app opens', (tester) async {
    final (container, groupId, world) = await openBalances(tester);
    world.linkOpens = false;

    await tapVisible(tester, find.text('Remind'));
    await tapVisible(tester, sheetButton('WhatsApp'));
    expect(find.text("Couldn't open WhatsApp."), findsOneWidget, reason: 'shown inside the sheet, not behind it');
    expect(find.byType(BottomSheet), findsOneWidget);

    world.linkOpens = true;
    await tapVisible(tester, sheetButton('WhatsApp'));
    expect(world.launchedUris.last.toString(), contains('919876543210'));
    await tapVisible(tester, find.text('Remind again'));
    await tapVisible(tester, sheetButton('SMS'));
    expect(world.launchedUris.last.scheme, 'sms');
    expect(await reminderChannels(tester, container, groupId), ['whatsapp', 'sms']);
    await leaveApp(tester);
  });

  testWidgets('paying with UPI asks whether it went through before recording it', (tester) async {
    final (container, groupId, world) = await openBalances(tester);
    world.linkOpens = false;

    await tapVisible(tester, find.text('Pay'));
    expect(find.text('Pay Priya'), findsOneWidget);
    expect(find.text('WhatsApp'), findsNothing, reason: 'Priya has no phone number');
    await tapVisible(tester, sheetButton('Pay with UPI'));
    expect(find.text('No UPI app on this phone. Pay another way, then record it.'), findsOneWidget);

    world.linkOpens = true;
    await tapVisible(tester, sheetButton('Pay with UPI'));
    expect(world.launchedUris.last.scheme, 'upi');
    expect(world.launchedUris.last.queryParameters['pa'], 'priya@upi');
    expect(find.text('Did the payment go through?'), findsOneWidget);
    await tapVisible(tester, find.text('Not yet'));
    expect((await savedDetail(tester, container, groupId)).settlements, isEmpty);
    expect(find.byType(BottomSheet), findsOneWidget, reason: 'Not yet leaves the sheet open to try again');

    await tapVisible(tester, sheetButton('Pay with UPI'));
    await tapVisible(tester, find.text('Yes, record it'));
    final settlement = (await savedDetail(tester, container, groupId)).settlements.single;
    expect((settlement.amountMinor, settlement.method), (10000, 'upi'));
    expect(find.text('Recorded You → Priya ₹100'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    await leaveApp(tester);
  });

  testWidgets('sharing a payment message logs no reminder, and Record payment opens the payment sheet', (tester) async {
    final (container, groupId, world) = await openBalances(tester);

    await tapVisible(tester, find.text('Pay'));
    await tapVisible(tester, sheetButton('Share…'));
    expect(world.sharedTexts, hasLength(1));
    expect((await savedDetail(tester, container, groupId)).lastRemindedAt, isEmpty, reason: 'only money owed to me is a reminder');

    await tapVisible(tester, find.text('Pay'));
    await tapVisible(tester, sheetButton('Record payment'));
    expect(find.text('Save payment'), findsOneWidget);
    expect(find.text('100'), findsOneWidget, reason: 'the payment sheet is prefilled with what I owe');
    await leaveApp(tester);
  });
}

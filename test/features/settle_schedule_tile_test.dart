import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';

import '../core/fake_notification_gateway.dart';
import '../support/app_harness.dart' show settle;
import '../support/group_harness.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('a settle-up reminder asks for notifications, then offers a nudge until it is turned off', (tester) async {
    final world = FakeOutsideWorld();
    final gateway = FakeNotificationGateway(notificationsAllowed: false);
    final container = await createContainer(overrides: [...world.overrides, notificationGatewayProvider.overrideWithValue(gateway)]);
    final groupId = (await tester.runAsync(() async {
      final groupId = await seedSettleUpGroup(container);
      await container.read(groupsRepositoryProvider).editMember((await memberIdsByName(container, groupId))['You']!, name: 'Ankur');
      return groupId;
    }))!;
    await openAppAt(tester, container, '/groups/$groupId?tab=balances');
    Future<Object?> savedSchedule() => tester.runAsync<Object?>(() => container.read(settleScheduleRepositoryProvider).watchSchedule(groupId).first);

    expect(find.text('Settle-up reminder off'), findsOneWidget);
    expect(find.byTooltip('Share a nudge'), findsNothing);

    await tapVisible(tester, find.text('Remind me to settle up'));
    await tester.tapAt(const Offset(20, 20));
    await settle(tester);
    expect(await savedSchedule(), isNull, reason: 'closing the sheet saves nothing');

    await tapVisible(tester, find.text('Remind me to settle up'));
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save'));
    expect(find.text('Get reminded to settle up'), findsOneWidget);
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Allow'));
    expect(gateway.permissionRequests, 1);
    expect(await savedSchedule(), isNotNull);
    expect(find.text('Settle-up reminder off'), findsNothing);

    await tapVisible(tester, find.byTooltip('Share a nudge'));
    expect(world.sharedTexts.single, allOf(contains('Goa'), contains('Amit owes Ankur ₹150'), contains('Ankur owes Priya ₹100')), reason: 'the nudge goes to others, so it names me by my name');

    await tapVisible(tester, find.text('Remind me to settle up'));
    await tapVisible(tester, find.widgetWithText(OutlinedButton, 'Turn off'));
    expect(await savedSchedule(), isNull);
    expect(find.text('Settle-up reminder off'), findsOneWidget);
    expect(gateway.permissionRequests, 1, reason: 'turning off never asks for permission');
    await leaveApp(tester);
  });
}

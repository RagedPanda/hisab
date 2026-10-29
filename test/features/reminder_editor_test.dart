import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/domain/reminders/reminder_draft.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:hisab/features/reminders/reminder_editor.dart';
import 'package:hisab/features/shell/router.dart';

import '../core/fake_notification_gateway.dart';
import '../support/app_harness.dart' show pumpApp, settle;

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await settle(tester, 3);
  await tester.tap(finder);
  await settle(tester);
}

Future<void> _openEditor(WidgetTester tester) async {
  final inThreeDays = DateTime.now().add(const Duration(days: 3));
  final draft = ReminderDraft(
    kind: ReminderKind.bill,
    title: 'Electricity',
    amountMinor: 210000,
    dueAt: DateTime(inThreeDays.year, inThreeDays.month, inThreeDays.day),
    repeat: ReminderRepeat.monthly,
    remindDaysBefore: const [1, 0],
  );
  showReminderEditor(appRouter.routerDelegate.navigatorKey.currentContext!, initial: draft);
  await settle(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every field of the editor is editable and saved', (tester) async {
    final container = await pumpApp(tester, overrides: [notificationGatewayProvider.overrideWithValue(FakeNotificationGateway())]);
    final scottyId = await container.read(projectsRepositoryProvider).create(name: 'Scotty', icon: 'directions_car', color: 0xFF2196F3, templateKey: 'vehicle');
    await settle(tester);
    await _openEditor(tester);

    await _tapVisible(tester, find.widgetWithText(ChoiceChip, 'EMI'));
    await _tapVisible(tester, find.byKey(const ValueKey('reminder-due')));
    await tester.tap(find.text('OK'));
    await settle(tester);

    await _tapVisible(tester, find.text('Every month'));
    await tester.tap(find.text('Every 3 months').last);
    await settle(tester);

    await _tapVisible(tester, find.byKey(const ValueKey('reminder-project')));
    await tester.tap(find.text('Scotty').last);
    await settle(tester);

    await _tapVisible(tester, find.widgetWithText(SwitchListTile, 'Notify me'));
    expect(find.text('On the day'), findsNothing, reason: 'no alert choices while notifications are off');
    await _tapVisible(tester, find.widgetWithText(SwitchListTile, 'Notify me'));
    await _tapVisible(tester, find.widgetWithText(FilterChip, '1 day before'));
    final alertTime = find.textContaining('At ');
    final timeBefore = tester.widget<Text>(alertTime).data;
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    await _tapVisible(tester, alertTime);
    await tester.tap(find.text('PM'));
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tester.binding.setSurfaceSize(const Size(430, 932));
    await settle(tester, 3);
    expect(tester.widget<Text>(alertTime).data, isNot(timeBefore));

    await _tapVisible(tester, find.text('Choose category'));
    await tester.tap(find.descendant(of: find.byType(DraggableScrollableSheet), matching: find.byType(ListTile)).first);
    await settle(tester);
    expect(find.text('Choose category'), findsNothing);

    await _tapVisible(tester, find.byKey(const ValueKey('reminder-save')));

    final saved = (await container.read(remindersRepositoryProvider).getUpcoming()).single;
    expect(saved.kind, ReminderKind.emi.key);
    expect(saved.repeat, ReminderRepeat.quarterly.key);
    expect(saved.projectId, scottyId);
    expect(saved.categoryId, isNotNull);
    expect(tester.takeException(), isNull);
  });
}

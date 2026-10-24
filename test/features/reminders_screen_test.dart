import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/money.dart';
import 'package:hisab/core/notifications/reminder_payload.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/sms/sms_channel.dart';
import 'package:hisab/domain/reminders/reminder_draft.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:hisab/features/reminders/reminder_startup.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/fake_notification_gateway.dart';

Future<(ProviderContainer, AppDatabase)> _pumpReminders(WidgetTester tester, FakeNotificationGateway gateway, {String location = '/reminders'}) async {
  SharedPreferences.setMockInitialValues({'onboarded': true, 'currencyCode': 'INR'});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    databaseProvider.overrideWithValue(db),
    notificationGatewayProvider.overrideWithValue(gateway),
  ]);
  addTearDown(container.dispose);
  await tester.binding.setSurfaceSize(const Size(360, 780));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  appRouter.go('/settings');
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
  await _settle(tester);
  if (location != '/settings') {
    appRouter.push(location);
    await _settle(tester);
  }
  return (container, db);
}

Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

DateTime _inDays(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + days);
}

Future<String> _addBill(ProviderContainer container, {int amountMinor = 210000, String? categoryId, ReminderRepeat repeat = ReminderRepeat.monthly}) =>
    container.read(reminderSchedulerProvider).save(ReminderDraft(
          kind: ReminderKind.bill,
          title: 'Electricity',
          dueAt: _inDays(3),
          amountMinor: amountMinor,
          categoryId: categoryId,
          repeat: repeat,
          remindDaysBefore: const [1, 0],
        ));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty state, then a reminder created in the editor is listed and scheduled', (tester) async {
    final gateway = FakeNotificationGateway();
    await _pumpReminders(tester, gateway);
    expect(find.text('No reminders yet'), findsOneWidget);

    await tester.tap(find.text('Add reminder'));
    await _settle(tester);
    expect(find.text('New reminder'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reminder-save')));
    await _settle(tester);
    expect(find.text('Enter a title'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('reminder-title')), 'Rent');
    await tester.enterText(find.byKey(const ValueKey('reminder-amount')), '15000');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('reminder-save')));
    await _settle(tester);

    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.textContaining('Due tomorrow'), findsOneWidget);
    expect(gateway.scheduled.values.where((alert) => alert.title.contains('Rent')), isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('#44 amount field drops letters and blocks saving an amount it cannot read', (tester) async {
    final gateway = FakeNotificationGateway();
    final (_, db) = await _pumpReminders(tester, gateway);
    await tester.tap(find.text('Add reminder'));
    await _settle(tester);
    await tester.enterText(find.byKey(const ValueKey('reminder-title')), 'Rent');

    await tester.enterText(find.byKey(const ValueKey('reminder-amount')), 'abc15x00');
    await tester.pump();
    expect(tester.widget<TextField>(find.byKey(const ValueKey('reminder-amount'))).controller!.text, '1500');

    await tester.enterText(find.byKey(const ValueKey('reminder-amount')), '1.2.3');
    await tester.pump();
    expect(find.text('Enter a valid amount, e.g. 250 or 99.50'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reminder-save')));
    await _settle(tester);
    expect(await db.select(db.reminders).get(), isEmpty, reason: 'nothing saved with an unreadable amount');
    expect(find.text('New reminder'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('#54 the Undo snackbar after mark paid goes away on its own', (tester) async {
    final gateway = FakeNotificationGateway();
    final (container, _) = await _pumpReminders(tester, gateway, location: '/settings');
    await _addBill(container);
    appRouter.push('/reminders');
    await _settle(tester);

    await tester.tap(find.byTooltip('Mark paid'));
    await _settle(tester);
    await tester.tap(find.text('Just mark paid'));
    await _settle(tester);
    expect(find.byType(SnackBar), findsOneWidget);
    await _settle(tester, 80);
    expect(find.byType(SnackBar), findsNothing, reason: 'Marked paid snackbar times out after 6 s');
    expect(tester.takeException(), isNull);
  });

  testWidgets('just mark paid moves the bill to history and Undo reopens it', (tester) async {
    final gateway = FakeNotificationGateway();
    final (container, db) = await _pumpReminders(tester, gateway, location: '/settings');
    final id = await _addBill(container);
    appRouter.push('/reminders');
    await _settle(tester);
    expect(gateway.scheduled, isNotEmpty);

    await tester.tap(find.byTooltip('Mark paid'));
    await _settle(tester);
    expect(find.text('Paid Electricity?'), findsOneWidget);
    await tester.tap(find.text('Just mark paid'));
    await _settle(tester);

    final closed = await (db.select(db.reminders)..where((t) => t.id.equals(id))).getSingle();
    expect(closed.status, 'done');
    expect(closed.nextId, isNotNull, reason: 'monthly bill rolls on to next month');
    expect(gateway.alertsFor(reminderPayload(id)), isEmpty);
    expect(gateway.alertsFor(reminderPayload(closed.nextId!)), isNotEmpty);

    await tester.tap(find.text('History'));
    await _settle(tester);
    expect(find.textContaining('Paid '), findsOneWidget);
    await tester.tap(find.text('Undo').last);
    await _settle(tester);
    final reopened = await (db.select(db.reminders)..where((t) => t.id.equals(id))).getSingle();
    expect(reopened.status, 'pending');
    expect(gateway.alertsFor(reminderPayload(id)), isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a bank SMS that matches a bill marks it paid and History labels it Paid via SMS', (tester) async {
    final gateway = FakeNotificationGateway();
    final (container, db) = await _pumpReminders(tester, gateway, location: '/settings');
    final scheduler = container.read(reminderSchedulerProvider);
    const body = 'Rs.2,150.00 debited from A/c XX1234 to electricity.board@okicici (UPI Ref No 123456789012). Avl bal Rs.10,000.00';
    final electricityId = await _addBill(container);
    final rent = await scheduler.save(ReminderDraft(kind: ReminderKind.bill, title: 'Rent', dueAt: _inDays(2), amountMinor: 1500000));
    await scheduler.markDone(rent);
    await container.read(smsIngestServiceProvider).ingest(RawSms(sender: 'HDFCBK', body: body, receivedAt: DateTime.now()), autoAdd: true);
    final paid = await (db.select(db.reminders)..where((t) => t.id.equals(electricityId))).getSingle();
    final log = await db.select(db.smsLog).getSingle();
    expect(paid.status, 'done');
    expect(paid.entryId, isNotNull);
    expect(paid.nextId, isNotNull, reason: 'the monthly bill rolls on');
    expect(log.matchedReminderId, electricityId);

    appRouter.push('/reminders');
    await _settle(tester);
    await tester.tap(find.text('History'));
    await _settle(tester);
    expect(find.text('Electricity'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('Paid via SMS'), findsOneWidget, reason: 'only the SMS-paid reminder carries the label');
    final electricityTile = find.widgetWithText(ListTile, 'Electricity');
    expect(find.descendant(of: electricityTile, matching: find.textContaining(formatMinor(215000))), findsOneWidget,
        reason: 'History shows what the SMS paid (decision 16)');
    expect(find.descendant(of: electricityTile, matching: find.textContaining(formatMinor(210000))), findsNothing,
        reason: 'not the bill amount it was due for');
    expect(tester.takeException(), isNull);
  });

  testWidgets('add entry & mark paid opens a prefilled expense and links it', (tester) async {
    final gateway = FakeNotificationGateway();
    final (container, db) = await _pumpReminders(tester, gateway, location: '/settings');
    final category = (await db.select(db.categories).get()).firstWhere((c) => c.kind == 'expense');
    final id = await _addBill(container, categoryId: category.id, repeat: ReminderRepeat.once);
    appRouter.push('/reminders');
    await _settle(tester);

    await tester.tap(find.byTooltip('Mark paid'));
    await _settle(tester);
    await tester.tap(find.text('Add entry & mark paid'));
    await _settle(tester);
    expect(find.text('New entry'), findsOneWidget);
    expect(find.widgetWithText(TextField, '2100'), findsOneWidget);
    await tester.tap(find.textContaining('Save').last);
    await _settle(tester);

    final closed = await (db.select(db.reminders)..where((t) => t.id.equals(id))).getSingle();
    expect(closed.status, 'done');
    expect(closed.entryId, isNotNull);
    final entry = await (db.select(db.entries)..where((t) => t.id.equals(closed.entryId!))).getSingle();
    expect(entry.amountMinor, 210000);
    expect(entry.categoryId, category.id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notifications off: banner on the list, pre-permission sheet on save', (tester) async {
    final gateway = FakeNotificationGateway(notificationsAllowed: false);
    final (container, _) = await _pumpReminders(tester, gateway, location: '/settings');
    await _addBill(container);
    appRouter.push('/reminders');
    await _settle(tester);
    expect(find.textContaining('Notifications are off'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await _settle(tester);
    await tester.enterText(find.byKey(const ValueKey('reminder-title')), 'Mobile');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('reminder-save')));
    await _settle(tester);
    expect(find.text("Get reminded before it's due"), findsOneWidget);
    await tester.tap(find.text('Allow'));
    await _settle(tester);
    expect(gateway.permissionRequests, 1);
    expect(find.text('Mobile'), findsOneWidget);
    expect(find.textContaining('Notifications are off'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exact alarms denied: asked after the pre-prompt, late note on the list, resume re-posts exact', (tester) async {
    final gateway = FakeNotificationGateway(notificationsAllowed: false, exactAlarmsAllowed: false);
    final (container, _) = await _pumpReminders(tester, gateway, location: '/settings');
    appRouter.push('/reminders');
    await _settle(tester);

    await tester.tap(find.text('Add reminder'));
    await _settle(tester);
    await tester.enterText(find.byKey(const ValueKey('reminder-title')), 'Rent');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('reminder-save')));
    await _settle(tester);
    await tester.tap(find.text('Allow'));
    await _settle(tester);
    expect(find.text('Get reminders on time'), findsOneWidget, reason: 'explained after the notification pre-prompt');
    await tester.tap(find.text('Allow'));
    await _settle(tester);
    expect(gateway.exactRequests, 1);
    expect(gateway.exactById.values, everyElement(isFalse), reason: 'denied: inexact fallback');

    expect(find.text('Reminders may arrive late. Allow Alarms & reminders'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reminders-late-note')));
    await _settle(tester);
    expect(gateway.exactRequests, 2);

    final before = await gateway.permissionState();
    gateway.exactAlarmsAllowed = true; // granted in Settings, then the app resumes
    await recheckAlarmAccess(container, before);
    await _settle(tester);
    expect(gateway.exactById.values, everyElement(isTrue), reason: 're-posted exact');
    expect(find.text('Reminders may arrive late. Allow Alarms & reminders'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Turn on -> notifications granted -> no throw -> Alarms & reminders sheet -> granted re-posts exact', (tester) async {
    final gateway = FakeNotificationGateway(notificationsAllowed: false, exactAlarmsAllowed: false, grantExactOnRequest: true);
    final (container, _) = await _pumpReminders(tester, gateway, location: '/settings');
    await _addBill(container);
    appRouter.push('/reminders');
    await _settle(tester);
    expect(gateway.exactById.values, everyElement(isFalse), reason: 'no access yet: inexact');

    await tester.tap(find.text('Turn on'));
    await _settle(tester);
    expect(tester.takeException(), isNull, reason: 'the banner goes away once granted; the flow must not use its ref');
    expect(gateway.permissionRequests, 1);
    expect(find.text('Get reminders on time'), findsOneWidget, reason: 'permission is re-read only at the end, so the banner stays while the sheet shows');
    await tester.tap(find.text('Allow'));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(gateway.exactRequests, 1);
    expect(gateway.exactById.values, everyElement(isTrue), reason: 'granted: every alert re-posted exact');
    expect(find.text('Reminders may arrive late. Allow Alarms & reminders'), findsNothing);
    expect(find.text('Turn on'), findsNothing, reason: 'notifications on: the banner is gone');
  });

  testWidgets('Turn on in the notifications-off banner follows with the Alarms & reminders sheet', (tester) async {
    final gateway = FakeNotificationGateway(notificationsAllowed: false, exactAlarmsAllowed: false);
    final (container, _) = await _pumpReminders(tester, gateway, location: '/settings');
    await _addBill(container);
    appRouter.push('/reminders');
    await _settle(tester);

    await tester.tap(find.text('Turn on'));
    await _settle(tester);
    expect(gateway.permissionRequests, 1);
    expect(find.text('Get reminders on time'), findsOneWidget, reason: 'decision 22: reminders fire on time');
    await tester.tap(find.text('Allow'));
    await _settle(tester);
    expect(gateway.exactRequests, 1);
    expect(find.text('Reminders may arrive late. Allow Alarms & reminders'), findsOneWidget, reason: 'still denied, so the late note shows');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a 0 amount is no amount: hidden on the list and empty in the editor', (tester) async {
    final gateway = FakeNotificationGateway();
    final (container, _) = await _pumpReminders(tester, gateway, location: '/settings');
    await _addBill(container, amountMinor: 0);
    appRouter.push('/reminders');
    await _settle(tester);
    expect(find.textContaining('₹0'), findsNothing);

    await tester.tap(find.text('Electricity'));
    await _settle(tester);
    expect(tester.widget<TextField>(find.byKey(const ValueKey('reminder-amount'))).controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings row shows the upcoming count and notification state', (tester) async {
    final gateway = FakeNotificationGateway();
    final (container, _) = await _pumpReminders(tester, gateway, location: '/settings');
    await _addBill(container);
    await _settle(tester);
    await tester.scrollUntilVisible(find.text('Reminders'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('1 upcoming · notifications on'), findsOneWidget);
    await tester.tap(find.text('Reminders'));
    await _settle(tester);
    expect(find.text('Electricity'), findsOneWidget);
  });

  testWidgets('a notification tap on a paid reminder says it is already paid', (tester) async {
    final gateway = FakeNotificationGateway();
    final (container, _) = await _pumpReminders(tester, gateway, location: '/settings');
    final id = await _addBill(container, repeat: ReminderRepeat.once);
    await container.read(reminderSchedulerProvider).markDone(id);
    appRouter.push('/reminders/$id');
    await _settle(tester);
    expect(find.text('Already marked paid'), findsOneWidget);
  });
}

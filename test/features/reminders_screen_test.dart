import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/notifications/reminder_payload.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/domain/reminders/reminder_draft.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:hisab/features/shell/widgets/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/fake_notification_gateway.dart';

Future<(ProviderContainer, AppDatabase)> _pumpReminders(WidgetTester tester, FakeNotificationGateway gateway, {String location = '/reminders'}) async {
  SharedPreferences.setMockInitialValues({'onboarded': true});
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
    expect(find.text('Documents & renewals'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('new-reminder.blank')));
    await _settle(tester);
    expect(find.text('New reminder'), findsOneWidget);
    expect(find.byKey(const ValueKey('reminder-document-number')), findsNothing, reason: 'a plain bill has no document number');
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
    await tester.tap(find.byKey(const ValueKey('new-reminder.blank')));
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

  group('documents & renewals', () {
    testWidgets('a PUC preset prefills the editor, links the only vehicle project and keeps the number', (tester) async {
      final gateway = FakeNotificationGateway();
      final (container, db) = await _pumpReminders(tester, gateway);
      final scottyId = await container.read(projectsRepositoryProvider).create(name: 'Scotty', icon: 'directions_car', color: 0xFF2196F3, templateKey: 'vehicle');
      await _settle(tester);

      await tester.tap(find.text('Add reminder'));
      await _settle(tester);
      await tester.scrollUntilVisible(find.byKey(const ValueKey('new-reminder.preset.puc')), 100, scrollable: find.byType(Scrollable).last);
      await tester.tap(find.byKey(const ValueKey('new-reminder.preset.puc')));
      await _settle(tester);

      final title = tester.widget<TextField>(find.byKey(const ValueKey('reminder-title')));
      expect(title.controller!.text, 'PUC certificate');
      expect(find.text('Every year'), findsOneWidget);
      await tester.dragUntilVisible(find.text('15 days before'), find.byType(ChipRow).at(1), const Offset(-100, 0));
      expect(find.text('15 days before'), findsOneWidget);
      expect(find.textContaining('Older vehicles'), findsOneWidget);
      await tester.scrollUntilVisible(find.byKey(const ValueKey('reminder-project')), 100, scrollable: find.byType(Scrollable).first);
      expect(find.descendant(of: find.byKey(const ValueKey('reminder-project')), matching: find.text('Scotty')), findsOneWidget, reason: 'the only vehicle project is suggested');

      await tester.enterText(find.byKey(const ValueKey('reminder-document-number')), 'dl01ab1234');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('reminder-save')));
      await tester.tap(find.byKey(const ValueKey('reminder-save')));
      await _settle(tester);

      final saved = await db.select(db.reminders).getSingle();
      expect(saved.title, 'PUC certificate');
      expect(saved.kind, 'document');
      expect(saved.presetKey, 'puc');
      expect(saved.projectId, scottyId);
      expect(saved.documentNumber, 'dl01ab1234');
      expect(saved.repeat, 'yearly');
      expect(saved.remindDaysBefore, '15,7,1,0');
      expect(tester.takeException(), isNull);
    });

    testWidgets('editing a passport reminder offers its ten-year cycle', (tester) async {
      final gateway = FakeNotificationGateway();
      final (container, _) = await _pumpReminders(tester, gateway, location: '/settings');
      await container.read(reminderSchedulerProvider).save(ReminderDraft(
            kind: ReminderKind.document,
            title: 'Passport',
            dueAt: _inDays(200),
            repeat: ReminderRepeat.everyTenYears,
            remindDaysBefore: const [180, 0],
            presetKey: 'passport',
            documentNumber: 'Z1234567',
          ));
      appRouter.push('/reminders');
      await _settle(tester);
      expect(find.textContaining('Z1234567'), findsOneWidget);
      await tester.tap(find.text('Passport'));
      await _settle(tester);
      expect(find.text('Every 10 years'), findsOneWidget);
      await tester.dragUntilVisible(find.text('180 days before'), find.byType(ChipRow).at(1), const Offset(-100, 0));
      expect(find.text('180 days before'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a project screen lists the reminders linked to it', (tester) async {
      final gateway = FakeNotificationGateway();
      final (container, _) = await _pumpReminders(tester, gateway, location: '/settings');
      final scottyId = await container.read(projectsRepositoryProvider).create(name: 'Scotty', icon: 'directions_car', color: 0xFF2196F3, templateKey: 'vehicle');
      await container.read(reminderSchedulerProvider).save(ReminderDraft(
            kind: ReminderKind.insurance,
            title: 'Bike insurance',
            dueAt: _inDays(20),
            repeat: ReminderRepeat.yearly,
            projectId: scottyId,
            presetKey: 'vehicle_insurance',
          ));
      appRouter.push('/projects/$scottyId');
      await _settle(tester);
      await tester.scrollUntilVisible(find.text('Bike insurance'), 100,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Reminders'), findsWidgets);
      expect(find.textContaining('Due in 20 days'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

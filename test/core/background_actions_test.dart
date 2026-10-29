import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/notifications/background_actions.dart';
import 'package:hisab/core/notifications/reminder_payload.dart';
import 'package:hisab/core/notifications/reminder_scheduler.dart';
import 'package:hisab/core/settings.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/reminders_repository.dart';
import 'package:hisab/domain/reminders/reminder_draft.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds a scheduler over the given database in the saved language', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    SharedPreferences.setMockInitialValues({});
    final settings = AppSettings.fromPrefs(await SharedPreferences.getInstance());

    expect(buildReminderScheduler(db, settings), isA<ReminderScheduler>());
  });

  group('background notification actions', () {
    late Directory documents;
    final opened = <String>[];

    setUp(() {
      documents = Directory.systemTemp.createTempSync('hisab_background_');
      opened.clear();
      SharedPreferences.setMockInitialValues({});
      // Where the app database lives; recorded so the test can tell whether
      // the action opened it.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (call) async {
        opened.add(call.method);
        return documents.path;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), null);
      documents.deleteSync(recursive: true);
    });

    test('a tap that is not Snooze leaves the database closed', () async {
      await handleBackgroundAction(payload: reminderPayload('power'), actionId: kMarkPaidActionId);
      await handleBackgroundAction(payload: 'not a reminder', actionId: kSnoozeActionId);
      onBackgroundNotificationResponse(const NotificationResponse(notificationResponseType: NotificationResponseType.selectedNotificationAction));

      expect(opened, isEmpty);
    });

    test('Snooze opens the app database, snoozes the reminder and posts its alert', () async {
      // The notification plugin as the background isolate sees it on Android.
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      final pluginCalls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('dexterous.com/flutter/local_notifications'), (call) async {
        pluginCalls.add(call.method);
        return switch (call.method) {
          'pendingNotificationRequests' => <Object>[],
          'areNotificationsEnabled' || 'canScheduleExactNotifications' => true,
          _ => null,
        };
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('dexterous.com/flutter/local_notifications'), null));
      final databaseFile = File('${documents.path}/hisab.sqlite');
      final seeded = AppDatabase(NativeDatabase(databaseFile));
      final dueAt = DateTime.now().add(const Duration(days: 20));
      final reminderId = await RemindersRepository(seeded).save(ReminderDraft(
        kind: ReminderKind.bill,
        title: 'Electricity',
        amountMinor: 210000,
        dueAt: DateTime(dueAt.year, dueAt.month, dueAt.day),
        repeat: ReminderRepeat.once,
        remindDaysBefore: const [0],
        notifyAtMinute: 9 * 60,
      ));
      await seeded.close();

      await handleBackgroundAction(payload: reminderPayload(reminderId), actionId: kSnoozeActionId);

      expect(opened, contains('getApplicationDocumentsDirectory'));
      expect(pluginCalls, contains('zonedSchedule'));
      final reopened = AppDatabase(NativeDatabase(databaseFile));
      addTearDown(reopened.close);
      final snoozed = await RemindersRepository(reopened).getById(reminderId);
      expect(snoozed?.snoozedUntil, isNotNull);
    });
  });
}

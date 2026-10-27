import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/notifications/notification_gateway.dart';
import 'package:hisab/core/notifications/notification_service.dart';
import 'package:hisab/core/notifications/reminder_alert_text.dart';
import 'package:hisab/core/notifications/reminder_payload.dart';
import 'package:hisab/core/notifications/reminder_scheduler.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/reminders_repository.dart';
import 'package:hisab/domain/reminders/reminder_draft.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:hisab/domain/reminders/reminder_schedule.dart';

import 'fake_notification_gateway.dart';
import 'package:hisab/core/money.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationGateway gateway;
  late ReminderScheduler scheduler;
  late RemindersRepository repository;
  var now = DateTime(2026, 10, 22, 10);
  final english = notificationLocalizations('en');

  setUp(() {
    now = DateTime(2026, 10, 22, 10);
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway();
    repository = RemindersRepository(db, clock: () => now);
    scheduler = ReminderScheduler(
      reminders: repository,
      notifications: NotificationService(gateway, buildAlert: (r, a) => alertRequestFor(r, a, english, moneyFormat: MoneyFormat.inr), clock: () => now),
      clock: () => now,
    );
  });

  tearDown(() => db.close());

  ReminderDraft electricity({String? id, List<int> days = const [3, 0], ReminderKind kind = ReminderKind.bill}) => ReminderDraft(
        id: id,
        kind: kind,
        title: 'Electricity',
        amountMinor: 210000,
        dueAt: DateTime(2026, 11, 5),
        repeat: ReminderRepeat.monthly,
        remindDaysBefore: days,
        notifyAtMinute: 9 * 60 + 30,
      );

  test('save schedules one alert per day before with texts, actions and payload', () async {
    final id = await scheduler.save(electricity());
    final alerts = gateway.alertsFor(reminderPayload(id));
    expect(alerts.map((a) => a.fireAt), [DateTime(2026, 11, 2, 9, 30), DateTime(2026, 11, 5, 9, 30)]);
    expect(alerts.first.title, 'Electricity');
    expect(alerts.first.body, 'Due in 3 days · ₹2,100');
    expect(alerts.last.body, 'Due today · ₹2,100');
    expect(alerts.first.markPaidLabel, 'Mark paid');
    expect(alerts.first.isMoney, isTrue);
    expect(gateway.exactById.values, everyElement(isTrue));
  });

  test('a 0 amount (as in an old row) shows no amount in the notification text', () {
    final due = DateTime(2026, 11, 5);
    expect(reminderDueCaption(english, dueAt: due, at: DateTime(2026, 11, 5, 9), amountMinor: 0, moneyFormat: MoneyFormat.inr), 'Due today');
    expect(reminderDueCaption(english, dueAt: due, at: DateTime(2026, 11, 5, 9), amountMinor: 210000, moneyFormat: MoneyFormat.inr), 'Due today · ₹2,100');
  });

  test('documents say Done; Hindi texts come from the hi dictionary', () async {
    final hindi = NotificationService(gateway, buildAlert: (r, a) => alertRequestFor(r, a, notificationLocalizations('hi'), moneyFormat: MoneyFormat.inr), clock: () => now);
    final id = await repository.save(electricity(kind: ReminderKind.document));
    await hindi.schedule((await repository.getById(id))!);
    final alert = gateway.alertsFor(reminderPayload(id)).first;
    expect(alert.isMoney, isFalse);
    expect(alert.markPaidLabel, 'हो गया');
    expect(alert.body, contains('3 दिन में देय'));
  });

  test('without exact-alarm permission alerts are still posted, inexact', () async {
    gateway.exactAlarmsAllowed = false;
    final id = await scheduler.save(electricity());
    expect(gateway.alertsFor(reminderPayload(id)), hasLength(2));
    expect(gateway.exactById.values, everyElement(isFalse));
  });

  test('editing the days replaces old alerts, including slots no longer chosen', () async {
    final id = await scheduler.save(electricity(days: const [90, 0]));
    expect(gateway.alertsFor(reminderPayload(id)), hasLength(1), reason: 'the 90-day alert is already past');
    await scheduler.save(electricity(id: id, days: const [1]));
    expect(gateway.alertsFor(reminderPayload(id)).map((a) => a.fireAt), [DateTime(2026, 11, 4, 9, 30)]);
  });

  test('markDone cancels the alerts and schedules the next occurrence', () async {
    final id = await scheduler.save(electricity());
    final nextId = await scheduler.markDone(id, entryId: 'e1');
    expect(gateway.alertsFor(reminderPayload(id)), isEmpty);
    expect(gateway.alertsFor(reminderPayload(nextId!)).map((a) => a.fireAt), [DateTime(2026, 12, 2, 9, 30), DateTime(2026, 12, 5, 9, 30)]);

    await scheduler.undoDone(id);
    expect(gateway.alertsFor(reminderPayload(nextId)), isEmpty);
    expect(gateway.alertsFor(reminderPayload(id)), hasLength(2));
  });

  test('snooze posts one alert a day later and drops earlier ones', () async {
    now = DateTime(2026, 11, 2, 9, 31);
    final id = await scheduler.save(electricity());
    await scheduler.snooze(id);
    final alerts = gateway.alertsFor(reminderPayload(id));
    expect(alerts.map((a) => a.fireAt), [DateTime(2026, 11, 3, 9, 31), DateTime(2026, 11, 5, 9, 30)]);
    expect(alerts.first.id, notificationIdFor(id, kSnoozeSlot));
  });

  test('delete cancels; restore re-posts', () async {
    final id = await scheduler.save(electricity());
    await scheduler.delete(id);
    expect(gateway.scheduled, isEmpty);
    await scheduler.restore(id);
    expect(gateway.alertsFor(reminderPayload(id)), hasLength(2));
  });

  test('rescheduleAll drops stale reminder alerts and re-posts every pending reminder', () async {
    final keep = await scheduler.save(electricity());
    final quiet = await repository.save(electricity(days: const [0]));
    await repository.markDone(quiet);
    gateway.scheduled.clear();
    // A stale alert for a reminder that no longer exists.
    gateway.scheduled[7] = AlertRequest(
      id: 7, title: 'Old', body: '', fireAt: DateTime(2026, 12, 1), payload: reminderPayload('gone'), markPaidLabel: '', snoozeLabel: '', isMoney: true);

    final posted = await scheduler.rescheduleAll();
    expect(posted, 3, reason: 'two for Electricity and one for the spawned next occurrence');
    expect(gateway.scheduled.values.where((a) => a.payload == reminderPayload('gone')), isEmpty);
    expect(gateway.alertsFor(reminderPayload(keep)), hasLength(2));
  });

  test('alerts whose time has passed are not posted', () async {
    now = DateTime(2026, 11, 6);
    final id = await scheduler.save(electricity());
    expect(gateway.alertsFor(reminderPayload(id)), isEmpty);
  });

  test('permission state and request pass through', () async {
    gateway.notificationsAllowed = false;
    final service = NotificationService(gateway, buildAlert: (r, a) => alertRequestFor(r, a, english, moneyFormat: MoneyFormat.inr));
    expect((await service.checkPermission()).notificationsAllowed, isFalse);
    expect(await service.requestPermission(), isTrue);
    expect(gateway.permissionRequests, 1);
  });

  test('notificationLocalizations follows the saved choice, then the device, then English', () {
    expect(notificationLocalizations('hi').localeName, 'hi');
    expect(notificationLocalizations('', deviceLocale: const Locale('hi', 'IN')).localeName, 'hi');
    expect(notificationLocalizations('', deviceLocale: const Locale('fr')).localeName, 'en');
  });
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/core/notifications/notification_service.dart';
import 'package:hisab/core/notifications/reminder_alert_text.dart';
import 'package:hisab/core/notifications/reminder_payload.dart';
import 'package:hisab/core/notifications/reminder_scheduler.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/groups_repository.dart';
import 'package:hisab/data/repositories/reminders_repository.dart';
import 'package:hisab/data/repositories/settle_schedule_repository.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:hisab/domain/split/settle_reminder.dart';
import 'package:hisab/features/groups/settle_reminder_service.dart';
import 'package:hisab/features/groups/settle_schedule_tile.dart';

import '../core/fake_notification_gateway.dart';

void main() {
  late AppDatabase db;
  late GroupsRepository groups;
  late SettleScheduleRepository schedules;
  late FakeNotificationGateway gateway;
  late ReminderScheduler scheduler;
  late SettleReminderService service;
  var now = DateTime(2026, 10, 22, 10);
  final english = notificationLocalizations('en');
  const monthlyOnFirst = SettleReminderSchedule(frequency: RecurrenceFrequency.monthly, dayOfMonth: 1);

  setUp(() {
    now = DateTime(2026, 10, 22, 10);
    db = AppDatabase(NativeDatabase.memory());
    groups = GroupsRepository(db);
    schedules = SettleScheduleRepository(db);
    gateway = FakeNotificationGateway();
    scheduler = ReminderScheduler(
      reminders: RemindersRepository(db, clock: () => now),
      notifications: NotificationService(gateway, buildAlert: (r, a) => alertRequestFor(r, a, english, currencySymbol: '₹'), clock: () => now),
      settleSchedules: schedules,
      clock: () => now,
    );
    service = SettleReminderService(groups: groups, schedules: schedules, scheduler: scheduler, l10n: english, currencySymbol: '₹', clock: () => now);
  });

  tearDown(() => db.close());

  /// A flat where Ravi owes me [raviOwesMinor]; returns (groupId, raviId, meId).
  Future<(String, String, String)> flat({int raviOwesMinor = 50000}) async {
    final groupId = await groups.createGroup(name: 'Flat 302', icon: 'home', myName: 'Me', otherMembers: ['Ravi']);
    final members = await groups.getMembers(groupId);
    final me = members.firstWhere((m) => m.isMe).id;
    final ravi = members.firstWhere((m) => !m.isMe).id;
    if (raviOwesMinor > 0) {
      final entryId = newId();
      await EntriesRepository(db).saveEntry(
        EntriesRepository.newExpense(id: entryId, amountMinor: raviOwesMinor * 2, occurredAt: DateTime(2026, 10, 1), groupId: groupId, paidByMemberId: me, splitMethod: 'equal'),
        splits: [
          SplitsCompanion.insert(id: newId(), entryId: entryId, memberId: me, amountMinor: raviOwesMinor),
          SplitsCompanion.insert(id: newId(), entryId: entryId, memberId: ravi, amountMinor: raviOwesMinor),
        ],
      );
    }
    return (groupId, ravi, me);
  }

  group('SettleScheduleRepository', () {
    test('save stores the schedule as a pending reminder due next after now, and scheduleOf reads it back', () async {
      final row = await schedules.save('g1', monthlyOnFirst, now: now, text: (title: 'T', body: 'B'));
      expect(row.id, settleScheduleReminderId('g1'));
      expect(row.kind, kSettleScheduleKind);
      expect(row.groupId, 'g1');
      expect(row.status, ReminderStatus.pending);
      expect(row.dueAt, DateTime(2026, 11, 1, kSettleReminderHour));
      expect(row.notifyAtMinute, kSettleReminderHour * 60);
      final stored = await schedules.scheduleOf('g1');
      expect(stored?.frequency, RecurrenceFrequency.monthly);
      expect(stored?.dayOfMonth, 1);
      expect(stored?.memberId, isNull);
    });

    test('save over an existing schedule replaces it', () async {
      await schedules.save('g1', monthlyOnFirst, now: now);
      await schedules.save('g1', const SettleReminderSchedule(frequency: RecurrenceFrequency.weekly, weekday: DateTime.monday, memberId: 'm2'), now: now);
      final stored = await schedules.scheduleOf('g1');
      expect(stored?.frequency, RecurrenceFrequency.weekly);
      expect(stored?.weekday, DateTime.monday);
      expect(stored?.memberId, 'm2');
      expect(await schedules.liveRows(), hasLength(1));
    });

    test('remove turns it off and a later save brings it back', () async {
      await schedules.save('g1', monthlyOnFirst, now: now);
      await schedules.remove('g1', now: now);
      expect(await schedules.scheduleOf('g1'), isNull);
      expect(await schedules.liveRows(), isEmpty);
      await schedules.save('g1', monthlyOnFirst, now: now);
      expect(await schedules.scheduleOf('g1'), isNotNull);
    });

    test('schedulable leaves out a settled group (empty text)', () async {
      await schedules.save('g1', monthlyOnFirst, now: now, text: (title: 'T', body: 'B'));
      await schedules.save('g2', monthlyOnFirst, now: now);
      expect((await schedules.schedulable()).map((row) => row.groupId), ['g1']);
    });

    test('refreshRow rolls a passed reminder to its next date and rewrites the text', () async {
      final row = await schedules.save('g1', monthlyOnFirst, now: now, text: (title: 'Old', body: 'Old'));
      now = DateTime(2026, 11, 1, 12);
      final refreshed = await schedules.refreshRow(row, now: now, text: (title: 'New', body: 'Body'));
      expect(refreshed.dueAt, DateTime(2026, 12, 1, kSettleReminderHour));
      expect(refreshed.title, 'New');
      expect(refreshed.notes, 'Body');
    });

    test('refreshRow keeps a future date and writes nothing when the text is the same', () async {
      final row = await schedules.save('g1', monthlyOnFirst, now: now, text: (title: 'T', body: 'B'));
      final refreshed = await schedules.refreshRow(row, now: now.add(const Duration(days: 1)), text: (title: 'T', body: 'B'));
      expect(refreshed.dueAt, DateTime(2026, 11, 1, kSettleReminderHour));
      expect(refreshed.updatedAt, row.updatedAt);
    });

    test('settle-up schedules stay off the Reminders list', () async {
      await schedules.save('g1', monthlyOnFirst, now: now, text: (title: 'T', body: 'B'));
      expect(await RemindersRepository(db, clock: () => now).getSchedulable(), isEmpty);
    });
  });

  group('SettleReminderService', () {
    test('settleReminderTextFor words the balance about one member or everyone, and is null when settled', () async {
      final (groupId, ravi, _) = await flat();
      final detail = (await groups.getGroupDetail(groupId))!;
      expect(settleReminderTextFor(english, detail, memberId: ravi, currencySymbol: '₹'), (title: 'Settle up: Flat 302', body: 'Ravi owes you ₹500'));
      expect(settleReminderTextFor(english, detail, currencySymbol: '₹')?.body, 'Ravi owes you ₹500');
      final (settledId, _, _) = await flat(raviOwesMinor: 0);
      expect(settleReminderTextFor(english, (await groups.getGroupDetail(settledId))!, currencySymbol: '₹'), isNull);
    });

    test('setSchedule posts the alert at 9:00 on the next date and opens the group on tap', () async {
      final (groupId, ravi, _) = await flat();
      await service.setSchedule(groupId, SettleReminderSchedule(frequency: RecurrenceFrequency.monthly, dayOfMonth: 1, memberId: ravi));
      final payload = reminderPayload(settleScheduleReminderId(groupId));
      final alerts = gateway.alertsFor(payload);
      expect(alerts, hasLength(1));
      expect(alerts.single.fireAt, DateTime(2026, 11, 1, 9));
      expect(alerts.single.title, 'Settle up: Flat 302');
      expect(alerts.single.body, 'Ravi owes you ₹500');
      expect(alerts.single.isMoney, isFalse);
      expect(reminderLocationFor(payload: payload, actionId: null), '/groups/$groupId');
      expect(reminderLocationFor(payload: payload, actionId: kMarkPaidActionId), '/groups/$groupId');
      expect(reminderLocationFor(payload: payload, actionId: kSnoozeActionId), isNull);
    });

    test('turning it off cancels the alert', () async {
      final (groupId, _, _) = await flat();
      await service.setSchedule(groupId, monthlyOnFirst);
      await service.setSchedule(groupId, null);
      expect(gateway.alertsFor(reminderPayload(settleScheduleReminderId(groupId))), isEmpty);
    });

    test('a settled group keeps its schedule but posts nothing', () async {
      final (groupId, _, _) = await flat(raviOwesMinor: 0);
      await service.setSchedule(groupId, monthlyOnFirst);
      expect(await schedules.scheduleOf(groupId), isNotNull);
      expect(gateway.alertsFor(reminderPayload(settleScheduleReminderId(groupId))), isEmpty);
    });

    test('refreshGroup rewords the alert after the balance changes', () async {
      final (groupId, ravi, me) = await flat();
      await service.setSchedule(groupId, monthlyOnFirst);
      await groups.addSettlement(groupId: groupId, fromMemberId: ravi, toMemberId: me, amountMinor: 20000);
      await service.refreshGroup(groupId);
      expect(gateway.alertsFor(reminderPayload(settleScheduleReminderId(groupId))).single.body, 'Ravi owes you ₹300');
    });

    test('refreshAll then rescheduleAll rolls a passed schedule on and posts it again', () async {
      final (groupId, _, _) = await flat();
      await service.setSchedule(groupId, monthlyOnFirst);
      now = DateTime(2026, 11, 2, 8);
      await service.refreshAll();
      await scheduler.rescheduleAll();
      expect(gateway.alertsFor(reminderPayload(settleScheduleReminderId(groupId))).single.fireAt, DateTime(2026, 12, 1, 9));
    });

    test('snooze from the notification moves the alert a day on', () async {
      final (groupId, _, _) = await flat();
      await service.setSchedule(groupId, monthlyOnFirst);
      now = DateTime(2026, 11, 1, 9, 5);
      await scheduler.snooze(settleScheduleReminderId(groupId));
      final fireAt = gateway.alertsFor(reminderPayload(settleScheduleReminderId(groupId))).single.fireAt;
      expect(fireAt.isAfter(now), isTrue);
    });

    test('settleScheduleNudgeFor names people by their own names and is null when settled', () async {
      final (groupId, ravi, _) = await flat();
      final detail = (await groups.getGroupDetail(groupId))!;
      final nudge = settleScheduleNudgeFor(english, detail, SettleReminderSchedule(frequency: RecurrenceFrequency.monthly, dayOfMonth: 1, memberId: ravi), currencySymbol: '₹');
      expect(nudge, contains('Ravi'));
      expect(nudge, contains('₹500'));
      final (settledId, _, _) = await flat(raviOwesMinor: 0);
      expect(settleScheduleNudgeFor(english, (await groups.getGroupDetail(settledId))!, monthlyOnFirst, currencySymbol: '₹'), isNull);
    });
  });
}

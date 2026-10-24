import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/reminders/reminder_buckets.dart';
import 'package:hisab/domain/reminders/reminder_draft.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:hisab/domain/reminders/reminder_schedule.dart';

void main() {
  group('remind days before', () {
    test('parse drops junk and duplicates and sorts largest first', () {
      expect(parseRemindDaysBefore('0, 3,x,3,-1,7'), [7, 3, 0]);
      expect(parseRemindDaysBefore(''), isEmpty);
    });
    test('format round-trips', () => expect(formatRemindDaysBefore([0, 3, 3, 1]), '3,1,0'));
  });

  group('nextDueDate', () {
    test('once does not repeat', () => expect(nextDueDate(DateTime(2026, 1, 5), ReminderRepeat.once), isNull));
    test('weekly adds seven days', () => expect(nextDueDate(DateTime(2026, 12, 28), ReminderRepeat.weekly), DateTime(2027, 1, 4)));
    test('monthly clamps to month end and returns to the anchor day', () {
      final feb = nextDueDate(DateTime(2026, 1, 31), ReminderRepeat.monthly, anchorDay: 31)!;
      expect(feb, DateTime(2026, 2, 28));
      expect(nextDueDate(feb, ReminderRepeat.monthly, anchorDay: 31), DateTime(2026, 3, 31));
    });
    test('monthly without an anchor keeps the day', () => expect(nextDueDate(DateTime(2026, 11, 5), ReminderRepeat.monthly), DateTime(2026, 12, 5)));
    test('quarterly crosses the year', () => expect(nextDueDate(DateTime(2026, 11, 30), ReminderRepeat.quarterly, anchorDay: 30), DateTime(2027, 2, 28)));
    test('yearly handles 29 Feb', () => expect(nextDueDate(DateTime(2028, 2, 29), ReminderRepeat.yearly, anchorDay: 29), DateTime(2029, 2, 28)));
  });

  group('notificationIdFor', () {
    test('is stable, positive 31-bit and differs per slot', () {
      final first = notificationIdFor('abc', 0);
      expect(notificationIdFor('abc', 0), first);
      expect(first, inInclusiveRange(0, 0x7fffffff));
      expect(notificationIdFor('abc', 3), isNot(first));
      expect(notificationIdFor('abd', 0), isNot(first));
    });
    test('allNotificationIdsFor covers stored days, the defaults and the snooze slot', () {
      final ids = allNotificationIdsFor('r', [90]);
      expect(ids, containsAll([notificationIdFor('r', 90), notificationIdFor('r', 0), notificationIdFor('r', 7), notificationIdFor('r', kSnoozeSlot)]));
    });
  });

  group('planAlerts', () {
    final due = DateTime(2026, 11, 5);
    List<PlannedAlert> plan({List<int> days = const [3, 0], int? minute = 540, DateTime? snoozedUntil, required DateTime now}) =>
        planAlerts(reminderId: 'r1', dueAt: due, daysBefore: days, notifyAtMinute: minute, snoozedUntil: snoozedUntil, now: now);

    test('one alert per day before, at the chosen time, earliest first', () {
      final alerts = plan(now: DateTime(2026, 10, 22));
      expect(alerts.map((a) => a.fireAt), [DateTime(2026, 11, 2, 9), DateTime(2026, 11, 5, 9)]);
      expect(alerts.map((a) => a.daysBefore), [3, 0]);
      expect(alerts.first.notificationId, notificationIdFor('r1', 3));
    });
    test('past alerts are dropped', () {
      expect(plan(now: DateTime(2026, 11, 3)).map((a) => a.daysBefore), [0]);
      expect(plan(now: DateTime(2026, 11, 5, 9, 1)), isEmpty);
    });
    test('no time means no alerts', () => expect(plan(minute: null, now: DateTime(2026, 10, 1)), isEmpty));
    test('a snooze replaces alerts before it and adds its own', () {
      final alerts = plan(now: DateTime(2026, 11, 2, 9, 5), snoozedUntil: DateTime(2026, 11, 3, 9, 5));
      expect(alerts.map((a) => a.daysBefore), [kSnoozeSlot, 0]);
      expect(alerts.first.fireAt, DateTime(2026, 11, 3, 9, 5));
    });
    test('a snooze past the due day still fires (overdue nudge)', () {
      final alerts = plan(now: DateTime(2026, 11, 5, 10), snoozedUntil: DateTime(2026, 11, 6, 10));
      expect(alerts, [PlannedAlert(notificationId: notificationIdFor('r1', kSnoozeSlot), fireAt: DateTime(2026, 11, 6, 10), daysBefore: kSnoozeSlot)]);
    });
    test('an expired snooze is ignored', () => expect(plan(now: DateTime(2026, 11, 4), snoozedUntil: DateTime(2026, 11, 3)).map((a) => a.daysBefore), [0]));
  });

  group('daysUntilDue and buckets', () {
    final now = DateTime(2026, 10, 22, 23, 30);
    test('counts calendar days, ignoring time of day', () {
      expect(daysUntilDue(DateTime(2026, 10, 23), now), 1);
      expect(daysUntilDue(DateTime(2026, 10, 22), now), 0);
      expect(daysUntilDue(DateTime(2026, 10, 20, 23), now), -2);
    });
    test('across a daylight-saving change', () => expect(daysUntilDue(DateTime(2026, 11, 2), DateTime(2026, 10, 30)), 3));
    test('bucketFor', () {
      expect(bucketFor(DateTime(2026, 10, 21), now), ReminderBucket.overdue);
      expect(bucketFor(DateTime(2026, 10, 29), now), ReminderBucket.thisWeek);
      expect(bucketFor(DateTime(2026, 10, 30), now), ReminderBucket.later);
    });
    test('groupByBucket keeps order and drops empty buckets', () {
      final grouped = groupByBucket([DateTime(2026, 10, 20), DateTime(2026, 12, 1), DateTime(2026, 10, 21)], (d) => d, now);
      expect(grouped.keys, [ReminderBucket.overdue, ReminderBucket.later]);
      expect(grouped[ReminderBucket.overdue], [DateTime(2026, 10, 20), DateTime(2026, 10, 21)]);
    });
  });

  group('ReminderDraft', () {
    test('needs a title and a non-negative amount', () {
      expect(ReminderDraft(kind: ReminderKind.bill, title: ' ', dueAt: DateTime(2026)).error, ReminderDraftError.missingTitle);
      expect(ReminderDraft(kind: ReminderKind.bill, title: 'Rent', amountMinor: -1, dueAt: DateTime(2026)).error, ReminderDraftError.negativeAmount);
      expect(ReminderDraft(kind: ReminderKind.document, title: 'Passport', dueAt: DateTime(2026)).error, isNull);
    });
    test('repeatDay only for month-based repeats', () {
      final due = DateTime(2026, 1, 31, 15);
      expect(ReminderDraft(kind: ReminderKind.emi, title: 'EMI', dueAt: due, repeat: ReminderRepeat.monthly).repeatDay, 31);
      expect(ReminderDraft(kind: ReminderKind.emi, title: 'EMI', dueAt: due, repeat: ReminderRepeat.weekly).repeatDay, isNull);
      expect(ReminderDraft(kind: ReminderKind.emi, title: 'EMI', dueAt: due).dueDay, DateTime(2026, 1, 31));
    });
  });

  test('kinds round-trip and only documents and custom are not money', () {
    for (final kind in ReminderKind.values) {
      expect(ReminderKind.fromKey(kind.key), kind);
    }
    expect(ReminderKind.fromKey('settle_up'), isNull);
    expect(ReminderKind.values.where((k) => !k.isMoney), [ReminderKind.document, ReminderKind.custom]);
    expect(ReminderRepeat.fromKey('nonsense'), ReminderRepeat.once);
  });

  group('planOccurrenceAlerts', () {
    final now = DateTime(2026, 10, 26, 10);
    final weeks = [for (var day = 26; day <= 47; day += 7) DateTime(2026, 10, day, 9)];

    test('posts every future occurrence with its own id and drops past ones', () {
      final alerts = planOccurrenceAlerts(reminderId: 'settle_schedule_g1', fireTimes: weeks, now: now);
      expect(alerts.map((alert) => alert.fireAt), weeks.skip(1));
      expect(alerts.map((alert) => alert.notificationId).toSet(), hasLength(3));
      expect(allNotificationIdsFor('settle_schedule_g1', const [0]), containsAll(alerts.map((alert) => alert.notificationId)));
    });

    test('a snooze replaces the occurrences before it and keeps later ones', () {
      final snoozedUntil = DateTime(2026, 11, 3, 9);
      final alerts = planOccurrenceAlerts(reminderId: 'settle_schedule_g1', fireTimes: weeks, snoozedUntil: snoozedUntil, now: now);
      expect(alerts.map((alert) => alert.fireAt), [snoozedUntil, weeks[2], weeks[3]]);
      expect(alerts.first.daysBefore, kSnoozeSlot);
    });
  });
}

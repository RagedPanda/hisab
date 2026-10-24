import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/split/debt_simplifier.dart';
import 'package:hisab/domain/split/settle_reminder.dart';
import 'package:hisab/features/groups/group_detail_screen.dart' show groupDetailInitialTab;

void main() {
  group('nextSettleReminderAt', () {
    const onTheFirst = SettleReminderSchedule(frequency: RecurrenceFrequency.monthly, dayOfMonth: 1, memberId: 'ravi');

    test('fires at 9 on the next 1st', () {
      expect(nextSettleReminderAt(onTheFirst, now: DateTime(2026, 10, 22, 14)), DateTime(2026, 11, 1, 9));
    });

    test('later today when the day has come but the hour has not', () {
      expect(nextSettleReminderAt(onTheFirst, now: DateTime(2026, 11, 1, 8)), DateTime(2026, 11, 1, 9));
    });

    test('next month once today\'s reminder has fired', () {
      expect(nextSettleReminderAt(onTheFirst, now: DateTime(2026, 11, 1, 9)), DateTime(2026, 12, 1, 9));
    });

    test('the last day of the month follows short months', () {
      const monthEnd = SettleReminderSchedule(frequency: RecurrenceFrequency.monthly, dayOfMonth: kLastDayOfMonth);
      expect(nextSettleReminderAt(monthEnd, now: DateTime(2027, 2, 3)), DateTime(2027, 2, 28, 9));
    });

    test('weekly on a weekday', () {
      const sundays = SettleReminderSchedule(frequency: RecurrenceFrequency.weekly, weekday: DateTime.sunday);
      // 22 Oct 2026 is a Thursday.
      expect(nextSettleReminderAt(sundays, now: DateTime(2026, 10, 22, 10)), DateTime(2026, 10, 25, 9));
      expect(nextSettleReminderAt(sundays, now: DateTime(2026, 10, 25, 10)), DateTime(2026, 11, 1, 9));
    });
  });

  group('settleReminderFacts', () {
    const transfers = [Transfer('ravi', 'me', 120000), Transfer('priya', 'me', 30000), Transfer('me', 'amit', 5000), Transfer('ravi', 'amit', 100)];

    test('splits my side of the transfers into owed to me and I owe', () {
      final facts = settleReminderFacts(transfers, myMemberId: 'me');
      expect(facts.owedToMeMinor, 150000);
      expect(facts.iOweMinor, 5000);
      expect(facts.isSettled, isFalse);
    });

    test('a named member limits the facts to them', () {
      final facts = settleReminderFacts(transfers, myMemberId: 'me', withMemberId: 'ravi');
      expect(facts.owedToMe, const [Transfer('ravi', 'me', 120000)]);
      expect(facts.iOwe, isEmpty);
    });

    test('settled when nothing involves me or I am not in the group', () {
      expect(settleReminderFacts(transfers, myMemberId: 'me', withMemberId: 'nobody').isSettled, isTrue);
      expect(settleReminderFacts(transfers, myMemberId: null).isSettled, isTrue);
    });
  });

  group('stored schedule', () {
    test('round-trips monthly, last-day and weekly schedules', () {
      for (final schedule in const [
        SettleReminderSchedule(frequency: RecurrenceFrequency.monthly, dayOfMonth: 1, memberId: 'ravi'),
        SettleReminderSchedule(frequency: RecurrenceFrequency.monthly, dayOfMonth: kLastDayOfMonth),
        SettleReminderSchedule(frequency: RecurrenceFrequency.weekly, weekday: DateTime.friday),
      ]) {
        final stored = settleScheduleFromStored(repeat: settleScheduleRepeat(schedule), repeatDay: settleScheduleRepeatDay(schedule), memberId: schedule.memberId);
        expect(stored, schedule);
      }
    });

    test('ignores repeats this feature never writes', () {
      expect(settleScheduleFromStored(repeat: 'once'), isNull);
    });

    test('the reminder id names its group', () {
      expect(groupIdOfSettleSchedule(settleScheduleReminderId('flat')), 'flat');
      expect(groupIdOfSettleSchedule('some-bill'), isNull);
      expect(groupIdOfSettleSchedule('settle_schedule_'), isNull);
    });
  });

  group('settle-up alerts ahead', () {
    const weeklyMonday = SettleReminderSchedule(frequency: RecurrenceFrequency.weekly, weekday: DateTime.monday);
    const onTheFirst = SettleReminderSchedule(frequency: RecurrenceFrequency.monthly, dayOfMonth: 1);

    test('settleReminderTimesFrom lists the next weeks or months from the first', () {
      final firstMonday = DateTime(2026, 10, 26, kSettleReminderHour);
      expect(settleReminderTimesFrom(weeklyMonday, firstMonday), [
        firstMonday,
        DateTime(2026, 11, 2, kSettleReminderHour),
        DateTime(2026, 11, 9, kSettleReminderHour),
        DateTime(2026, 11, 16, kSettleReminderHour),
      ]);
      expect(settleReminderTimesFrom(onTheFirst, DateTime(2026, 11, 1, kSettleReminderHour), count: 2), [
        DateTime(2026, 11, 1, kSettleReminderHour),
        DateTime(2026, 12, 1, kSettleReminderHour),
      ]);
    });

    test('settleAlertTimesOfRow reads stored rows and ignores other reminders', () {
      final due = DateTime(2026, 10, 26, kSettleReminderHour);
      expect(settleAlertTimesOfRow(reminderId: settleScheduleReminderId('g1'), repeat: 'weekly', repeatDay: DateTime.monday, dueAt: due), hasLength(kSettleAlertsAhead));
      expect(settleAlertTimesOfRow(reminderId: 'rent', repeat: 'weekly', repeatDay: DateTime.monday, dueAt: due), isNull);
      expect(settleAlertTimesOfRow(reminderId: settleScheduleReminderId('g1'), repeat: 'yearly', dueAt: due), isNull);
    });

    test('settleUpLocationFor opens the group on Balances', () {
      final location = Uri.parse(settleUpLocationFor('g1'));
      expect(location.path, '/groups/g1');
      expect(groupDetailInitialTab(location.queryParameters['tab']), 1, reason: 'Expenses, Balances, Members');
      expect(groupDetailInitialTab(null), 0);
      expect(groupDetailInitialTab('members'), 2);
    });
  });
}

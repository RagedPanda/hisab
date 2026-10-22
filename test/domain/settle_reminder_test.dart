import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/split/debt_simplifier.dart';
import 'package:hisab/domain/split/settle_reminder.dart';

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
}

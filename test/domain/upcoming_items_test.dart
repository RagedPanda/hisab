import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/upcoming/upcoming_items.dart';

void main() {
  final today = DateTime(2026, 10, 22, 15, 30);

  RecurringOccurrenceInput rule(String id, DateTime dueAt, {int? amount, bool income = false}) =>
      RecurringOccurrenceInput(ruleId: id, title: id, dueAt: dueAt, amountMinor: amount, isIncome: income);
  ReminderInput reminder(String id, DateTime dueAt, {String? recurringId, bool done = false, int? amount}) =>
      ReminderInput(id: id, title: id, dueAt: dueAt, recurringId: recurringId, isDone: done, amountMinor: amount);

  group('overdue and today', () {
    test('a pending reminder from last week is overdue and sorts first', () {
      final items = upcomingWithin(
        today: today,
        window: UpcomingWindow.week,
        reminders: [reminder('rent', DateTime(2026, 10, 15)), reminder('emi', DateTime(2026, 10, 24))],
      );
      expect(items.map((item) => item.sourceId), ['rent', 'emi']);
      expect(items.first.timing, UpcomingTiming.overdue);
      expect(items.first.daysAway, -7);
      expect(items.last.timing, UpcomingTiming.soon);
    });

    test('an item earlier today is due today, not overdue', () {
      final items = upcomingWithin(today: today, window: UpcomingWindow.week, recurring: [rule('netflix', DateTime(2026, 10, 22, 9))]);
      expect(items.single.timing, UpcomingTiming.today);
      expect(items.single.isOverdue, isFalse);
    });

    test('done reminders never show, even when overdue', () {
      final items = upcomingWithin(today: today, window: UpcomingWindow.month, reminders: [reminder('paid', DateTime(2026, 10, 10), done: true)]);
      expect(items, isEmpty);
    });
  });

  group('next 7 and 30 days', () {
    final occurrences = [
      rule('day7', DateTime(2026, 10, 29)),
      rule('day8', DateTime(2026, 10, 30)),
      rule('day30', DateTime(2026, 11, 21)),
      rule('day31', DateTime(2026, 11, 22)),
    ];

    test('the week window runs through day 7', () {
      final items = upcomingWithin(today: today, window: UpcomingWindow.week, recurring: occurrences);
      expect(items.map((item) => item.sourceId), ['day7']);
    });

    test('the month window runs through day 30', () {
      final items = upcomingWithin(today: today, window: UpcomingWindow.month, recurring: occurrences);
      expect(items.map((item) => item.sourceId), ['day7', 'day8', 'day30']);
    });

    test('window names round-trip and default to the week', () {
      expect(UpcomingWindow.parse('month'), UpcomingWindow.month);
      expect(UpcomingWindow.parse(null), UpcomingWindow.week);
      expect(UpcomingWindow.parse('bogus'), UpcomingWindow.week);
    });
  });

  group('merging sources', () {
    test('all three sources merge into one list ordered by due date', () {
      final items = upcomingWithin(
        today: today,
        window: UpcomingWindow.month,
        recurring: [rule('salary', DateTime(2026, 11, 1), income: true)],
        reminders: [reminder('insurance', DateTime(2026, 10, 25))],
        cardDues: [CardDueInput(accountId: 'hdfc', title: 'HDFC card', dueAt: DateTime(2026, 10, 28), amountMinor: 1250000)],
      );
      expect(items.map((item) => item.source), [UpcomingSource.reminder, UpcomingSource.cardDue, UpcomingSource.recurring]);
    });

    test('card dues are optional', () {
      final items = upcomingWithin(today: today, window: UpcomingWindow.week, reminders: [reminder('bill', DateTime(2026, 10, 23))]);
      expect(items.single.source, UpcomingSource.reminder);
    });

    test('a reminder for a rule replaces that rule occurrence on the same day only', () {
      final items = upcomingWithin(
        today: today,
        window: UpcomingWindow.month,
        recurring: [rule('rent', DateTime(2026, 11, 1, 9)), rule('rent', DateTime(2026, 10, 25, 9))],
        reminders: [reminder('rent-reminder', DateTime(2026, 11, 1), recurringId: 'rent')],
      );
      expect(items.map((item) => '${item.source.name}:${item.sourceId}'), ['recurring:rent', 'reminder:rent-reminder']);
      expect(items.last.recurringId, 'rent');
    });

    test('same day ties break by time, then source, then title', () {
      final items = upcomingWithin(
        today: today,
        window: UpcomingWindow.week,
        recurring: [rule('b', DateTime(2026, 10, 24)), rule('a', DateTime(2026, 10, 24)), rule('late', DateTime(2026, 10, 24, 20))],
        reminders: [reminder('r', DateTime(2026, 10, 24))],
      );
      expect(items.map((item) => item.sourceId), ['a', 'b', 'r', 'late']);
    });
  });

  group('calendar month', () {
    test('keeps only the month asked for, without overdue carry-over', () {
      final items = upcomingInMonth(
        today: today,
        month: DateTime(2026, 11, 15),
        reminders: [reminder('old', DateTime(2026, 10, 1)), reminder('first', DateTime(2026, 11, 1)), reminder('last', DateTime(2026, 11, 30, 23))],
        recurring: [rule('december', DateTime(2026, 12, 1))],
      );
      expect(items.map((item) => item.sourceId), ['first', 'last']);
    });

    test('a past month still shows what was due then', () {
      final items = upcomingInMonth(today: today, month: DateTime(2026, 9), reminders: [reminder('september', DateTime(2026, 9, 5))]);
      expect(items.single.isOverdue, isTrue);
    });

    test('groups items by day in order', () {
      final byDay = upcomingByDay(
        upcomingInMonth(
          today: today,
          month: today,
          recurring: [rule('a', DateTime(2026, 10, 25, 8)), rule('b', DateTime(2026, 10, 25, 18)), rule('c', DateTime(2026, 10, 30))],
        ),
      );
      expect(byDay.keys, [DateTime(2026, 10, 25), DateTime(2026, 10, 30)]);
      expect(byDay[DateTime(2026, 10, 25)]!.map((item) => item.sourceId), ['a', 'b']);
    });
  });

  group('summary', () {
    test('counts overdue and sums outgoing amounts in the currency', () {
      final items = upcomingWithin(
        today: today,
        window: UpcomingWindow.week,
        recurring: [rule('salary', DateTime(2026, 10, 25), amount: 5000000, income: true), rule('rent', DateTime(2026, 10, 26), amount: 2000000)],
        reminders: [reminder('late', DateTime(2026, 10, 20), amount: 50000), reminder('unknown', DateTime(2026, 10, 23))],
      );
      final summary = summariseUpcoming(items);
      expect(summary.overdueCount, 1);
      expect(summary.dueOutMinor, 2050000);
    });
  });
}

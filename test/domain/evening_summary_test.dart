import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/notifications/evening_summary.dart';
import 'package:hisab/domain/upcoming/upcoming_items.dart';

void main() {
  final day = DateTime(2026, 10, 29);

  group('buildEveningSummary', () {
    test('counts outgoing items due from today through 3 days later', () {
      final summary = buildEveningSummary(
        day: day,
        spentMinor: 45000,
        reviewCount: 2,
        currency: 'INR',
        reminders: [
          ReminderInput(id: 'rent', title: 'Rent', dueAt: DateTime(2026, 10, 29), amountMinor: 1500000),
          ReminderInput(id: 'power', title: 'Power', dueAt: DateTime(2026, 11, 1), amountMinor: 185000),
          ReminderInput(id: 'later', title: 'Insurance', dueAt: DateTime(2026, 11, 2), amountMinor: 900000),
          ReminderInput(id: 'late', title: 'Overdue', dueAt: DateTime(2026, 10, 27), amountMinor: 1000),
          ReminderInput(id: 'paid', title: 'Paid', dueAt: DateTime(2026, 10, 30), amountMinor: 1000, isDone: true),
        ],
        recurring: [
          RecurringOccurrenceInput(ruleId: 'salary', title: 'Salary', dueAt: DateTime(2026, 10, 30), amountMinor: 9000000, isIncome: true),
          RecurringOccurrenceInput(ruleId: 'netflix', title: 'Netflix', dueAt: DateTime(2026, 10, 31), amountMinor: 64900, isSubscription: true),
        ],
      );

      expect(summary.spentMinor, 45000);
      expect(summary.reviewCount, 2);
      expect(summary.dueCount, 3, reason: 'rent, power and Netflix; not later, overdue, paid or income');
      expect(summary.dueMinor, 1500000 + 185000 + 64900);
    });

    test('items in another currency count but leave the amount alone', () {
      final summary = buildEveningSummary(
        day: day,
        spentMinor: 0,
        reviewCount: 0,
        currency: 'INR',
        reminders: [ReminderInput(id: 'visa', title: 'Visa fee', dueAt: DateTime(2026, 10, 30), amountMinor: 16000, currency: 'USD')],
      );
      expect(summary.dueCount, 1);
      expect(summary.dueMinor, 0);
    });
  });

  group('nextEveningTimes', () {
    test('starts tonight while the time is still ahead', () {
      expect(nextEveningTimes(now: DateTime(2026, 10, 29, 18), minuteOfDay: 21 * 60), [
        DateTime(2026, 10, 29, 21),
        DateTime(2026, 10, 30, 21),
        DateTime(2026, 10, 31, 21),
      ]);
    });

    test('starts tomorrow once the time has passed, across a month end', () {
      expect(nextEveningTimes(now: DateTime(2026, 10, 31, 21), minuteOfDay: 21 * 60, count: 2), [DateTime(2026, 11, 1, 21), DateTime(2026, 11, 2, 21)]);
    });

    test('keeps the minutes', () {
      expect(nextEveningTimes(now: DateTime(2026, 10, 29, 8), minuteOfDay: 20 * 60 + 45, count: 1), [DateTime(2026, 10, 29, 20, 45)]);
    });
  });

  test('a stored minute is kept within the day', () {
    expect(clampMinuteOfDay(-5), 0);
    expect(clampMinuteOfDay(9000), 24 * 60 - 1);
    expect(clampMinuteOfDay(kDefaultEveningSummaryMinute), 21 * 60);
  });
}

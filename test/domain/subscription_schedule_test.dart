import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/subscriptions/subscription_schedule.dart';
import 'package:hisab/domain/subscriptions/subscription_templates.dart';

void main() {
  final today = DateTime(2026, 10, 23, 15);
  const monthly = SubscriptionCycle(RecurrenceFrequency.monthly, 1);

  test('a renewal date in the past rolls forward to the next renewal on or after today', () {
    final schedule = subscriptionScheduleFrom(renewalDate: DateTime(2024, 3, 5), cycle: monthly, today: today, hour: 9);
    expect(schedule.start, DateTime(2026, 11, 5, 9));
    expect(schedule.dayOfMonth, 5);
  });

  test('a past renewal that falls on today renews today', () {
    final schedule = subscriptionScheduleFrom(renewalDate: DateTime(2026, 7, 23), cycle: monthly, today: today, hour: 9);
    expect(schedule.start, DateTime(2026, 10, 23, 9));
  });

  test('today and future dates are kept as they are', () {
    expect(subscriptionScheduleFrom(renewalDate: DateTime(2026, 10, 23), cycle: monthly, today: today).start, DateTime(2026, 10, 23));
    expect(subscriptionScheduleFrom(renewalDate: DateTime(2026, 12, 1), cycle: monthly, today: today).start, DateTime(2026, 12, 1));
  });

  test('a 28-day pack keeps its phase from the past start', () {
    const pack = SubscriptionCycle(RecurrenceFrequency.daily, 28);
    final schedule = subscriptionScheduleFrom(renewalDate: DateTime(2026, 9, 1), cycle: pack, today: today);
    // 1 Sep + 28 = 29 Sep, + 28 = 27 Oct.
    expect(schedule.start, DateTime(2026, 10, 27));
    expect(schedule.dayOfMonth, isNull);
  });

  test('quarterly and yearly cycles step by their interval from the anchor', () {
    const quarterly = SubscriptionCycle(RecurrenceFrequency.monthly, 3);
    expect(subscriptionScheduleFrom(renewalDate: DateTime(2026, 1, 10), cycle: quarterly, today: today).start, DateTime(2027, 1, 10));
    const yearly = SubscriptionCycle(RecurrenceFrequency.yearly, 1);
    expect(subscriptionScheduleFrom(renewalDate: DateTime(2022, 11, 2), cycle: yearly, today: today).start, DateTime(2026, 11, 2));
  });

  test('a month-end anchor stays on month ends after rolling forward', () {
    final schedule = subscriptionScheduleFrom(renewalDate: DateTime(2026, 1, 31), cycle: monthly, today: DateTime(2026, 11, 2));
    expect(schedule.start, DateTime(2026, 11, 30));
    expect(schedule.dayOfMonth, 31);
  });

  test('a weekly subscription keeps its weekday', () {
    const weekly = SubscriptionCycle(RecurrenceFrequency.weekly, 1);
    final schedule = subscriptionScheduleFrom(renewalDate: DateTime(2026, 10, 5), cycle: weekly, today: today);
    expect(schedule.start, DateTime(2026, 10, 26));
    expect(schedule.weekday, DateTime.monday);
  });

  test('renewal dates go back at most five years', () {
    expect(earliestSubscriptionRenewal(DateTime(2026, 10, 23)), DateTime(2021, 10, 23));
  });
}

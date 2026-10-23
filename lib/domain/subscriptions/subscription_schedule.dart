/// Where a subscription's recurring schedule starts. Pure: the caller passes
/// today, so a renewal date in the past is unit-testable.
library;

import '../../core/dates.dart';
import '../recurring/recurrence.dart';
import 'subscription_templates.dart';

/// How far back a subscription's renewal date may be entered.
const kSubscriptionMaxYearsBack = 5;

/// Earliest renewal date the form accepts on [today].
DateTime earliestSubscriptionRenewal(DateTime today) => DateTime(today.year - kSubscriptionMaxYearsBack, today.month, today.day);

/// The rule start and anchors for a subscription that renewed (or will renew)
/// on [renewalDate] and repeats every [cycle].
///
/// A past date only anchors the schedule: the start rolls forward to the
/// first renewal on or after [today], so saving never back-posts charges
/// for cycles that already went by. The anchor's day of month (or weekday)
/// is kept, so a plan renewing on the 31st stays on month ends.
({DateTime start, int? dayOfMonth, int? weekday}) subscriptionScheduleFrom({
  required DateTime renewalDate,
  required SubscriptionCycle cycle,
  required DateTime today,
  int hour = 0,
  int minute = 0,
  int monthStartDay = 1,
}) {
  final anchor = DateTime(renewalDate.year, renewalDate.month, renewalDate.day, hour, minute);
  final anchoredOnDay = cycle.frequency == RecurrenceFrequency.monthly || cycle.frequency == RecurrenceFrequency.yearly;
  final dayOfMonth = anchoredOnDay ? anchor.day : null;
  final weekday = cycle.frequency == RecurrenceFrequency.weekly ? anchor.weekday : null;
  final spec = RecurrenceSpec(frequency: cycle.frequency, start: anchor, interval: cycle.interval, dayOfMonth: dayOfMonth, weekday: weekday);
  final firstDay = startOfDay(today);
  var renewal = firstOccurrence(spec, monthStartDay: monthStartDay);
  while (startOfDay(renewal).isBefore(firstDay)) {
    renewal = nextAfter(spec, renewal, monthStartDay: monthStartDay);
  }
  return (start: renewal, dayOfMonth: dayOfMonth, weekday: weekday);
}

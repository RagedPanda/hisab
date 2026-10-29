/// The optional evening summary: what it says and when it fires. Pure: the
/// caller passes the day's figures and the clock.
library;

import '../upcoming/upcoming_items.dart';

/// 9 pm, as minutes after midnight.
const int kDefaultEveningSummaryMinute = 21 * 60;

/// Bills due from the summary's day through this many days later are counted.
const int kEveningSummaryDueDays = 3;

/// Evenings posted ahead, so a summary still arrives on days the app is not
/// opened. Each is refreshed whenever the app opens or goes to the background.
const int kEveningSummaryNightsAhead = 3;

/// The figures one evening's summary reports.
class EveningSummary {
  const EveningSummary({required this.spentMinor, required this.reviewCount, required this.dueCount, required this.dueMinor});

  /// My spend on the day, in the home currency's minor units.
  final int spentMinor;

  /// Bank SMS waiting for review.
  final int reviewCount;

  /// Outgoing bills and other upcoming items due within [kEveningSummaryDueDays].
  final int dueCount;

  /// Known amounts of those items in the home currency.
  final int dueMinor;
}

/// The summary for [day]: [spentMinor] spent that day, [reviewCount] SMS to
/// review, and the outgoing items of [upcoming] due from [day] through
/// [kEveningSummaryDueDays] days later (income and overdue items left out).
EveningSummary buildEveningSummary({
  required DateTime day,
  required int spentMinor,
  required int reviewCount,
  required String currency,
  List<RecurringOccurrenceInput> recurring = const [],
  List<ReminderInput> reminders = const [],
  List<CardDueInput> cardDues = const [],
}) {
  final due = mergeUpcoming(
    today: day,
    throughDay: kEveningSummaryDueDays,
    includeOverdue: false,
    recurring: recurring,
    reminders: reminders,
    cardDues: cardDues,
  ).where((item) => !item.isIncome).toList();
  return EveningSummary(
    spentMinor: spentMinor,
    reviewCount: reviewCount,
    dueCount: due.length,
    dueMinor: summariseUpcoming(due, currency: currency).dueOutMinor,
  );
}

/// The next [count] times the summary fires after [now], at [minuteOfDay]
/// (minutes after local midnight) on consecutive days.
List<DateTime> nextEveningTimes({required DateTime now, required int minuteOfDay, int count = kEveningSummaryNightsAhead}) {
  final todayAt = DateTime(now.year, now.month, now.day, minuteOfDay ~/ 60, minuteOfDay % 60);
  final first = todayAt.isAfter(now) ? 0 : 1;
  return [for (var offset = first; offset < first + count; offset++) DateTime(now.year, now.month, now.day + offset, minuteOfDay ~/ 60, minuteOfDay % 60)];
}

/// A minute of the day kept within 00:00..23:59.
int clampMinuteOfDay(int minute) => minute.clamp(0, 24 * 60 - 1);

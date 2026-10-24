/// Pure schedule maths for recurring entries. No I/O and no clock: every
/// function takes the dates it needs, so month ends, leap years and the
/// salary-month setting are all unit-testable.
///
/// A schedule is anchored on a stored day of month (or weekday), never on the
/// previous occurrence, so a rule on the 31st goes 31 Jan, 28 Feb, 31 Mar
/// instead of drifting to the 28th for the rest of the year.
library;

import '../../core/dates.dart';

enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  static RecurrenceFrequency parse(String value) =>
      RecurrenceFrequency.values.firstWhere((frequency) => frequency.name == value, orElse: () => RecurrenceFrequency.monthly);
}

/// [RecurrenceSpec.dayOfMonth] value for "the last day of the month".
const int kLastDayOfMonth = -1;

/// [RecurrenceSpec.dayOfMonth] value for "the day my month starts" (the
/// salary-month setting), resolved with the `monthStartDay` argument.
const int kMonthStartDayOfMonth = 0;

/// Upper bound on occurrences produced in one call, so a daily rule left
/// alone for years can never stall the app while catching up.
const int kMaxCatchUp = 400;

/// When and how often a rule repeats, plus where it stops.
class RecurrenceSpec {
  const RecurrenceSpec({
    required this.frequency,
    required this.start,
    this.interval = 1,
    this.dayOfMonth,
    this.weekday,
    this.endDate,
    this.maxCount,
  });

  final RecurrenceFrequency frequency;

  /// Every [interval] days, weeks, months or years (1 = every one).
  final int interval;

  /// First possible occurrence; its time of day is the time every
  /// occurrence is recorded at, and for yearly rules its month is the month.
  final DateTime start;

  /// 1..31 (clamped to short months), [kLastDayOfMonth] or
  /// [kMonthStartDayOfMonth]; null means the start date's day.
  final int? dayOfMonth;

  /// ISO weekday 1 (Monday)..7 for weekly rules; null means the start's.
  final int? weekday;

  /// Last day an occurrence may fall on, inclusive.
  final DateTime? endDate;

  /// How many occurrences the rule produces in total; null = no limit.
  final int? maxCount;

  int get _step => interval < 1 ? 1 : interval;
  int get _weekday => weekday ?? start.weekday;
  int get _dayOfMonth => dayOfMonth ?? start.day;
}

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// The calendar day [dayOfMonth] means in [year]/[month].
int resolveDayOfMonth(int dayOfMonth, int year, int month, {int monthStartDay = 1}) {
  final length = daysInMonth(year, month);
  if (dayOfMonth == kLastDayOfMonth) return length;
  if (dayOfMonth == kMonthStartDayOfMonth) return monthStartDay.clamp(1, length);
  return dayOfMonth.clamp(1, length);
}

DateTime _at(RecurrenceSpec spec, int year, int month, int day) => DateTime(year, month, day, spec.start.hour, spec.start.minute);

DateTime _inMonth(RecurrenceSpec spec, int year, int month, int monthStartDay) {
  final normalised = DateTime(year, month);
  return _at(spec, normalised.year, normalised.month, resolveDayOfMonth(spec._dayOfMonth, normalised.year, normalised.month, monthStartDay: monthStartDay));
}

/// First occurrence on or after the calendar day of [from] (time ignored).
DateTime firstOnOrAfter(RecurrenceSpec spec, DateTime from, {int monthStartDay = 1}) {
  final day = startOfDay(from);
  switch (spec.frequency) {
    case RecurrenceFrequency.daily:
      return _at(spec, day.year, day.month, day.day);
    case RecurrenceFrequency.weekly:
      final offset = (spec._weekday - day.weekday) % 7;
      return _at(spec, day.year, day.month, day.day + offset);
    case RecurrenceFrequency.monthly:
      final candidate = _inMonth(spec, day.year, day.month, monthStartDay);
      return startOfDay(candidate).isBefore(day) ? _inMonth(spec, day.year, day.month + 1, monthStartDay) : candidate;
    case RecurrenceFrequency.yearly:
      final candidate = _inMonth(spec, day.year, spec.start.month, monthStartDay);
      return startOfDay(candidate).isBefore(day) ? _inMonth(spec, day.year + 1, spec.start.month, monthStartDay) : candidate;
  }
}

/// The first occurrence of the schedule.
DateTime firstOccurrence(RecurrenceSpec spec, {int monthStartDay = 1}) => firstOnOrAfter(spec, spec.start, monthStartDay: monthStartDay);

/// The occurrence after [occurrence], ignoring end conditions.
DateTime nextAfter(RecurrenceSpec spec, DateTime occurrence, {int monthStartDay = 1}) {
  final step = spec._step;
  switch (spec.frequency) {
    case RecurrenceFrequency.daily:
      return _at(spec, occurrence.year, occurrence.month, occurrence.day + step);
    case RecurrenceFrequency.weekly:
      return _at(spec, occurrence.year, occurrence.month, occurrence.day + 7 * step);
    case RecurrenceFrequency.monthly:
      return _inMonth(spec, occurrence.year, occurrence.month + step, monthStartDay);
    case RecurrenceFrequency.yearly:
      return _inMonth(spec, occurrence.year + step, spec.start.month, monthStartDay);
  }
}

/// Whether [occurrence] may still happen given the end date, and the
/// [postedCount] occurrences already consumed against [RecurrenceSpec.maxCount].
bool allowsOccurrence(RecurrenceSpec spec, DateTime occurrence, {required int postedCount}) {
  if (spec.maxCount != null && postedCount >= spec.maxCount!) return false;
  final end = spec.endDate;
  if (end != null && startOfDay(occurrence).isAfter(startOfDay(end))) return false;
  return true;
}

/// Occurrences from [nextDue] up to and including [now], respecting the end
/// conditions, oldest first. This is the catch-up list when the app was not
/// opened for a while.
List<DateTime> dueOccurrences(RecurrenceSpec spec, {required DateTime nextDue, required DateTime now, int postedCount = 0, int monthStartDay = 1, int cap = kMaxCatchUp}) {
  final due = <DateTime>[];
  var occurrence = nextDue;
  while (!occurrence.isAfter(now) && due.length < cap && allowsOccurrence(spec, occurrence, postedCount: postedCount + due.length)) {
    due.add(occurrence);
    occurrence = nextAfter(spec, occurrence, monthStartDay: monthStartDay);
  }
  return due;
}

/// Occurrences from [nextDue] that fall before [until] (exclusive), oldest
/// first, for upcoming lists and calendars.
List<DateTime> occurrencesBefore(RecurrenceSpec spec, {required DateTime nextDue, required DateTime until, int postedCount = 0, int monthStartDay = 1, int cap = kMaxCatchUp}) {
  final result = <DateTime>[];
  var occurrence = nextDue;
  while (occurrence.isBefore(until) && result.length < cap && allowsOccurrence(spec, occurrence, postedCount: postedCount + result.length)) {
    result.add(occurrence);
    occurrence = nextAfter(spec, occurrence, monthStartDay: monthStartDay);
  }
  return result;
}

/// Where a rule stands after [consumed] more occurrences were posted or
/// skipped starting at [nextDue]: the new next due date (null once the rule
/// has ended) and the new lifetime count.
({DateTime? nextDue, int postedCount}) advance(RecurrenceSpec spec, {required DateTime nextDue, required int postedCount, required int consumed, int monthStartDay = 1}) {
  var occurrence = nextDue;
  for (var step = 0; step < consumed; step++) {
    occurrence = nextAfter(spec, occurrence, monthStartDay: monthStartDay);
  }
  final count = postedCount + consumed;
  return (nextDue: allowsOccurrence(spec, occurrence, postedCount: count) ? occurrence : null, postedCount: count);
}

/// The first due date for a new rule, or null if its end conditions leave
/// no occurrence at all.
DateTime? initialNextDue(RecurrenceSpec spec, {int postedCount = 0, int monthStartDay = 1}) {
  final first = firstOccurrence(spec, monthStartDay: monthStartDay);
  return allowsOccurrence(spec, first, postedCount: postedCount) ? first : null;
}

/// How many occurrences of [spec] fall inside [range], e.g. the salary
/// month built with `monthRange(anchor, startDay: monthStartDay)`.
List<DateTime> occurrencesInRange(RecurrenceSpec spec, DateRange range, {int monthStartDay = 1}) {
  final first = firstOnOrAfter(spec, range.start.isAfter(spec.start) ? range.start : spec.start, monthStartDay: monthStartDay);
  // Earlier occurrences consumed against maxCount are not known here, so
  // only the end date limits this window view.
  final open = RecurrenceSpec(frequency: spec.frequency, start: spec.start, interval: spec.interval, dayOfMonth: spec.dayOfMonth, weekday: spec.weekday, endDate: spec.endDate);
  return occurrencesBefore(open, nextDue: _alignToSchedule(spec, first, monthStartDay), until: range.end, monthStartDay: monthStartDay);
}

/// For intervals above one, the first on-schedule occurrence at or after
/// [candidate], counted from the rule's first occurrence.
DateTime _alignToSchedule(RecurrenceSpec spec, DateTime candidate, int monthStartDay) {
  if (spec._step == 1) return candidate;
  var occurrence = firstOccurrence(spec, monthStartDay: monthStartDay);
  var guard = 0;
  while (startOfDay(occurrence).isBefore(startOfDay(candidate)) && guard++ < 100000) {
    occurrence = nextAfter(spec, occurrence, monthStartDay: monthStartDay);
  }
  return occurrence;
}

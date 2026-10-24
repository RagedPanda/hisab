/// Credit card billing-cycle arithmetic. Pure: no clock, no I/O; callers pass
/// `today` in. All dates are calendar dates (midnight local time).
///
/// Conventions:
/// * A statement is generated on [statementDay] of each month. A day past the
///   end of a short month clamps to its last day (31 -> 30 Apr, 28/29 Feb).
/// * The statement date closes the cycle: spend on that day is on that bill.
///   The next cycle starts the following day.
/// * The bill is due on the first [dueDay] after the statement date. A due day
///   on or before the statement day means the following month.
library;

import '../../core/dates.dart';

/// Number of days in [month] of [year] (handles leap years).
int daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

/// [day] of the given month, clamped to the month's last day. [month] may
/// overflow (13 = January next year) as with [DateTime].
DateTime clampedMonthDay(int year, int month, int day) {
  final normalized = DateTime(year, month);
  final lastDay = daysInMonth(normalized.year, normalized.month);
  return DateTime(normalized.year, normalized.month, day.clamp(1, lastDay));
}

/// Whole calendar days from [from] to [to]; negative when [to] is earlier.
/// Counted on UTC dates so a DST shift can never make it off by one.
int calendarDaysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// The most recent statement date on or before [today].
DateTime previousStatementDate(DateTime today, int statementDay) {
  final thisMonth = clampedMonthDay(today.year, today.month, statementDay);
  return calendarDaysBetween(thisMonth, today) >= 0 ? thisMonth : clampedMonthDay(today.year, today.month - 1, statementDay);
}

/// The statement date that will close the cycle containing [today]: today
/// itself on statement day, else the next one.
DateTime nextStatementDate(DateTime today, int statementDay) {
  final thisMonth = clampedMonthDay(today.year, today.month, statementDay);
  return calendarDaysBetween(today, thisMonth) >= 0 ? thisMonth : clampedMonthDay(today.year, today.month + 1, statementDay);
}

/// The billing cycle containing [today], closed-open: from the day after the
/// previous statement up to and including the closing statement date.
DateRange currentCycle(DateTime today, int statementDay) {
  final closing = nextStatementDate(today, statementDay);
  final previousClosing = clampedMonthDay(closing.year, closing.month - 1, statementDay);
  return DateRange(_nextDay(previousClosing), _nextDay(closing));
}

/// When the bill generated on [statementDate] is due.
DateTime dueDateForStatement(DateTime statementDate, int dueDay) {
  final sameMonth = clampedMonthDay(statementDate.year, statementDate.month, dueDay);
  return calendarDaysBetween(statementDate, sameMonth) > 0 ? sameMonth : clampedMonthDay(statementDate.year, statementDate.month + 1, dueDay);
}

/// The next due date on or after [today]: the bill already generated if it
/// is not yet due, otherwise the bill the current cycle will produce.
DateTime upcomingDueDate(DateTime today, {required int statementDay, required int dueDay}) {
  final billed = dueDateForStatement(previousStatementDate(today, statementDay), dueDay);
  if (calendarDaysBetween(today, billed) >= 0) return billed;
  return dueDateForStatement(nextStatementDate(today, statementDay), dueDay);
}

DateTime _nextDay(DateTime date) => DateTime(date.year, date.month, date.day + 1);

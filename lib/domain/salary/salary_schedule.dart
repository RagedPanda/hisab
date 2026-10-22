/// Pure salary-day rules: when the salary is expected in a month, how that
/// lines up with the "month starts on" setting, whether it has been seen and
/// when the gentle "Salary not seen yet" reminder is due. No I/O, no clock.
library;

import '../../core/dates.dart';

/// What to do when the salary day falls on a weekend or holiday.
enum SalaryShift {
  /// Expect it on the day itself regardless.
  sameDay,

  /// Employers that pay early: the previous working day.
  previousWorkingDay,

  /// Employers that pay late: the next working day.
  nextWorkingDay;

  static SalaryShift parse(String value) =>
      SalaryShift.values.firstWhere((shift) => shift.name == value, orElse: () => SalaryShift.previousWorkingDay);
}

/// Highest day the "month starts on" setting supports (see [monthRange]).
const int kMaxMonthStartDay = 28;

/// Days either side of the expected date an income still counts as salary.
const int kSalaryMatchWindowDays = 4;

/// Share of the expected amount an income may differ by and still count.
const double kSalaryAmountTolerance = 0.15;

/// Default days after the expected date before reminding.
const int kDefaultSalaryReminderDelayDays = 2;

/// Saturday and Sunday are not working days.
bool isWeekend(DateTime date) => date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

/// A working day is neither a weekend nor one of [holidays] (compared by day).
bool isWorkingDay(DateTime date, {Set<DateTime> holidays = const {}}) =>
    !isWeekend(date) && !holidays.any((holiday) => isSameDay(holiday, date));

/// The salary day as a date in [year]/[month], clamped to short months
/// (31 becomes 30 Apr, 28 or 29 Feb). [month] may overflow, as with [DateTime].
DateTime nominalSalaryDate(int year, int month, int salaryDay) {
  final normalised = DateTime(year, month);
  final length = DateTime(normalised.year, normalised.month + 1, 0).day;
  return DateTime(normalised.year, normalised.month, salaryDay.clamp(1, length));
}

/// Moves [date] off weekends and [holidays] in the direction [shift] asks.
DateTime shiftToWorkingDay(DateTime date, SalaryShift shift, {Set<DateTime> holidays = const {}}) {
  if (shift == SalaryShift.sameDay) return startOfDay(date);
  final step = shift == SalaryShift.previousWorkingDay ? -1 : 1;
  var candidate = startOfDay(date);
  // Two weeks bounds any realistic run of holidays and keeps this total.
  for (var tries = 0; tries < 14 && !isWorkingDay(candidate, holidays: holidays); tries++) {
    candidate = DateTime(candidate.year, candidate.month, candidate.day + step);
  }
  return candidate;
}

/// The day the salary is expected for the pay month [year]/[month].
DateTime expectedSalaryDate(int year, int month, {required int salaryDay, SalaryShift shift = SalaryShift.sameDay, Set<DateTime> holidays = const {}}) =>
    shiftToWorkingDay(nominalSalaryDate(year, month, salaryDay), shift, holidays: holidays);

/// The most recent expected salary date on or before the day of [now]
/// (the current pay cycle), and the one after it.
({DateTime current, DateTime next}) salaryCycle(DateTime now, {required int salaryDay, SalaryShift shift = SalaryShift.sameDay, Set<DateTime> holidays = const {}}) {
  final today = startOfDay(now);
  DateTime expectedIn(int monthOffset) =>
      expectedSalaryDate(today.year, today.month + monthOffset, salaryDay: salaryDay, shift: shift, holidays: holidays);
  // A shift can pull next month's date into this month or push this month's
  // into the next, so look two months back and two ahead.
  final candidates = [for (var offset = -2; offset <= 2; offset++) expectedIn(offset)];
  final currentIndex = candidates.lastIndexWhere((date) => !date.isAfter(today));
  return (current: candidates[currentIndex], next: candidates[currentIndex + 1]);
}

/// The "month starts on" value that matches a salary day. The setting only
/// goes up to [kMaxMonthStartDay], so a salary on the 29th to 31st suggests
/// the 28th, which still keeps the salary inside the month it pays for.
int suggestedMonthStartDay(int salaryDay) => salaryDay.clamp(1, kMaxMonthStartDay);

/// Whether the "month starts on" setting already matches the salary day.
bool isMonthStartAligned({required int monthStartDay, required int salaryDay}) =>
    monthStartDay.clamp(1, kMaxMonthStartDay) == suggestedMonthStartDay(salaryDay);

/// The budget month (per the "month starts on" setting) a salary received on
/// [expected] is counted in. When month start and salary day are not
/// aligned, a salary paid on the 30th lands in the month that is nearly over.
DateRange budgetMonthOfSalary(DateTime expected, {required int monthStartDay}) =>
    monthRange(expected, startDay: monthStartDay);

/// An income entry as far as salary detection cares.
class IncomeCandidate {
  const IncomeCandidate({required this.occurredAt, required this.amountMinor, this.accountId, this.id = '', this.recurringId});

  /// Entry id, so the edge can link the recognised salary to its rule.
  final String id;

  /// Rule that posted or claimed the entry, if any.
  final String? recurringId;
  final DateTime occurredAt;
  final int amountMinor;
  final String? accountId;
}

/// Whether [amountMinor] is within [tolerance] (a share, 0.15 = 15%) of
/// [expectedMinor]. An expected amount of zero or less matches any income.
bool isAmountWithinTolerance(int amountMinor, int expectedMinor, {double tolerance = kSalaryAmountTolerance}) {
  if (expectedMinor <= 0) return amountMinor > 0;
  return (amountMinor - expectedMinor).abs() <= expectedMinor * tolerance;
}

/// The window an income must fall in to count as the salary expected on
/// [expected]: [windowDays] before it through [windowDays] after, extended
/// to the day of [now] so a late salary still dismisses the reminder, but
/// never reaching into the next cycle's window ([nextExpected]).
DateRange salaryMatchWindow(DateTime expected, {required DateTime now, DateTime? nextExpected, int windowDays = kSalaryMatchWindowDays}) {
  final start = DateTime(expected.year, expected.month, expected.day - windowDays);
  final afterWindow = DateTime(expected.year, expected.month, expected.day + windowDays + 1);
  final afterToday = DateTime(now.year, now.month, now.day + 1);
  var end = afterToday.isAfter(afterWindow) ? afterToday : afterWindow;
  if (nextExpected != null) {
    final nextWindowStart = DateTime(nextExpected.year, nextExpected.month, nextExpected.day - windowDays);
    if (nextWindowStart.isBefore(end)) end = nextWindowStart;
  }
  return DateRange(start, end);
}

/// The first income in [incomes] that looks like the salary expected on
/// [expected]: inside [salaryMatchWindow], amount within [tolerance] and, when
/// [accountId] is given, credited to that account or to no account (SMS
/// entries whose account was not recognised). Null when not seen yet.
IncomeCandidate? findSalaryIncome(
  Iterable<IncomeCandidate> incomes, {
  required DateTime expected,
  required int expectedMinor,
  required DateTime now,
  DateTime? nextExpected,
  String? accountId,
  int windowDays = kSalaryMatchWindowDays,
  double tolerance = kSalaryAmountTolerance,
}) {
  final window = salaryMatchWindow(expected, now: now, nextExpected: nextExpected, windowDays: windowDays);
  final matches = incomes.where((income) =>
      window.contains(income.occurredAt) &&
      isAmountWithinTolerance(income.amountMinor, expectedMinor, tolerance: tolerance) &&
      (accountId == null || income.accountId == null || income.accountId == accountId));
  if (matches.isEmpty) return null;
  // Prefer the income closest to the expected day.
  int distance(IncomeCandidate income) => income.occurredAt.difference(expected).inMinutes.abs();
  return matches.reduce((best, income) => distance(income) < distance(best) ? income : best);
}

/// Where the salary reminder stands for one pay cycle.
enum SalaryReminderState {
  /// Not yet past the expected date plus the delay.
  waiting,

  /// Past it and no matching income: show "Salary not seen yet".
  due,

  /// A matching income arrived: nothing to show (dismiss any notification).
  seen,
}

/// The moment to show the reminder for a salary expected on [expected].
DateTime salaryReminderAt(DateTime expected, {required int delayDays, int hour = 10}) =>
    DateTime(expected.year, expected.month, expected.day + delayDays, hour);

SalaryReminderState salaryReminderState({required DateTime expected, required DateTime now, required bool seen, required int delayDays}) {
  if (seen) return SalaryReminderState.seen;
  return now.isBefore(salaryReminderAt(expected, delayDays: delayDays)) ? SalaryReminderState.waiting : SalaryReminderState.due;
}

/// Whole days from the day of [now] to [nextExpected], for "salary in N days".
int daysUntilSalary(DateTime nextExpected, {required DateTime now}) =>
    startOfDay(nextExpected).difference(startOfDay(now)).inDays;

/// Everything the dashboard and reminder need about the current pay cycle.
class SalaryStatus {
  const SalaryStatus({required this.expected, required this.next, required this.received, required this.reminderState, required this.reminderAt});

  /// Expected date of the current cycle (on or before today).
  final DateTime expected;

  /// Expected date of the next cycle.
  final DateTime next;

  /// The income recognised as this cycle's salary, if any.
  final IncomeCandidate? received;
  final SalaryReminderState reminderState;

  /// When the reminder for [expected] is (or was) due.
  final DateTime reminderAt;

  bool get isSeen => received != null;
}

/// Evaluates the current pay cycle for a salary of [expectedMinor] on
/// [salaryDay] against [incomes] (recent income entries).
SalaryStatus evaluateSalary({
  required DateTime now,
  required int salaryDay,
  required int expectedMinor,
  required Iterable<IncomeCandidate> incomes,
  SalaryShift shift = SalaryShift.sameDay,
  Set<DateTime> holidays = const {},
  String? accountId,
  int reminderDelayDays = kDefaultSalaryReminderDelayDays,
}) {
  final cycle = salaryCycle(now, salaryDay: salaryDay, shift: shift, holidays: holidays);
  final received = findSalaryIncome(incomes, expected: cycle.current, expectedMinor: expectedMinor, now: now, nextExpected: cycle.next, accountId: accountId);
  return SalaryStatus(
    expected: cycle.current,
    next: cycle.next,
    received: received,
    reminderState: salaryReminderState(expected: cycle.current, now: now, seen: received != null, delayDays: reminderDelayDays),
    reminderAt: salaryReminderAt(cycle.current, delayDays: reminderDelayDays),
  );
}

/// Earliest income date [evaluateSalary] can look at for [now], so callers
/// load only the entries that matter.
DateTime salaryLookbackStart(DateTime now, {int windowDays = kSalaryMatchWindowDays}) =>
    DateTime(now.year, now.month - 2, now.day - windowDays);

/// Whether the salary rule's waiting occurrence ([ruleNextDue]) should be
/// consumed by the income [status] recognised, so the rule does not ask the
/// user to confirm a salary that already arrived (by SMS or by hand). Only
/// an occurrence that belongs to the current cycle is claimed, and only by
/// an income not already tied to the rule.
bool shouldClaimSalaryOccurrence(SalaryStatus status, {required DateTime? ruleNextDue, required String ruleId, int windowDays = kSalaryMatchWindowDays}) {
  final received = status.received;
  if (received == null || ruleNextDue == null || received.recurringId == ruleId) return false;
  final nextCycleWindowStart = DateTime(status.next.year, status.next.month, status.next.day - windowDays);
  return startOfDay(ruleNextDue).isBefore(nextCycleWindowStart);
}

/// What the notification layer should do about the salary reminder.
sealed class SalaryNotificationPlan {
  const SalaryNotificationPlan();
}

/// Remove any shown or scheduled "Salary not seen yet" notification.
class CancelSalaryNotification extends SalaryNotificationPlan {
  const CancelSalaryNotification();
}

/// Have "Salary not seen yet" for [expected] appear at [at] (now or later).
class ScheduleSalaryNotification extends SalaryNotificationPlan {
  const ScheduleSalaryNotification({required this.at, required this.expected});
  final DateTime at;
  final DateTime expected;

  @override
  bool operator ==(Object other) => other is ScheduleSalaryNotification && other.at == at && other.expected == expected;

  @override
  int get hashCode => Object.hash(at, expected);
}

/// Decides the reminder for [status]: nothing when the salary is not set up,
/// the reminder is off or the salary was seen; otherwise the current cycle's
/// reminder (shown at once when it is already due). A cycle whose reminder
/// moment passed more than [staleAfterDays] ago is not nagged about again.
SalaryNotificationPlan planSalaryNotification(SalaryStatus? status, {required bool reminderEnabled, required DateTime now, int staleAfterDays = 10}) {
  if (status == null || !reminderEnabled || status.isSeen) return const CancelSalaryNotification();
  final stale = now.isAfter(status.reminderAt.add(Duration(days: staleAfterDays)));
  if (stale) return const CancelSalaryNotification();
  return ScheduleSalaryNotification(at: status.reminderAt.isAfter(now) ? status.reminderAt : now, expected: status.expected);
}

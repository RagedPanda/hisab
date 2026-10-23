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

/// Default days either side of the expected date an income still counts as salary.
const int kSalaryMatchWindowDays = 4;

/// User bounds for the match window. A week either side is the most a monthly
/// cycle can take before it reaches into the neighbouring payday.
const int kMinSalaryMatchWindowDays = 1;
const int kMaxSalaryMatchWindowDays = 7;

/// Default share, in percent, the amount may differ by and still count.
const int kDefaultSalaryTolerancePercent = 15;

/// Amount tolerance choices offered to the user, in percent. Bounded at 50%
/// so a small unrelated income never passes for the salary.
const List<int> kSalaryTolerancePercentChoices = [0, 5, 10, 15, 20, 25, 30, 40, 50];

/// Default share of the expected amount an income may differ by and still count.
const double kSalaryAmountTolerance = kDefaultSalaryTolerancePercent / 100;

/// [days] within the match-window bounds.
int clampSalaryMatchWindowDays(int days) => days.clamp(kMinSalaryMatchWindowDays, kMaxSalaryMatchWindowDays);

/// [percent] within the tolerance bounds (0 .. the highest choice).
int clampSalaryTolerancePercent(int percent) => percent.clamp(0, kSalaryTolerancePercentChoices.last);

/// The offered choice closest to [percent], for showing a restored or
/// hand-edited value that is not one of [kSalaryTolerancePercentChoices].
int nearestSalaryToleranceChoice(int percent) {
  final bounded = clampSalaryTolerancePercent(percent);
  return kSalaryTolerancePercentChoices.reduce((best, choice) => (choice - bounded).abs() < (best - bounded).abs() ? choice : best);
}

/// A tolerance in percent as the fraction [isAmountWithinTolerance] takes.
double salaryToleranceFraction(int percent) => clampSalaryTolerancePercent(percent) / 100;

/// Default days after the expected date before reminding.
const int kDefaultSalaryReminderDelayDays = 2;

/// Stored name of the salary recurring rule. Kept untranslated so it reads
/// right after a language change; lists show it via `localizedRuleName`.
const String kSalaryRuleName = 'Salary';

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

/// The expected salary dates around [now]: the cycle before the current one,
/// the current one (the most recent on or before the day of [now]), the
/// next one and the one after it.
({DateTime previous, DateTime current, DateTime next, DateTime afterNext}) salaryCycles(DateTime now, {required int salaryDay, SalaryShift shift = SalaryShift.sameDay, Set<DateTime> holidays = const {}}) {
  final today = startOfDay(now);
  DateTime expectedIn(int monthOffset) =>
      expectedSalaryDate(today.year, today.month + monthOffset, salaryDay: salaryDay, shift: shift, holidays: holidays);
  // A shift can pull next month's date into this month or push this month's
  // into the next, so look three months back and three ahead.
  final candidates = [for (var offset = -3; offset <= 3; offset++) expectedIn(offset)];
  final currentIndex = candidates.lastIndexWhere((date) => !date.isAfter(today));
  return (
    previous: candidates[currentIndex - 1],
    current: candidates[currentIndex],
    next: candidates[currentIndex + 1],
    afterNext: candidates[currentIndex + 2],
  );
}

/// The most recent expected salary date on or before the day of [now]
/// (the current pay cycle), and the one after it.
({DateTime current, DateTime next}) salaryCycle(DateTime now, {required int salaryDay, SalaryShift shift = SalaryShift.sameDay, Set<DateTime> holidays = const {}}) {
  final cycles = salaryCycles(now, salaryDay: salaryDay, shift: shift, holidays: holidays);
  return (current: cycles.current, next: cycles.next);
}

/// The unshifted salary date of the pay cycle that [due] belongs to: the
/// one nearest to [due]. A shift moves a date by at most two weeks, so a
/// shifted or unshifted due date both map to their own cycle.
DateTime nominalSalaryCycleOf(DateTime due, {required int salaryDay}) {
  final day = startOfDay(due);
  DateTime nominalIn(int monthOffset) => nominalSalaryDate(day.year, day.month + monthOffset, salaryDay);
  int distance(int monthOffset) => nominalIn(monthOffset).difference(day).inDays.abs();
  return nominalIn([-1, 0, 1].reduce((best, offset) => distance(offset) < distance(best) ? offset : best));
}

/// Ties the salary rule's lifetime count to a pay cycle, so its due date
/// can be placed on the right cycle after the recurring engine (which steps
/// on unshifted dates) confirms or skips an occurrence. Written when the
/// salary rule is saved.
class SalaryRuleAnchor {
  const SalaryRuleAnchor({required this.nominal, required this.postedCount});

  /// Unshifted salary date of the cycle that was due at [postedCount].
  final DateTime nominal;
  final int postedCount;

  Map<String, dynamic> toJson() => {'nominal': nominal.toIso8601String(), 'postedCount': postedCount};

  /// Null for anything that is not a valid anchor.
  static SalaryRuleAnchor? fromJson(Object? json) {
    if (json is! Map) return null;
    final nominal = DateTime.tryParse('${json['nominal']}');
    final postedCount = json['postedCount'];
    if (nominal == null || postedCount is! int) return null;
    return SalaryRuleAnchor(nominal: startOfDay(nominal), postedCount: postedCount);
  }

  @override
  bool operator ==(Object other) => other is SalaryRuleAnchor && other.nominal == nominal && other.postedCount == postedCount;

  @override
  int get hashCode => Object.hash(nominal, postedCount);
}

/// The anchor for a salary rule just saved with [nextDue] and [postedCount].
SalaryRuleAnchor salaryRuleAnchorFor(DateTime nextDue, {required int postedCount, required int salaryDay}) =>
    SalaryRuleAnchor(nominal: nominalSalaryCycleOf(nextDue, salaryDay: salaryDay), postedCount: postedCount);

/// The due date the salary rule should hold, with the weekend and holiday
/// shift applied. The cycle is [anchor]'s moved on by the occurrences the
/// rule consumed since ([postedCount]); without a usable anchor it is the
/// cycle nearest to [storedDue]. Keeps the time of day of [storedDue].
DateTime alignedSalaryRuleDue(
  DateTime storedDue, {
  required int postedCount,
  required int salaryDay,
  SalaryRuleAnchor? anchor,
  SalaryShift shift = SalaryShift.sameDay,
  Set<DateTime> holidays = const {},
}) {
  final nominal = anchor == null || postedCount < anchor.postedCount
      ? nominalSalaryCycleOf(storedDue, salaryDay: salaryDay)
      : nominalSalaryDate(anchor.nominal.year, anchor.nominal.month + postedCount - anchor.postedCount, salaryDay);
  final expected = shiftToWorkingDay(nominal, shift, holidays: holidays);
  return DateTime(expected.year, expected.month, expected.day, storedDue.hour, storedDue.minute);
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
  const SalaryStatus({required this.expected, required this.next, required this.received, required this.reminderState, required this.reminderAt, this.lastReceived});

  /// Expected date of the cycle being tracked: the current one (on or before
  /// today), or the next one once its salary arrived early.
  final DateTime expected;

  /// Expected date of the next cycle.
  final DateTime next;

  /// The income recognised as this cycle's salary, if any.
  final IncomeCandidate? received;
  final SalaryReminderState reminderState;

  /// When the reminder for [expected] is (or was) due.
  final DateTime reminderAt;

  /// The latest salary recognised: [received], else the previous cycle's.
  final IncomeCandidate? lastReceived;

  bool get isSeen => received != null;

  /// The salary has not arrived and its reminder moment has passed.
  bool get isLate => reminderState == SalaryReminderState.due;
}

/// Evaluates the current pay cycle for a salary of [expectedMinor] on
/// [salaryDay] against [incomes] (recent income entries). A cycle expected
/// before [trackedSince] (the day the salary rule started) is never tracked
/// or late: the first one tracked is the first on or after that day.
SalaryStatus evaluateSalary({
  required DateTime now,
  required int salaryDay,
  required int expectedMinor,
  required Iterable<IncomeCandidate> incomes,
  SalaryShift shift = SalaryShift.sameDay,
  Set<DateTime> holidays = const {},
  String? accountId,
  int reminderDelayDays = kDefaultSalaryReminderDelayDays,
  int windowDays = kSalaryMatchWindowDays,
  double tolerance = kSalaryAmountTolerance,
  DateTime? trackedSince,
}) {
  final cycles = salaryCycles(now, salaryDay: salaryDay, shift: shift, holidays: holidays);
  IncomeCandidate? findFor(DateTime expected, DateTime nextExpected) => findSalaryIncome(
        incomes,
        expected: expected,
        expectedMinor: expectedMinor,
        now: now,
        nextExpected: nextExpected,
        accountId: accountId,
        windowDays: windowDays,
        tolerance: tolerance,
      );
  SalaryStatus statusFor(DateTime expected, DateTime next, IncomeCandidate? received, IncomeCandidate? previous) => SalaryStatus(
        expected: expected,
        next: next,
        received: received,
        lastReceived: received ?? previous,
        reminderState: salaryReminderState(expected: expected, now: now, seen: received != null, delayDays: reminderDelayDays),
        reminderAt: salaryReminderAt(expected, delayDays: reminderDelayDays),
      );

  // A salary that came early, inside the next cycle's window, settles that
  // cycle straight away instead of waiting for its expected date.
  final early = findFor(cycles.next, cycles.afterNext);
  if (early != null) return statusFor(cycles.next, cycles.afterNext, early, null);
  if (isBeforeSalaryTracking(cycles.current, trackedSince: trackedSince)) {
    return statusFor(cycles.next, cycles.afterNext, null, findFor(cycles.current, cycles.next));
  }
  final current = findFor(cycles.current, cycles.next);
  return statusFor(cycles.current, cycles.next, current, current == null ? findFor(cycles.previous, cycles.current) : null);
}

/// Whether the cycle [expected] on that date predates the salary rule
/// ([trackedSince]), so it is not tracked. Without a start date (setups made
/// before it was stored) every cycle counts.
bool isBeforeSalaryTracking(DateTime expected, {required DateTime? trackedSince}) =>
    trackedSince != null && startOfDay(expected).isBefore(startOfDay(trackedSince));

/// Whether saving the salary setup must rebuild its rule from today: only a
/// new rule or a changed salary day. Any other edit keeps the rule's due
/// date and its waiting occurrence.
bool shouldRestartSalaryRule({required int? ruleDay, required int salaryDay}) => ruleDay != salaryDay;

/// Earliest income date [evaluateSalary] can look at for [now], so callers
/// load only the entries that matter. Defaults to the widest window the user
/// can pick, so the loaded range never depends on the setting.
DateTime salaryLookbackStart(DateTime now, {int windowDays = kMaxSalaryMatchWindowDays}) =>
    DateTime(now.year, now.month - 2, now.day - windowDays);

/// Whether the salary rule's waiting occurrence ([ruleNextDue]) should be
/// consumed by the income [status] recognised, so the rule does not ask the
/// user to confirm a salary that already arrived (by SMS or by hand). Only
/// an occurrence of the cycle the income settled is claimed (an older one
/// the salary missed stays waiting), and only by an income not already tied
/// to the rule.
bool shouldClaimSalaryOccurrence(SalaryStatus status, {required DateTime? ruleNextDue, required String ruleId, int windowDays = kSalaryMatchWindowDays}) {
  final received = status.received;
  if (received == null || ruleNextDue == null || received.recurringId == ruleId) return false;
  final cycleWindowStart = DateTime(status.expected.year, status.expected.month, status.expected.day - windowDays);
  final nextCycleWindowStart = DateTime(status.next.year, status.next.month, status.next.day - windowDays);
  final due = startOfDay(ruleNextDue);
  return !due.isBefore(cycleWindowStart) && due.isBefore(nextCycleWindowStart);
}

/// What the notification layer should do about the salary reminder.
sealed class SalaryNotificationPlan {
  const SalaryNotificationPlan();
}

/// Remove any shown or scheduled "Salary not seen yet" notification.
class CancelSalaryNotification extends SalaryNotificationPlan {
  const CancelSalaryNotification();
}

/// Have "Salary not seen yet" for [expected] appear at [at] (always in the
/// future, as the OS scheduler requires). [overdue] means its moment already
/// passed, so it shows within seconds.
class ScheduleSalaryNotification extends SalaryNotificationPlan {
  const ScheduleSalaryNotification({required this.at, required this.expected, this.overdue = false});
  final DateTime at;
  final DateTime expected;
  final bool overdue;

  @override
  bool operator ==(Object other) => other is ScheduleSalaryNotification && other.at == at && other.expected == expected && other.overdue == overdue;

  @override
  int get hashCode => Object.hash(at, expected, overdue);
}

/// How far ahead an overdue alert is scheduled: the OS rejects a time that
/// is not in the future, and a few seconds still reads as "now".
const Duration kSalaryAlertLead = Duration(seconds: 5);

/// When to fire an alert meant for [reminderAt]: then, or a moment from
/// [now] when that has already passed.
DateTime salaryAlertFireAt(DateTime reminderAt, {required DateTime now}) {
  final earliest = now.add(kSalaryAlertLead);
  return reminderAt.isAfter(earliest) ? reminderAt : earliest;
}

/// Decides the reminder for [status]: nothing when the salary is not set up,
/// the reminder is off or the salary was seen; otherwise the current cycle's
/// reminder (shown within seconds when it is already due). A cycle whose
/// reminder moment passed more than [staleAfterDays] ago is not nagged
/// about again.
SalaryNotificationPlan planSalaryNotification(SalaryStatus? status, {required bool reminderEnabled, required DateTime now, int staleAfterDays = 10}) {
  if (status == null || !reminderEnabled || status.isSeen) return const CancelSalaryNotification();
  final stale = now.isAfter(status.reminderAt.add(Duration(days: staleAfterDays)));
  if (stale) return const CancelSalaryNotification();
  return ScheduleSalaryNotification(
    at: salaryAlertFireAt(status.reminderAt, now: now),
    expected: status.expected,
    overdue: !status.reminderAt.isAfter(now),
  );
}

/// Identifies one posted alert: its cycle and the language of its text.
String salaryAlertMarker(ScheduleSalaryNotification plan, {required String locale}) => '${startOfDay(plan.expected).toIso8601String()}|$locale';

/// Whether [plan] needs to reach the notification layer. An overdue alert
/// already posted for the same cycle and language ([postedMarker]) is left
/// alone, so it is not shown again on every app resume; a new language
/// re-posts it with fresh text. Cancels and future alerts always apply.
bool shouldApplySalaryPlan(SalaryNotificationPlan plan, {required String? postedMarker, required String locale}) => switch (plan) {
      CancelSalaryNotification() => true,
      ScheduleSalaryNotification(overdue: false) => true,
      ScheduleSalaryNotification() => postedMarker != salaryAlertMarker(plan, locale: locale),
    };

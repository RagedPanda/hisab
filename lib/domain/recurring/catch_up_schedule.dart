import 'repeat_draft.dart' show RecurringStatus;

/// What the foreground timer needs to know about a rule.
typedef WakeRule = ({String status, DateTime? nextDue});

/// The start of the local day after [now]. Built from calendar fields, so a
/// daylight-saving shift still lands on midnight rather than 23:00 or 01:00.
DateTime nextLocalMidnight(DateTime now) => DateTime(now.year, now.month, now.day + 1);

/// When an open app should next run the catch-up: the earliest occurrence
/// still ahead of [now] on an active rule, or the next local midnight if that
/// comes first. Occurrences already due (a confirm-first rule waiting for the
/// user) are ignored, so the timer never spins on them.
DateTime nextWakeAt(Iterable<WakeRule> rules, DateTime now) {
  final upcoming = rules.where((rule) => rule.status == RecurringStatus.active && rule.nextDue != null && rule.nextDue!.isAfter(now)).map((rule) => rule.nextDue!);
  return upcoming.fold(nextLocalMidnight(now), (earliest, due) => due.isBefore(earliest) ? due : earliest);
}

/// How long to wait from [now] until [wake] has passed. The small [slack]
/// makes sure a timer that fires a little early still sees the wake time as
/// reached; a wake already behind [now] waits only the slack.
Duration delayUntil(DateTime wake, DateTime now, {Duration slack = const Duration(seconds: 1)}) {
  final remaining = wake.difference(now);
  return (remaining.isNegative ? Duration.zero : remaining) + slack;
}

/// How long to wait from [now] until the next local day has begun.
Duration delayUntilNextDay(DateTime now, {Duration slack = const Duration(seconds: 1)}) => delayUntil(nextLocalMidnight(now), now, slack: slack);

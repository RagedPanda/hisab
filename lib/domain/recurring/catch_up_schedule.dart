/// The start of the local day after [now]. Built from calendar fields, so a
/// daylight-saving shift still lands on midnight rather than 23:00 or 01:00.
DateTime nextLocalMidnight(DateTime now) => DateTime(now.year, now.month, now.day + 1);

/// How long to wait from [now] until the next local day has begun. The small
/// [slack] makes sure a timer that fires a little early still sees the new date.
Duration delayUntilNextDay(DateTime now, {Duration slack = const Duration(seconds: 1)}) => nextLocalMidnight(now).difference(now) + slack;

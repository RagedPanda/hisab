/// Where the inbox catch-up scan starts and how far it got. Pure, so the
/// rules can be tested without a device.
library;

/// Inbox messages newer than this are scanned on start/resume.
///
/// Starts at the stored [cursor] (last inbox message already processed),
/// falls back to the newest logged SMS for installs that predate the cursor,
/// and never reaches further back than [lookback]. A small [overlap] covers
/// clock skew between the receiver and the SMS provider; dedupe in the
/// ingest pipeline makes re-reading those messages harmless.
DateTime catchUpSince({
  required DateTime now,
  DateTime? cursor,
  DateTime? lastLogged,
  Duration lookback = const Duration(days: 90),
  Duration overlap = const Duration(minutes: 1),
}) {
  final floor = now.subtract(lookback);
  final start = cursor ?? lastLogged ?? floor;
  final bounded = start.isBefore(floor) ? floor : start;
  return bounded.subtract(overlap);
}

/// The cursor after a scan that saw messages received at [seen]: the newest
/// of those and the previous [cursor]. Never moves backwards.
DateTime? advanceCursor(DateTime? cursor, Iterable<DateTime> seen) =>
    seen.fold<DateTime?>(cursor, (latest, time) => latest == null || time.isAfter(latest) ? time : latest);

import 'reminder_schedule.dart';

/// Sections of the Reminders screen's Upcoming list.
enum ReminderBucket { overdue, thisWeek, later }

/// Which section a pending reminder due at [dueAt] belongs in at [now].
ReminderBucket bucketFor(DateTime dueAt, DateTime now) {
  final days = daysUntilDue(dueAt, now);
  if (days < 0) return ReminderBucket.overdue;
  if (days <= 7) return ReminderBucket.thisWeek;
  return ReminderBucket.later;
}

/// [items] grouped by bucket in display order, keeping each bucket's order;
/// empty buckets are left out.
Map<ReminderBucket, List<T>> groupByBucket<T>(Iterable<T> items, DateTime Function(T) dueOf, DateTime now) {
  final grouped = {for (final bucket in ReminderBucket.values) bucket: <T>[]};
  for (final item in items) {
    grouped[bucketFor(dueOf(item), now)]!.add(item);
  }
  return {
    for (final entry in grouped.entries)
      if (entry.value.isNotEmpty) entry.key: entry.value,
  };
}

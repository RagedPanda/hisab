/// The Repeat choice a person makes in the editor, before it becomes a
/// stored rule. Pure: converting to and from a [RecurrenceSpec] needs no I/O.
library;

import 'recurrence.dart';

/// How a repeating rule stops.
enum RepeatEnd { never, onDate, afterCount }

class RepeatDraft {
  const RepeatDraft({
    this.frequency = RecurrenceFrequency.monthly,
    this.interval = 1,
    this.lastDayOfMonth = false,
    this.end = RepeatEnd.never,
    this.endDate,
    this.maxCount,
    this.autoPost = true,
  });

  final RecurrenceFrequency frequency;
  final int interval;

  /// Monthly rules only: fall on the month's last day instead of the start
  /// date's day.
  final bool lastDayOfMonth;
  final RepeatEnd end;
  final DateTime? endDate;
  final int? maxCount;

  /// Post occurrences on their own (true) or wait for a confirm (false).
  final bool autoPost;

  /// The draft a stored schedule was made from.
  factory RepeatDraft.fromSpec(RecurrenceSpec spec, {bool autoPost = true}) => RepeatDraft(
        frequency: spec.frequency,
        interval: spec.interval < 1 ? 1 : spec.interval,
        lastDayOfMonth: spec.frequency == RecurrenceFrequency.monthly && spec.dayOfMonth == kLastDayOfMonth,
        end: spec.maxCount != null ? RepeatEnd.afterCount : (spec.endDate != null ? RepeatEnd.onDate : RepeatEnd.never),
        endDate: spec.endDate,
        maxCount: spec.maxCount,
        autoPost: autoPost,
      );

  /// The schedule this draft describes, starting on [start] (whose day and
  /// weekday anchor monthly and weekly rules).
  RecurrenceSpec specFrom(DateTime start) => RecurrenceSpec(
        frequency: frequency,
        start: start,
        interval: interval < 1 ? 1 : interval,
        dayOfMonth: switch (frequency) {
          RecurrenceFrequency.monthly => lastDayOfMonth ? kLastDayOfMonth : start.day,
          RecurrenceFrequency.yearly => start.day,
          _ => null,
        },
        weekday: frequency == RecurrenceFrequency.weekly ? start.weekday : null,
        endDate: end == RepeatEnd.onDate ? endDate : null,
        maxCount: end == RepeatEnd.afterCount ? maxCount : null,
      );

  /// Whether the draft can be saved: an end date must not precede [start]
  /// and a count must be at least one.
  bool isValidFrom(DateTime start) => switch (end) {
        RepeatEnd.never => interval >= 1,
        RepeatEnd.onDate => interval >= 1 && endDate != null && !DateTime(endDate!.year, endDate!.month, endDate!.day).isBefore(DateTime(start.year, start.month, start.day)),
        RepeatEnd.afterCount => interval >= 1 && (maxCount ?? 0) >= 1,
      };

  RepeatDraft copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    bool? lastDayOfMonth,
    RepeatEnd? end,
    DateTime? endDate,
    int? maxCount,
    bool? autoPost,
  }) =>
      RepeatDraft(
        frequency: frequency ?? this.frequency,
        interval: interval ?? this.interval,
        lastDayOfMonth: lastDayOfMonth ?? this.lastDayOfMonth,
        end: end ?? this.end,
        endDate: endDate ?? this.endDate,
        maxCount: maxCount ?? this.maxCount,
        autoPost: autoPost ?? this.autoPost,
      );

  @override
  bool operator ==(Object other) =>
      other is RepeatDraft &&
      other.frequency == frequency &&
      other.interval == interval &&
      other.lastDayOfMonth == lastDayOfMonth &&
      other.end == end &&
      other.endDate == endDate &&
      other.maxCount == maxCount &&
      other.autoPost == autoPost;

  @override
  int get hashCode => Object.hash(frequency, interval, lastDayOfMonth, end, endDate, maxCount, autoPost);
}

/// Rule lifecycle states stored in `recurring_rules.status`.
abstract final class RecurringStatus {
  static const active = 'active';
  static const paused = 'paused';
  static const ended = 'ended';
}

/// Where a rule is listed on the Recurring screen.
enum RecurringSection { waiting, active, paused, ended }

/// The section for a rule: confirm-first rules with an occurrence already
/// due wait for the person; the rest follow their stored status.
RecurringSection sectionOf({required String status, required bool autoPost, required DateTime? nextDue, required DateTime now}) {
  if (status == RecurringStatus.paused) return RecurringSection.paused;
  if (status == RecurringStatus.ended || nextDue == null) return RecurringSection.ended;
  if (!autoPost && !nextDue.isAfter(now)) return RecurringSection.waiting;
  return RecurringSection.active;
}

/// How many occurrences of a confirm-first rule are waiting at [now].
int waitingCount(RecurrenceSpec spec, {required DateTime nextDue, required DateTime now, required int postedCount, int monthStartDay = 1}) =>
    dueOccurrences(spec, nextDue: nextDue, now: now, postedCount: postedCount, monthStartDay: monthStartDay).length;

/// How a rule's used slots split into entries added and occurrences skipped.
/// [postedCount] counts both, so the added number is what is left after the
/// skips; it never goes below zero.
({int added, int skipped}) recurringTally({required int postedCount, required int skippedCount}) {
  final used = postedCount < 0 ? 0 : postedCount;
  final skipped = skippedCount.clamp(0, used);
  return (added: used - skipped, skipped: skipped);
}

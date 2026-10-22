/// Scheduled "remind me to settle up" for a group, optionally with one
/// member ("settle with Ravi on the 1st"). Pure: the schedule maths is the
/// shared recurrence engine, and the facts come from the group's transfers.
library;

import '../recurring/recurrence.dart';
import 'debt_simplifier.dart';

/// Hour of the day a settle-up reminder fires.
const int kSettleReminderHour = 9;

/// When to remind, and about whom (null = everyone in the group).
class SettleReminderSchedule {
  const SettleReminderSchedule({required this.frequency, this.dayOfMonth, this.weekday, this.memberId})
      : assert(frequency == RecurrenceFrequency.monthly || frequency == RecurrenceFrequency.weekly);

  /// monthly or weekly.
  final RecurrenceFrequency frequency;

  /// 1..31 or [kLastDayOfMonth] for monthly reminders.
  final int? dayOfMonth;

  /// ISO weekday 1..7 for weekly reminders.
  final int? weekday;
  final String? memberId;

  RecurrenceSpec specFrom(DateTime anchor) => RecurrenceSpec(
        frequency: frequency,
        start: DateTime(anchor.year, anchor.month, anchor.day, kSettleReminderHour),
        dayOfMonth: frequency == RecurrenceFrequency.monthly ? (dayOfMonth ?? 1) : null,
        weekday: frequency == RecurrenceFrequency.weekly ? (weekday ?? DateTime.monday) : null,
      );

  @override
  bool operator ==(Object other) =>
      other is SettleReminderSchedule && other.frequency == frequency && other.dayOfMonth == dayOfMonth && other.weekday == weekday && other.memberId == memberId;

  @override
  int get hashCode => Object.hash(frequency, dayOfMonth, weekday, memberId);
}

/// The first reminder strictly after [now].
DateTime nextSettleReminderAt(SettleReminderSchedule schedule, {required DateTime now}) {
  final spec = schedule.specFrom(now);
  final candidate = firstOnOrAfter(spec, now);
  return candidate.isAfter(now) ? candidate : nextAfter(spec, candidate);
}

/// What is outstanding between me and the people a reminder is about.
class SettleReminderFacts {
  const SettleReminderFacts({required this.owedToMe, required this.iOwe});

  /// Transfers paying me.
  final List<Transfer> owedToMe;

  /// Transfers I make.
  final List<Transfer> iOwe;

  int get owedToMeMinor => owedToMe.fold(0, (sum, transfer) => sum + transfer.amountMinor);
  int get iOweMinor => iOwe.fold(0, (sum, transfer) => sum + transfer.amountMinor);
  bool get isSettled => owedToMe.isEmpty && iOwe.isEmpty;
}

/// My side of the group's suggested [transfers], limited to [withMemberId]
/// when the reminder names one member.
SettleReminderFacts settleReminderFacts(List<Transfer> transfers, {required String? myMemberId, String? withMemberId}) {
  if (myMemberId == null) return const SettleReminderFacts(owedToMe: [], iOwe: []);
  bool concernsMember(String other) => withMemberId == null || other == withMemberId;
  return SettleReminderFacts(
    owedToMe: [for (final transfer in transfers) if (transfer.to == myMemberId && transfer.amountMinor > 0 && concernsMember(transfer.from)) transfer],
    iOwe: [for (final transfer in transfers) if (transfer.from == myMemberId && transfer.amountMinor > 0 && concernsMember(transfer.to)) transfer],
  );
}

/// Reminders-table kind of a group's scheduled settle-up reminder. It is not
/// a due-reminder kind, so the Reminders screens never list it.
const String kSettleScheduleKind = 'settle_schedule';

const String _settleScheduleIdPrefix = 'settle_schedule_';

/// One schedule per group, so its reminder id is derived from the group.
String settleScheduleReminderId(String groupId) => '$_settleScheduleIdPrefix$groupId';

/// The group of a scheduled settle-up reminder id, or null for any other id.
String? groupIdOfSettleSchedule(String reminderId) =>
    reminderId.startsWith(_settleScheduleIdPrefix) && reminderId.length > _settleScheduleIdPrefix.length
        ? reminderId.substring(_settleScheduleIdPrefix.length)
        : null;

/// The stored `repeat` value of [schedule]: 'weekly' or 'monthly'.
String settleScheduleRepeat(SettleReminderSchedule schedule) => schedule.frequency == RecurrenceFrequency.weekly ? 'weekly' : 'monthly';

/// The stored `repeatDay`: the weekday for weekly, the day of month (or
/// [kLastDayOfMonth]) for monthly.
int settleScheduleRepeatDay(SettleReminderSchedule schedule) =>
    schedule.frequency == RecurrenceFrequency.weekly ? (schedule.weekday ?? DateTime.monday) : (schedule.dayOfMonth ?? 1);

/// Reads a stored schedule back; null when [repeat] is not one this feature writes.
SettleReminderSchedule? settleScheduleFromStored({required String repeat, int? repeatDay, String? memberId}) => switch (repeat) {
      'weekly' => SettleReminderSchedule(frequency: RecurrenceFrequency.weekly, weekday: repeatDay ?? DateTime.monday, memberId: memberId),
      'monthly' => SettleReminderSchedule(frequency: RecurrenceFrequency.monthly, dayOfMonth: repeatDay ?? 1, memberId: memberId),
      _ => null,
    };

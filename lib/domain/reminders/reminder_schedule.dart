import '../../core/dates.dart';
import '../recurring/recurrence.dart';
import 'reminder_kind.dart';

/// Default notification time: 09:00.
const int kDefaultNotifyMinute = 9 * 60;

/// Days-before choices offered by the editor; 0 means on the due day.
const List<int> kRemindDaysBeforeChoices = [0, 1, 3, 7];

/// Lead times for document renewals (passport, PUC, insurance), in days.
const List<int> kDocumentRemindDaysBefore = [30, 7, 1, 0];

/// Parses the stored "3,0" form into distinct, non-negative days, largest first.
List<int> parseRemindDaysBefore(String stored) {
  final days = <int>{};
  for (final part in stored.split(',')) {
    final value = int.tryParse(part.trim());
    if (value != null && value >= 0) days.add(value);
  }
  return days.toList()..sort((a, b) => b.compareTo(a));
}

/// Stored form of [days]: distinct, largest first, comma separated.
String formatRemindDaysBefore(Iterable<int> days) => parseRemindDaysBefore(days.join(',')).join(',');

/// The [RecurrenceSpec] a repeating reminder due on [due] follows; null
/// for one-off reminders. Quarterly, half-yearly and eleven-monthly are
/// monthly with an interval; five and ten years are yearly with one.
RecurrenceSpec? reminderRecurrence(DateTime due, ReminderRepeat repeat, {int? anchorDay}) => switch (repeat) {
      ReminderRepeat.once => null,
      ReminderRepeat.weekly => RecurrenceSpec(frequency: RecurrenceFrequency.weekly, start: due),
      ReminderRepeat.monthly => RecurrenceSpec(frequency: RecurrenceFrequency.monthly, start: due, dayOfMonth: anchorDay),
      ReminderRepeat.quarterly => RecurrenceSpec(frequency: RecurrenceFrequency.monthly, start: due, interval: 3, dayOfMonth: anchorDay),
      ReminderRepeat.halfYearly => RecurrenceSpec(frequency: RecurrenceFrequency.monthly, start: due, interval: 6, dayOfMonth: anchorDay),
      ReminderRepeat.everyElevenMonths => RecurrenceSpec(frequency: RecurrenceFrequency.monthly, start: due, interval: 11, dayOfMonth: anchorDay),
      ReminderRepeat.yearly => RecurrenceSpec(frequency: RecurrenceFrequency.yearly, start: due, dayOfMonth: anchorDay),
      ReminderRepeat.everyFiveYears => RecurrenceSpec(frequency: RecurrenceFrequency.yearly, start: due, interval: 5, dayOfMonth: anchorDay),
      ReminderRepeat.everyTenYears => RecurrenceSpec(frequency: RecurrenceFrequency.yearly, start: due, interval: 10, dayOfMonth: anchorDay),
    };

/// The due date after [due] for [repeat]; null for one-off reminders.
/// Date maths lives in the shared recurrence engine, so 31 Jan -> 28 Feb
/// -> 31 Mar exactly as recurring entries do.
DateTime? nextDueDate(DateTime due, ReminderRepeat repeat, {int? anchorDay}) {
  final spec = reminderRecurrence(due, repeat, anchorDay: anchorDay);
  return spec == null ? null : nextAfter(spec, due);
}

/// One notification to post for a reminder.
class PlannedAlert {
  const PlannedAlert({required this.notificationId, required this.fireAt, required this.daysBefore});

  /// Stable per reminder and slot, so scheduling the same reminder again replaces it.
  final int notificationId;
  final DateTime fireAt;

  /// Days before the due day this alert fires; 0 on the day, -1 for a snooze.
  final int daysBefore;

  @override
  bool operator ==(Object other) =>
      other is PlannedAlert && other.notificationId == notificationId && other.fireAt == fireAt && other.daysBefore == daysBefore;

  @override
  int get hashCode => Object.hash(notificationId, fireAt, daysBefore);

  @override
  String toString() => 'PlannedAlert($notificationId, $fireAt, $daysBefore)';
}

/// Slot used for the snooze alert in [notificationIdFor].
const int kSnoozeSlot = -1;

/// Stable 31-bit notification id for a reminder alert slot (FNV-1a of "id:slot").
int notificationIdFor(String reminderId, int slot) {
  var hash = 0x811c9dc5;
  for (final unit in '$reminderId:$slot'.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}

/// The alerts still worth posting for a pending reminder at [now]: one per
/// days-before choice at [notifyAtMinute] local time, plus the snooze alert.
/// A snooze replaces every alert before it. Past times are dropped, except
/// that a reminder whose due day is today or overdue and has no future alert
/// gets nothing (the app shows it as overdue instead of nagging).
List<PlannedAlert> planAlerts({
  required String reminderId,
  required DateTime dueAt,
  required List<int> daysBefore,
  required int? notifyAtMinute,
  DateTime? snoozedUntil,
  required DateTime now,
}) {
  if (notifyAtMinute == null) return const [];
  final dueDay = startOfDay(dueAt);
  final alerts = <PlannedAlert>[
    for (final days in daysBefore)
      PlannedAlert(
        notificationId: notificationIdFor(reminderId, days),
        fireAt: DateTime(dueDay.year, dueDay.month, dueDay.day - days, notifyAtMinute ~/ 60, notifyAtMinute % 60),
        daysBefore: days,
      ),
  ];
  final snoozed = snoozedUntil != null && snoozedUntil.isAfter(now);
  return [
    for (final alert in alerts)
      if (alert.fireAt.isAfter(now) && (!snoozed || alert.fireAt.isAfter(snoozedUntil))) alert,
    if (snoozed) PlannedAlert(notificationId: notificationIdFor(reminderId, kSnoozeSlot), fireAt: snoozedUntil, daysBefore: kSnoozeSlot),
  ]..sort((a, b) => a.fireAt.compareTo(b.fireAt));
}

/// First slot of the later occurrences in [planOccurrenceAlerts]; the first
/// occurrence uses slot 0, like an on-the-day alert.
const int kOccurrenceSlotBase = 1000;

/// Most occurrences [planOccurrenceAlerts] posts ahead for one reminder.
const int kMaxOccurrencesAhead = 8;

/// Notification slot of the occurrence at [index] in [planOccurrenceAlerts].
int occurrenceSlot(int index) => index == 0 ? 0 : kOccurrenceSlotBase + index;

/// One alert per time in [fireTimes] (several occurrences of a repeating
/// reminder posted ahead), keeping only future ones. A snooze replaces every
/// alert before it, as in [planAlerts].
List<PlannedAlert> planOccurrenceAlerts({
  required String reminderId,
  required List<DateTime> fireTimes,
  DateTime? snoozedUntil,
  required DateTime now,
}) {
  final snoozed = snoozedUntil != null && snoozedUntil.isAfter(now);
  return [
    for (final (index, fireAt) in fireTimes.take(kMaxOccurrencesAhead).indexed)
      if (fireAt.isAfter(now) && (!snoozed || fireAt.isAfter(snoozedUntil)))
        PlannedAlert(notificationId: notificationIdFor(reminderId, occurrenceSlot(index)), fireAt: fireAt, daysBefore: 0),
    if (snoozed) PlannedAlert(notificationId: notificationIdFor(reminderId, kSnoozeSlot), fireAt: snoozedUntil, daysBefore: kSnoozeSlot),
  ]..sort((a, b) => a.fireAt.compareTo(b.fireAt));
}

/// Every notification id a reminder can ever use, so cancelling needs no lookup.
List<int> allNotificationIdsFor(String reminderId, Iterable<int> daysBefore) => {
      for (final days in {...daysBefore, ...kRemindDaysBeforeChoices, ...kDocumentRemindDaysBefore}) notificationIdFor(reminderId, days),
      for (var index = 1; index < kMaxOccurrencesAhead; index++) notificationIdFor(reminderId, occurrenceSlot(index)),
      notificationIdFor(reminderId, kSnoozeSlot),
    }.toList();

/// Whole calendar days from [now]'s date to [dueAt]'s date; negative when overdue.
/// Counted on UTC dates so a daylight-saving change never loses a day.
int daysUntilDue(DateTime dueAt, DateTime now) =>
    DateTime.utc(dueAt.year, dueAt.month, dueAt.day).difference(DateTime.utc(now.year, now.month, now.day)).inDays;

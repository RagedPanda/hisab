/// Pure aggregation behind the dashboard "Upcoming" card and the due
/// calendar. Recurring occurrences, reminders and credit card dues arrive as
/// small plain inputs; this file merges them into one sorted list, drops
/// duplicates and tags each item overdue, today or how many days away. No
/// I/O and no clock: callers pass `today`.
library;

import '../../core/dates.dart';
import '../reminders/reminder_schedule.dart' show daysUntilDue;

/// Where an upcoming item came from, so a tap can open the right screen.
enum UpcomingSource { recurring, reminder, cardDue }

/// The look-ahead the dashboard card offers.
enum UpcomingWindow {
  week(7),
  month(30);

  const UpcomingWindow(this.days);
  final int days;

  static UpcomingWindow parse(String? value) => UpcomingWindow.values.firstWhere((window) => window.name == value, orElse: () => UpcomingWindow.week);
}

/// Where an item sits relative to today.
enum UpcomingTiming { overdue, today, soon }

/// One future (or still pending past) occurrence of a recurring rule.
class RecurringOccurrenceInput {
  const RecurringOccurrenceInput({
    required this.ruleId,
    required this.title,
    required this.dueAt,
    this.amountMinor,
    this.currency = 'INR',
    this.isIncome = false,
    this.isSubscription = false,
    this.categoryId,
  });

  final String ruleId;
  final String title;
  final DateTime dueAt;
  final int? amountMinor;
  final String currency;
  final bool isIncome;
  final bool isSubscription;

  /// Category whose localised name stands in when [title] is empty.
  final String? categoryId;
}

/// A pending reminder (bill, EMI, document renewal...). Done reminders are
/// filtered out before they get here or flagged with [isDone].
class ReminderInput {
  const ReminderInput({
    required this.id,
    required this.title,
    required this.dueAt,
    this.amountMinor,
    this.currency = 'INR',
    this.recurringId,
    this.isDone = false,
    this.categoryId,
  });

  final String id;
  final String title;
  final DateTime dueAt;
  final int? amountMinor;
  final String currency;

  /// The recurring rule this reminder belongs to, if any; its occurrence on
  /// the same day is then shown once, as the reminder.
  final String? recurringId;
  final bool isDone;

  /// Category whose localised name stands in when [title] is empty.
  final String? categoryId;
}

/// A credit card bill due date.
class CardDueInput {
  const CardDueInput({required this.accountId, required this.title, required this.dueAt, this.amountMinor, this.currency = 'INR'});

  final String accountId;
  final String title;
  final DateTime dueAt;
  final int? amountMinor;
  final String currency;
}

/// One row of the merged list.
class UpcomingItem {
  const UpcomingItem({
    required this.source,
    required this.sourceId,
    required this.title,
    required this.dueAt,
    required this.daysAway,
    this.amountMinor,
    this.currency = 'INR',
    this.isIncome = false,
    this.recurringId,
    this.categoryId,
  });

  final UpcomingSource source;

  /// Rule id, reminder id or card account id, depending on [source].
  final String sourceId;
  final String title;
  final DateTime dueAt;
  final int? amountMinor;
  final String currency;
  final bool isIncome;
  final String? recurringId;

  /// Category whose localised name stands in when [title] is empty.
  final String? categoryId;

  /// Calendar days from today: negative when overdue, 0 today.
  final int daysAway;

  UpcomingTiming get timing => daysAway < 0
      ? UpcomingTiming.overdue
      : daysAway == 0
      ? UpcomingTiming.today
      : UpcomingTiming.soon;

  bool get isOverdue => daysAway < 0;

  @override
  String toString() => 'UpcomingItem(${source.name}:$sourceId $title $dueAt $daysAway)';
}

String _dayKey(DateTime value) => '${value.year}-${value.month}-${value.day}';

UpcomingItem _fromRecurring(RecurringOccurrenceInput input, DateTime today) => UpcomingItem(
  source: UpcomingSource.recurring,
  sourceId: input.ruleId,
  title: input.title,
  dueAt: input.dueAt,
  daysAway: daysUntilDue(input.dueAt, today),
  amountMinor: input.amountMinor,
  currency: input.currency,
  isIncome: input.isIncome,
  recurringId: input.ruleId,
  categoryId: input.categoryId,
);

UpcomingItem _fromReminder(ReminderInput input, DateTime today) => UpcomingItem(
  source: UpcomingSource.reminder,
  sourceId: input.id,
  title: input.title,
  dueAt: input.dueAt,
  daysAway: daysUntilDue(input.dueAt, today),
  amountMinor: input.amountMinor,
  currency: input.currency,
  recurringId: input.recurringId,
  categoryId: input.categoryId,
);

UpcomingItem _fromCardDue(CardDueInput input, DateTime today) => UpcomingItem(
  source: UpcomingSource.cardDue,
  sourceId: input.accountId,
  title: input.title,
  dueAt: input.dueAt,
  daysAway: daysUntilDue(input.dueAt, today),
  amountMinor: input.amountMinor,
  currency: input.currency,
);

int compareUpcoming(UpcomingItem first, UpcomingItem second) {
  final byDay = first.daysAway.compareTo(second.daysAway);
  if (byDay != 0) return byDay;
  final byTime = first.dueAt.compareTo(second.dueAt);
  if (byTime != 0) return byTime;
  final bySource = first.source.index.compareTo(second.source.index);
  return bySource != 0 ? bySource : first.title.compareTo(second.title);
}

/// Merges every source into one list sorted by due date.
///
/// Items due on days `fromDay..throughDay` (inclusive, counted from
/// [today]) are kept; with [includeOverdue] anything before today is kept as
/// well. Done reminders are dropped, and a recurring occurrence is dropped
/// when a reminder for the same rule falls on the same day.
List<UpcomingItem> mergeUpcoming({
  required DateTime today,
  required int throughDay,
  int fromDay = 0,
  bool includeOverdue = true,
  List<RecurringOccurrenceInput> recurring = const [],
  List<ReminderInput> reminders = const [],
  List<CardDueInput> cardDues = const [],
}) {
  final pendingReminders = reminders.where((reminder) => !reminder.isDone).toList();
  final remindedOccurrences = {
    for (final reminder in pendingReminders)
      if (reminder.recurringId != null) '${reminder.recurringId}@${_dayKey(reminder.dueAt)}',
  };
  final candidates = [
    for (final occurrence in recurring)
      if (!remindedOccurrences.contains('${occurrence.ruleId}@${_dayKey(occurrence.dueAt)}')) _fromRecurring(occurrence, today),
    for (final reminder in pendingReminders) _fromReminder(reminder, today),
    for (final cardDue in cardDues) _fromCardDue(cardDue, today),
  ];
  bool inRange(UpcomingItem item) => (includeOverdue && item.daysAway < 0) || (item.daysAway >= fromDay && item.daysAway <= throughDay);
  return candidates.where(inRange).toList()..sort(compareUpcoming);
}

/// The dashboard list: overdue items plus everything due from today through
/// the next [window] days.
List<UpcomingItem> upcomingWithin({
  required DateTime today,
  required UpcomingWindow window,
  List<RecurringOccurrenceInput> recurring = const [],
  List<ReminderInput> reminders = const [],
  List<CardDueInput> cardDues = const [],
}) => mergeUpcoming(today: today, throughDay: window.days, recurring: recurring, reminders: reminders, cardDues: cardDues);

/// Items due in the month containing [month] (calendar month), without
/// carrying earlier overdue items into it; for the due calendar.
List<UpcomingItem> upcomingInMonth({
  required DateTime today,
  required DateTime month,
  List<RecurringOccurrenceInput> recurring = const [],
  List<ReminderInput> reminders = const [],
  List<CardDueInput> cardDues = const [],
}) => mergeUpcoming(
  today: today,
  fromDay: daysUntilDue(DateTime(month.year, month.month), today),
  throughDay: daysUntilDue(DateTime(month.year, month.month + 1, 0), today),
  includeOverdue: false,
  recurring: recurring,
  reminders: reminders,
  cardDues: cardDues,
);

/// Groups items by calendar day (midnight keys), keeping each day's order.
Map<DateTime, List<UpcomingItem>> upcomingByDay(List<UpcomingItem> items) {
  final byDay = <DateTime, List<UpcomingItem>>{};
  for (final item in items) {
    byDay.putIfAbsent(startOfDay(item.dueAt), () => []).add(item);
  }
  return byDay;
}

/// Totals for the card header.
class UpcomingSummary {
  const UpcomingSummary({required this.overdueCount, required this.dueOutMinor});
  final int overdueCount;

  /// Sum of known outgoing amounts (income excluded) in the requested
  /// currency; items in other currencies or without an amount are skipped.
  final int dueOutMinor;
}

UpcomingSummary summariseUpcoming(List<UpcomingItem> items, {String currency = 'INR'}) => UpcomingSummary(
  overdueCount: items.where((item) => item.isOverdue).length,
  dueOutMinor: items.where((item) => !item.isIncome && item.currency == currency).fold(0, (sum, item) => sum + (item.amountMinor ?? 0)),
);

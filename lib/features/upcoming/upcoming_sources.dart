/// Maps stored rows to the plain inputs of the upcoming aggregator. Pure:
/// rows and dates in, inputs out, so the edge stays thin and testable.
library;

import '../../data/db/database.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../domain/recurring/recurrence.dart';
import '../../domain/reminders/reminder_kind.dart' show ReminderStatus;
import '../../domain/upcoming/upcoming_items.dart';

/// Occurrences of active rules inside [start, end), plus earlier ones still
/// waiting for confirmation (confirm-first rules whose next due is before
/// [today]). Auto-post rules never show past occurrences: they are posted.
List<RecurringOccurrenceInput> recurringOccurrenceInputs(
  List<RecurringRuleView> views, {
  required DateTime today,
  required DateTime start,
  required DateTime end,
  int monthStartDay = 1,
}) => [
  for (final view in views)
    if (view.rule.status == RecurringStatus.active && view.rule.nextDue != null)
      for (final occurrence in occurrencesBefore(
        specOf(view.rule),
        nextDue: view.rule.nextDue!,
        until: end,
        postedCount: view.rule.postedCount,
        monthStartDay: monthStartDay,
      ))
        if (!occurrence.isBefore(start) || (!view.rule.autoPost && occurrence.isBefore(today)))
          RecurringOccurrenceInput(
            ruleId: view.rule.id,
            title: recurringRuleTitle(view),
            dueAt: occurrence,
            amountMinor: view.rule.amountMinor,
            currency: view.rule.currency,
            isIncome: view.rule.kind == 'income',
            isSubscription: view.rule.isSubscription,
            categoryId: view.rule.categoryId,
          ),
];

/// The rule's name, else its payee; empty lets the UI fall back to the
/// localised category name.
String recurringRuleTitle(RecurringRuleView view) {
  final name = view.rule.name.trim();
  if (name.isNotEmpty) return name;
  return view.rule.payee?.trim() ?? '';
}

/// Pending due reminders that fall before [end]; earlier (overdue) ones are
/// kept, since the aggregator decides what an overdue item means.
List<ReminderInput> reminderInputs(List<Reminder> reminders, {required DateTime end}) => [
  for (final reminder in reminders)
    if (reminder.dueAt != null && reminder.dueAt!.isBefore(end))
      ReminderInput(
        id: reminder.id,
        title: reminder.title.trim(),
        dueAt: reminder.dueAt!,
        amountMinor: reminder.amountMinor,
        recurringId: reminder.recurringId,
        isDone: reminder.status != ReminderStatus.pending,
        categoryId: reminder.categoryId,
      ),
];

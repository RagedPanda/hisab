import '../../core/dates.dart';
import '../reminders/reminder_draft.dart';
import '../reminders/reminder_kind.dart';
import 'card_summary.dart';

/// Days before the due date a card-due reminder alerts: three days ahead
/// and on the day itself.
const kCardReminderDaysBefore = [3, 0];

/// One card-due reminder already stored for a card.
class ExistingCardReminder {
  const ExistingCardReminder({required this.id, required this.dueAt, required this.status, this.title = '', this.amountMinor});
  final String id;
  final DateTime dueAt;
  final String status;
  final String title;
  final int? amountMinor;

  bool get isPending => status == ReminderStatus.pending;
}

/// The writes that bring a card's reminders in line: at most one save
/// (create when its id is null, else update in place) and the pending
/// reminders to delete.
class CardReminderPlan {
  const CardReminderPlan({this.save, this.deleteIds = const []});
  final ReminderDraft? save;
  final List<String> deleteIds;

  bool get isEmpty => save == null && deleteIds.isEmpty;
}

/// The reminder a card should have for [due]; [existingId] updates in place.
ReminderDraft cardReminderDraft({required String accountId, required String cardName, required CardDue due, String? existingId}) {
  final amountDue = due.amountDueMinor;
  return ReminderDraft(
    id: existingId,
    kind: ReminderKind.card,
    title: cardName,
    accountId: accountId,
    dueAt: startOfDay(due.dueDate),
    amountMinor: amountDue != null && amountDue > 0 ? amountDue : null,
    remindDaysBefore: kCardReminderDaysBefore,
  );
}

/// Decides how to bring a card's reminders in line with its [due] date, so
/// the card ends up with at most one pending reminder.
///
/// [existing] is every live card reminder of the account, any status.
/// - No due date (due day cleared, card deleted or no longer a card): every
///   pending reminder is deleted; closed ones stay in history.
/// - A reminder the user already marked paid or skipped for this same due
///   date settles it: nothing is re-raised and stray pending ones go.
/// - Otherwise one pending reminder (the one on the due date if there is
///   one) is kept and updated when its date, amount or name changed, any
///   other pending ones are deleted, and a new one is created when none is
///   pending.
CardReminderPlan planCardReminder({
  required String accountId,
  required String cardName,
  required CardDue? due,
  required List<ExistingCardReminder> existing,
}) {
  final pending = [for (final reminder in existing) if (reminder.isPending) reminder];
  final allPendingIds = [for (final reminder in pending) reminder.id];
  if (due == null) return CardReminderPlan(deleteIds: allPendingIds);
  final settled = existing.any((reminder) => !reminder.isPending && isSameDay(reminder.dueAt, due.dueDate));
  if (settled) return CardReminderPlan(deleteIds: allPendingIds);
  final kept = _pick(pending, due.dueDate);
  final draft = cardReminderDraft(accountId: accountId, cardName: cardName, due: due, existingId: kept?.id);
  final extraIds = [for (final id in allPendingIds) if (id != kept?.id) id];
  return CardReminderPlan(save: kept != null && _matches(kept, draft) ? null : draft, deleteIds: extraIds);
}

/// The pending reminder to keep: the one already on [dueDate], else the first.
ExistingCardReminder? _pick(List<ExistingCardReminder> pending, DateTime dueDate) {
  if (pending.isEmpty) return null;
  return pending.firstWhere((reminder) => isSameDay(reminder.dueAt, dueDate), orElse: () => pending.first);
}

bool _matches(ExistingCardReminder existing, ReminderDraft draft) =>
    isSameDay(existing.dueAt, draft.dueAt) && existing.title == draft.title && existing.amountMinor == draft.amountMinor;

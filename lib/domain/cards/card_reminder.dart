import '../../core/dates.dart';
import '../reminders/reminder_draft.dart';
import '../reminders/reminder_kind.dart';
import 'card_summary.dart';

/// Days before the due date a card-due reminder alerts: three days ahead
/// and on the day itself.
const kCardReminderDaysBefore = [3, 0];

/// The card-due reminder already stored for a card (the latest one).
class ExistingCardReminder {
  const ExistingCardReminder({required this.id, required this.dueAt, required this.status, this.title = '', this.amountMinor});
  final String id;
  final DateTime dueAt;
  final String status;
  final String title;
  final int? amountMinor;

  bool get isPending => status == ReminderStatus.pending;
}

/// What to do with a card's automatic "card due" reminder.
sealed class CardReminderAction {
  const CardReminderAction();
}

/// The stored reminder already matches; nothing to write.
class KeepCardReminder extends CardReminderAction {
  const KeepCardReminder();
}

/// Create (draft.id null) or update (draft.id set) the reminder.
class SaveCardReminder extends CardReminderAction {
  const SaveCardReminder(this.draft);
  final ReminderDraft draft;
}

/// Remove the pending reminder: the card has no due day any more or is gone.
class DeleteCardReminder extends CardReminderAction {
  const DeleteCardReminder(this.id);
  final String id;
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

/// Decides how to bring a card's reminder in line with its [due] date.
///
/// - No due date (due day cleared, card deleted or no longer a card): a
///   pending reminder is deleted; closed ones stay in history.
/// - A reminder the user already marked paid or skipped for this same due
///   date is left alone, so it is not re-raised.
/// - Otherwise the pending reminder is updated when its date, amount or name
///   changed, or a new one is created when there is none or the last one
///   is closed.
CardReminderAction planCardReminder({
  required String accountId,
  required String cardName,
  required CardDue? due,
  required ExistingCardReminder? existing,
}) {
  if (due == null) {
    return existing != null && existing.isPending ? DeleteCardReminder(existing.id) : const KeepCardReminder();
  }
  if (existing != null && !existing.isPending && isSameDay(existing.dueAt, due.dueDate)) return const KeepCardReminder();
  final draft = cardReminderDraft(
    accountId: accountId,
    cardName: cardName,
    due: due,
    existingId: existing != null && existing.isPending ? existing.id : null,
  );
  if (existing != null && existing.isPending && _matches(existing, draft)) return const KeepCardReminder();
  return SaveCardReminder(draft);
}

bool _matches(ExistingCardReminder existing, ReminderDraft draft) =>
    isSameDay(existing.dueAt, draft.dueAt) && existing.title == draft.title && existing.amountMinor == draft.amountMinor;

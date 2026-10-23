import '../../core/dates.dart';
import '../reminders/reminder_draft.dart';
import '../reminders/reminder_kind.dart';
import 'card_summary.dart';

/// Days before the due date a card-due reminder alerts: three days ahead
/// and on the day itself.
const kCardReminderDaysBefore = [3, 0];

/// One card-due reminder already stored for a card: its [status] and its
/// full editable [draft] (so an update keeps what the user set on it).
class ExistingCardReminder {
  const ExistingCardReminder({required this.status, required this.draft});
  final String status;
  final ReminderDraft draft;

  String get id => draft.id!;
  DateTime get dueAt => draft.dueAt;
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

/// A new reminder for a card's bill [due], with the default alert days.
ReminderDraft cardReminderDraft({required String accountId, required String cardName, required CardDue due}) {
  final amountDue = due.amountDueMinor;
  return ReminderDraft(
    kind: ReminderKind.card,
    title: cardName,
    accountId: accountId,
    dueAt: startOfDay(due.dueDate),
    amountMinor: amountDue != null && amountDue > 0 ? amountDue : null,
    remindDaysBefore: kCardReminderDaysBefore,
  );
}

/// [stored] moved to the card's current bill: the name, due date and amount
/// follow the card; everything the user set on the reminder (alert days and
/// time, notes, repeat, matching) is kept. The defaults of
/// [cardReminderDraft] only apply to a newly created reminder.
ReminderDraft cardReminderUpdate(ReminderDraft stored, {required String cardName, required CardDue due}) {
  final fresh = cardReminderDraft(accountId: stored.accountId ?? '', cardName: cardName, due: due);
  return ReminderDraft(
    id: stored.id,
    kind: stored.kind,
    title: fresh.title,
    dueAt: fresh.dueAt,
    notes: stored.notes,
    amountMinor: fresh.amountMinor,
    categoryId: stored.categoryId,
    accountId: stored.accountId,
    recurringId: stored.recurringId,
    assetId: stored.assetId,
    repeat: stored.repeat,
    remindDaysBefore: stored.remindDaysBefore,
    notifyAtMinute: stored.notifyAtMinute,
    matchKeywords: stored.matchKeywords,
    toleranceMinor: stored.toleranceMinor,
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
///   one) is kept and moved when its date, amount or name changed (keeping
///   the user's alert days, see [cardReminderUpdate]), any
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
  final draft = kept == null
      ? cardReminderDraft(accountId: accountId, cardName: cardName, due: due)
      : cardReminderUpdate(kept.draft, cardName: cardName, due: due);
  final extraIds = [for (final id in allPendingIds) if (id != kept?.id) id];
  return CardReminderPlan(save: kept != null && _matches(kept, draft) ? null : draft, deleteIds: extraIds);
}

/// The pending reminder to keep: the one already on [dueDate], else the first.
ExistingCardReminder? _pick(List<ExistingCardReminder> pending, DateTime dueDate) {
  if (pending.isEmpty) return null;
  return pending.firstWhere((reminder) => isSameDay(reminder.dueAt, dueDate), orElse: () => pending.first);
}

bool _matches(ExistingCardReminder existing, ReminderDraft draft) =>
    isSameDay(existing.dueAt, draft.dueAt) && existing.draft.title == draft.title && existing.draft.amountMinor == draft.amountMinor;

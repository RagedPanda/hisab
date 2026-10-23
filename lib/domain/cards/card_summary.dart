/// What a credit card owes and when, from its account fields and the entries
/// that touched it. Pure.
library;

import '../../core/dates.dart';
import '../budget/budget_math.dart';
import 'card_cycle.dart';

/// The fields of an entry that matter to a card's cycle.
class CardMovement {
  const CardMovement({required this.kind, required this.amountMinor, required this.occurredAt, this.accountId, this.toAccountId});
  final String kind;
  final int amountMinor;
  final DateTime occurredAt;
  final String? accountId;
  final String? toAccountId;
}

/// Spend charged to [cardId] within [range]: purchases and transfers out of
/// the card, less refunds (income credited to it). Bill payments (transfers
/// into the card) are not spend.
int cycleSpendMinor(Iterable<CardMovement> movements, {required String cardId, required DateRange range}) {
  var total = 0;
  for (final movement in movements.where((movement) => range.contains(movement.occurredAt))) {
    if (movement.accountId != cardId) continue;
    total += switch (movement.kind) {
      'expense' || 'transfer' => movement.amountMinor,
      'income' => -movement.amountMinor,
      _ => 0,
    };
  }
  return total;
}

/// Bill payments into [cardId] on or after [since] (transfers to the card).
int paymentsSinceMinor(Iterable<CardMovement> movements, {required String cardId, required DateTime since}) => movements
    .where((movement) => movement.kind == 'transfer' && movement.toAccountId == cardId && !movement.occurredAt.isBefore(since))
    .fold(0, (sum, movement) => sum + movement.amountMinor);

/// Amount owed on a card: card balances are stored negative. Never negative.
int outstandingMinor(int balanceMinor) => balanceMinor < 0 ? -balanceMinor : 0;

/// Credit on a card (overpaid or refunded beyond what was owed). Never negative.
int cardCreditMinor(int balanceMinor) => balanceMinor > 0 ? balanceMinor : 0;

/// From this share of the limit utilisation is shown as high (above 30%
/// is what lenders and credit bureaus treat as heavy use).
const double kCardHighUtilisation = 0.3;

/// Semantic state of a card's utilisation, shared with budget bar colours.
BudgetBand utilisationBand(double fraction) => fraction >= 1
    ? BudgetBand.over
    : fraction > kCardHighUtilisation
        ? BudgetBand.nearLimit
        : BudgetBand.onTrack;

/// The date stamped on a statement amount entered [today]: the most recent
/// statement date when the statement day is known, else today.
DateTime statementDateForEntry(DateTime today, int? statementDay) =>
    statementDay == null ? DateTime(today.year, today.month, today.day) : previousStatementDate(today, statementDay);

/// The statement date to store after the editor saves [newAmountMinor]:
/// cleared with the amount, kept when the amount is unchanged, otherwise the
/// most recent statement date (see [statementDateForEntry]).
DateTime? lastStatementDateAfterEdit({
  required DateTime today,
  required int? statementDay,
  required int? newAmountMinor,
  int? previousAmountMinor,
  DateTime? previousAt,
}) {
  if (newAmountMinor == null) return null;
  if (newAmountMinor == previousAmountMinor && previousAt != null) return previousAt;
  return statementDateForEntry(today, statementDay);
}

enum CardDueState { upcoming, dueToday, overdue, paid }

class CardDue {
  const CardDue({required this.dueDate, required this.daysLeft, required this.state, this.amountDueMinor, this.nextDueDate});

  /// The bill's due date; for a paid bill, the date of the bill that was paid.
  final DateTime dueDate;

  /// Paid bills only: when the next bill falls due (null without a
  /// statement day). Reminders move on to this date.
  final DateTime? nextDueDate;

  /// The date the next alert belongs to: [nextDueDate] once paid, else [dueDate].
  /// Null when the bill is paid and the next one is not known yet.
  DateTime? get reminderDate => state == CardDueState.paid ? nextDueDate : dueDate;

  /// Calendar days from today to [dueDate]; negative when overdue.
  final int daysLeft;
  final CardDueState state;

  /// Unpaid part of the last statement; null when no statement is recorded.
  final int? amountDueMinor;
}

/// The bill to show for a card, or null when there is no due day to go on.
///
/// With a recorded statement: its unpaid remainder is due on the due day that
/// follows it, overdue once that passes; when fully paid the card shows paid
/// with that bill's due date, plus the next cycle's due date when the
/// statement day is known. Without a statement only the next due date is
/// known.
CardDue? cardDue({
  required DateTime today,
  required int? statementDay,
  required int? dueDay,
  int? lastStatementMinor,
  DateTime? lastStatementAt,
  int paidSinceStatementMinor = 0,
}) {
  if (dueDay == null) return null;
  if (lastStatementMinor != null && lastStatementAt != null) {
    final remaining = lastStatementMinor - paidSinceStatementMinor;
    final billedDue = dueDateForStatement(lastStatementAt, dueDay);
    if (remaining > 0) {
      final daysLeft = calendarDaysBetween(today, billedDue);
      return CardDue(dueDate: billedDue, daysLeft: daysLeft, state: _stateFor(daysLeft), amountDueMinor: remaining);
    }
    final nextDue = statementDay == null ? null : dueDateForStatement(nextStatementDate(_later(today, lastStatementAt), statementDay), dueDay);
    return CardDue(dueDate: billedDue, daysLeft: calendarDaysBetween(today, billedDue), state: CardDueState.paid, amountDueMinor: 0, nextDueDate: nextDue);
  }
  if (statementDay == null) return null;
  final due = upcomingDueDate(today, statementDay: statementDay, dueDay: dueDay);
  final daysLeft = calendarDaysBetween(today, due);
  return CardDue(dueDate: due, daysLeft: daysLeft, state: _stateFor(daysLeft));
}

CardDueState _stateFor(int daysLeft) => daysLeft < 0
    ? CardDueState.overdue
    : daysLeft == 0
        ? CardDueState.dueToday
        : CardDueState.upcoming;

/// The day after [statementAt] when that is later than [today], so a paid
/// statement never shows its own due date again.
DateTime _later(DateTime today, DateTime statementAt) {
  final afterStatement = DateTime(statementAt.year, statementAt.month, statementAt.day + 1);
  return afterStatement.isAfter(today) ? afterStatement : today;
}

/// Everything the card screen shows, derived from the account fields and the
/// movements since [movementsSince].
class CardOverview {
  const CardOverview({
    required this.outstandingMinor,
    this.creditMinor = 0,
    this.cycle,
    this.cycleSpendMinor,
    this.creditLimitMinor,
    this.due,
  });

  final int outstandingMinor;

  /// Credit on the card; when positive, [outstandingMinor] is 0.
  final int creditMinor;

  /// Current billing cycle; null without a statement day.
  final DateRange? cycle;
  final int? cycleSpendMinor;
  final int? creditLimitMinor;
  final CardDue? due;

  bool get hasLimit => (creditLimitMinor ?? 0) > 0;
  /// Credit still available; negative when over the limit.
  int? get availableMinor => hasLimit ? creditLimitMinor! - outstandingMinor : null;

  /// Share of the limit in use, 0 without a limit. May exceed 1.
  double get utilisation => hasLimit ? outstandingMinor / creditLimitMinor! : 0;
  int get utilisationPercent => (utilisation * 100).round().clamp(0, 999);
}

/// Earliest date the card overview needs movements from: the start of the
/// current cycle or the last statement date, whichever is earlier.
DateTime movementsSince({required DateTime today, int? statementDay, DateTime? lastStatementAt}) {
  final cycleStart = statementDay == null ? DateTime(today.year, today.month, today.day) : currentCycle(today, statementDay).start;
  if (lastStatementAt == null) return cycleStart;
  final statementStart = DateTime(lastStatementAt.year, lastStatementAt.month, lastStatementAt.day);
  return statementStart.isBefore(cycleStart) ? statementStart : cycleStart;
}

CardOverview buildCardOverview({
  required String cardId,
  required DateTime today,
  required int balanceMinor,
  required Iterable<CardMovement> movements,
  int? statementDay,
  int? dueDay,
  int? creditLimitMinor,
  int? lastStatementMinor,
  DateTime? lastStatementAt,
}) {
  final cycle = statementDay == null ? null : currentCycle(today, statementDay);
  final paid = lastStatementAt == null ? 0 : paymentsSinceMinor(movements, cardId: cardId, since: lastStatementAt);
  return CardOverview(
    outstandingMinor: outstandingMinor(balanceMinor),
    creditMinor: cardCreditMinor(balanceMinor),
    cycle: cycle,
    cycleSpendMinor: cycle == null ? null : cycleSpendMinor(movements, cardId: cardId, range: cycle),
    creditLimitMinor: creditLimitMinor,
    due: cardDue(
      today: today,
      statementDay: statementDay,
      dueDay: dueDay,
      lastStatementMinor: lastStatementMinor,
      lastStatementAt: lastStatementAt,
      paidSinceStatementMinor: paid,
    ),
  );
}

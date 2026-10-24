/// Timeline views of a group ledger: when everyone was last square, and what
/// each expense or payment meant for one member. Pure functions.
library;

import '../../core/dates.dart';
import 'debt_simplifier.dart';
import 'split_calculator.dart';

/// An expense on the group timeline: who paid how much, and each member's share.
class TimelineExpense {
  const TimelineExpense({required this.occurredAt, required this.paidMinor, required this.shareMinor});
  final DateTime occurredAt;

  /// Amount each payer put in, by member id.
  final Map<String, int> paidMinor;

  /// Amount each member owes for this expense, by member id.
  final Map<String, int> shareMinor;
}

/// A payment on the group timeline.
class TimelinePayment {
  const TimelinePayment({required this.occurredAt, required this.fromMemberId, required this.toMemberId, required this.amountMinor});
  final DateTime occurredAt;
  final String fromMemberId;
  final String toMemberId;
  final int amountMinor;
}

/// The last calendar day at whose end every member's running balance was
/// zero, or null when the group has never been square since its first
/// expense. Events are replayed a whole day at a time, so a payment dated the
/// same day as the expense it settles counts regardless of time of day.
DateTime? settledUpPoint({required List<TimelineExpense> expenses, required List<TimelinePayment> payments}) {
  final deltasByDay = <DateTime, Map<String, int>>{};
  void add(DateTime when, String memberId, int delta) {
    final day = deltasByDay.putIfAbsent(startOfDay(when), () => {});
    day.update(memberId, (value) => value + delta, ifAbsent: () => delta);
  }

  for (final expense in expenses) {
    expense.paidMinor.forEach((memberId, amount) => add(expense.occurredAt, memberId, amount));
    expense.shareMinor.forEach((memberId, amount) => add(expense.occurredAt, memberId, -amount));
  }
  for (final payment in payments) {
    add(payment.occurredAt, payment.fromMemberId, payment.amountMinor);
    add(payment.occurredAt, payment.toMemberId, -payment.amountMinor);
  }

  final days = deltasByDay.keys.toList()..sort();
  final running = <String, int>{};
  DateTime? lastSquareDay;
  for (final day in days) {
    deltasByDay[day]!.forEach((memberId, delta) => running.update(memberId, (value) => value + delta, ifAbsent: () => delta));
    if (running.values.every((balance) => balance == 0)) lastSquareDay = day;
  }
  return lastSquareDay;
}

/// What an expense meant for one member, from their point of view.
enum ExpenseEffectKind {
  /// They paid more than their share: others owe them the difference.
  lent,

  /// They paid less than their share: they owe the difference.
  borrowed,

  /// They paid exactly their own share, so nobody owes anyone because of them.
  paidOwnShare,

  /// Neither paid nor had a share.
  notInvolved,
}

/// [kind] with the amount that goes with it (lent or borrowed difference, or
/// the amount paid for [ExpenseEffectKind.paidOwnShare]; 0 when not involved).
typedef ExpenseEffect = ({ExpenseEffectKind kind, int amountMinor});

ExpenseEffect expenseEffectFor(String? memberId, TimelineExpense expense) {
  final paid = memberId == null ? 0 : expense.paidMinor[memberId] ?? 0;
  final share = memberId == null ? 0 : expense.shareMinor[memberId] ?? 0;
  final difference = paid - share;
  if (difference > 0) return (kind: ExpenseEffectKind.lent, amountMinor: difference);
  if (difference < 0) return (kind: ExpenseEffectKind.borrowed, amountMinor: -difference);
  if (paid > 0) return (kind: ExpenseEffectKind.paidOwnShare, amountMinor: paid);
  return (kind: ExpenseEffectKind.notInvolved, amountMinor: 0);
}

/// Whether [memberId] paid into or has a share of [expense].
bool expenseInvolves(String? memberId, TimelineExpense expense) =>
    memberId != null && ((expense.paidMinor[memberId] ?? 0) > 0 || (expense.shareMinor[memberId] ?? 0) > 0);

/// Whether [memberId] sent or received [payment].
bool paymentInvolves(String? memberId, TimelinePayment payment) =>
    memberId != null && (payment.fromMemberId == memberId || payment.toMemberId == memberId);

/// Builds the timeline form of a ledger expense.
TimelineExpense timelineExpenseOf(DateTime occurredAt, LedgerExpense expense) =>
    TimelineExpense(occurredAt: occurredAt, paidMinor: _sumByMember(expense.payers), shareMinor: _sumByMember(expense.shares));

Map<String, int> _sumByMember(List<SplitShare> amounts) {
  final byMember = <String, int>{};
  for (final amount in amounts) {
    byMember.update(amount.memberId, (value) => value + amount.amountMinor, ifAbsent: () => amount.amountMinor);
  }
  return byMember;
}

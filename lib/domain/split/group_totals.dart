/// Group spending totals for a period: what the group spent, what one member
/// paid and owed, and breakdowns by member and by category. Pure functions.
///
/// Payments between members are not spending: they never add to the group's
/// total or anyone's share, but they do move my balance, so the period's
/// payments I made or received count in [GroupTotals.myNetChangeMinor].
///
/// Everything here is for one group. Groups cannot be archived yet; when they
/// can, any overall total across groups must leave archived groups out.
library;

import '../../core/dates.dart';
import 'expense_totals.dart';
import 'group_timeline.dart';

/// One group expense as the totals see it: the timeline form (who paid how
/// much, who owes how much) plus its category.
class GroupTotalsExpense {
  const GroupTotalsExpense({required this.expense, this.categoryId, this.amountMinor});
  final TimelineExpense expense;

  /// Null when the expense has no category.
  final String? categoryId;

  /// The entry's recorded amount, the same figure the group export sums.
  /// Null falls back to [expenseTotalMinor].
  final int? amountMinor;

  /// What this expense cost the group.
  int get billMinor => amountMinor ?? expenseTotalMinor(expense);

  DateTime get occurredAt => expense.occurredAt;
}

/// What one member paid into and owed for the group's expenses.
class MemberSpend {
  const MemberSpend({required this.memberId, required this.paidMinor, required this.shareMinor});
  final String memberId;
  final int paidMinor;
  final int shareMinor;

  /// Positive: the expenses left others owing this member.
  int get netMinor => paidMinor - shareMinor;

  @override
  bool operator ==(Object other) => other is MemberSpend && other.memberId == memberId && other.paidMinor == paidMinor && other.shareMinor == shareMinor;

  @override
  int get hashCode => Object.hash(memberId, paidMinor, shareMinor);

  @override
  String toString() => '$memberId(paid $paidMinor, share $shareMinor)';
}

class GroupTotals {
  const GroupTotals({
    required this.totalSpentMinor,
    required this.myPaidMinor,
    required this.myShareMinor,
    required this.byMember,
    required this.byCategory,
    required this.expenseCount,
    this.myPaymentsSentMinor = 0,
    this.myPaymentsReceivedMinor = 0,
  });

  static const empty = GroupTotals(totalSpentMinor: 0, myPaidMinor: 0, myShareMinor: 0, byMember: [], byCategory: {}, expenseCount: 0);

  /// Everything the group spent: the sum of every expense's bill.
  final int totalSpentMinor;
  final int myPaidMinor;
  final int myShareMinor;

  /// Every member who paid or owed something, biggest share first.
  final List<MemberSpend> byMember;

  /// Group spend per category id ('' for expenses without a category).
  final Map<String, int> byCategory;
  final int expenseCount;

  /// Settle-up payments I made to other members in the period.
  final int myPaymentsSentMinor;

  /// Settle-up payments other members made to me in the period.
  final int myPaymentsReceivedMinor;

  /// How the period moved my balance: what I paid for expenses minus my share,
  /// plus payments I made, minus payments I received. Positive means I am owed
  /// more (or owe less) than at the start of the period.
  int get myNetChangeMinor => myPaidMinor - myShareMinor + myPaymentsSentMinor - myPaymentsReceivedMinor;
}

/// The bill of one expense. Shares and payers both add up to it; shares win
/// so an expense with no recorded payer still counts what it cost.
int expenseTotalMinor(TimelineExpense expense) {
  final shares = _sum(expense.shareMinor.values);
  return shares > 0 ? shares : _sum(expense.paidMinor.values);
}

/// Totals over [expenses] and [payments] that fall inside [range] (all of
/// them when null), seen from [myMemberId] (my figures are 0 when null).
GroupTotals computeGroupTotals({required List<GroupTotalsExpense> expenses, List<TimelinePayment> payments = const [], String? myMemberId, DateRange? range}) {
  final inRange = range == null ? expenses : expenses.where((item) => range.contains(item.occurredAt)).toList();
  final paymentsInRange = range == null ? payments : payments.where((payment) => range.contains(payment.occurredAt));
  final sums = sumExpenses([for (final item in inRange) (billMinor: item.billMinor, paidMinor: item.expense.paidMinor, shareMinor: item.expense.shareMinor)]);
  int myPayments(bool Function(TimelinePayment payment) isMine) =>
      myMemberId == null ? 0 : paymentsInRange.where(isMine).fold(0, (sum, payment) => sum + payment.amountMinor);
  return GroupTotals(
    totalSpentMinor: sums.totalMinor,
    myPaidMinor: myMemberId == null ? 0 : sums.paidByMember[myMemberId] ?? 0,
    myShareMinor: myMemberId == null ? 0 : sums.shareByMember[myMemberId] ?? 0,
    byMember: memberSpendOf(sums.paidByMember, sums.shareByMember),
    byCategory: spendByCategory(inRange),
    expenseCount: inRange.length,
    myPaymentsSentMinor: myPayments((payment) => payment.fromMemberId == myMemberId),
    myPaymentsReceivedMinor: myPayments((payment) => payment.toMemberId == myMemberId),
  );
}

/// Group spend per category id ('' for expenses without a category);
/// categories with nothing spent are left out.
Map<String, int> spendByCategory(Iterable<GroupTotalsExpense> expenses) {
  final byCategory = <String, int>{};
  for (final item in expenses.where((item) => item.billMinor > 0)) {
    byCategory.update(item.categoryId ?? '', (value) => value + item.billMinor, ifAbsent: () => item.billMinor);
  }
  return byCategory;
}

/// One row per member who paid or owed anything, biggest share first, then
/// biggest payment, then id so the order is stable.
List<MemberSpend> memberSpendOf(Map<String, int> paidByMember, Map<String, int> shareByMember) {
  final rows = [
    for (final memberId in {...paidByMember.keys, ...shareByMember.keys}) MemberSpend(memberId: memberId, paidMinor: paidByMember[memberId] ?? 0, shareMinor: shareByMember[memberId] ?? 0),
  ].where((row) => row.paidMinor != 0 || row.shareMinor != 0).toList();
  rows.sort((first, second) {
    final byShare = second.shareMinor.compareTo(first.shareMinor);
    if (byShare != 0) return byShare;
    final byPaid = second.paidMinor.compareTo(first.paidMinor);
    return byPaid != 0 ? byPaid : first.memberId.compareTo(second.memberId);
  });
  return rows;
}

/// The first day of every calendar month that has at least one expense,
/// newest first: the months the period picker offers.
List<DateTime> monthsWithExpenses(Iterable<GroupTotalsExpense> expenses) {
  final months = {for (final item in expenses) DateTime(item.occurredAt.year, item.occurredAt.month)}.toList()..sort((first, second) => second.compareTo(first));
  return months;
}

int _sum(Iterable<int> amounts) => amounts.fold(0, (sum, amount) => sum + amount);


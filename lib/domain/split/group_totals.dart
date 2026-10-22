/// Group spending totals for a period: what the group spent, what one member
/// paid and owed, and breakdowns by member and by category. Pure functions.
///
/// Payments between members are not spending, so only expenses count here.
library;

import '../../core/dates.dart';
import 'group_timeline.dart';

/// One group expense as the totals see it: the timeline form (who paid how
/// much, who owes how much) plus its category.
class GroupTotalsExpense {
  const GroupTotalsExpense({required this.expense, this.categoryId});
  final TimelineExpense expense;

  /// Null when the expense has no category.
  final String? categoryId;

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
  const GroupTotals({required this.totalSpentMinor, required this.myPaidMinor, required this.myShareMinor, required this.byMember, required this.byCategory, required this.expenseCount});

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

  /// How the period's expenses moved my balance: positive means I am owed more.
  int get myNetChangeMinor => myPaidMinor - myShareMinor;
}

/// The bill of one expense. Shares and payers both add up to it; shares win
/// so an expense with no recorded payer still counts what it cost.
int expenseTotalMinor(TimelineExpense expense) {
  final shares = _sum(expense.shareMinor.values);
  return shares > 0 ? shares : _sum(expense.paidMinor.values);
}

/// Totals over [expenses] that fall inside [range] (every expense when null),
/// seen from [myMemberId] (my figures are 0 when null).
GroupTotals computeGroupTotals({required List<GroupTotalsExpense> expenses, String? myMemberId, DateRange? range}) {
  final inRange = range == null ? expenses : expenses.where((item) => range.contains(item.occurredAt)).toList();
  final paidByMember = <String, int>{};
  final shareByMember = <String, int>{};
  final byCategory = <String, int>{};
  var total = 0;
  for (final item in inRange) {
    final bill = expenseTotalMinor(item.expense);
    total += bill;
    _addAll(paidByMember, item.expense.paidMinor);
    _addAll(shareByMember, item.expense.shareMinor);
    if (bill > 0) byCategory.update(item.categoryId ?? '', (value) => value + bill, ifAbsent: () => bill);
  }
  return GroupTotals(
    totalSpentMinor: total,
    myPaidMinor: myMemberId == null ? 0 : paidByMember[myMemberId] ?? 0,
    myShareMinor: myMemberId == null ? 0 : shareByMember[myMemberId] ?? 0,
    byMember: memberSpendOf(paidByMember, shareByMember),
    byCategory: byCategory,
    expenseCount: inRange.length,
  );
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

void _addAll(Map<String, int> into, Map<String, int> amounts) {
  amounts.forEach((memberId, amount) => into.update(memberId, (value) => value + amount, ifAbsent: () => amount));
}

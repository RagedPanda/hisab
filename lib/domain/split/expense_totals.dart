/// The one sum of a group's spending, shared by the totals screen and the
/// export: what the group spent overall and what each member paid and owed.
/// Payments between members settle debt; they are not spending, so callers
/// pass expenses only. Pure functions.
library;

/// One expense as amounts: its bill, who paid it and who owes it.
typedef ExpenseAmounts = ({int billMinor, Map<String, int> paidMinor, Map<String, int> shareMinor});

/// What the group spent overall, and what each member paid and owed of it.
typedef ExpenseTotals = ({int totalMinor, Map<String, int> paidByMember, Map<String, int> shareByMember});

/// Adds up [expenses]: the bills into the group total, and every payer's and
/// member's amounts into their own paid and share.
ExpenseTotals sumExpenses(Iterable<ExpenseAmounts> expenses) {
  var total = 0;
  final paid = <String, int>{};
  final share = <String, int>{};
  for (final expense in expenses) {
    total += expense.billMinor;
    _addAll(paid, expense.paidMinor);
    _addAll(share, expense.shareMinor);
  }
  return (totalMinor: total, paidByMember: paid, shareByMember: share);
}

void _addAll(Map<String, int> into, Map<String, int> amounts) {
  amounts.forEach((memberId, amount) => into.update(memberId, (value) => value + amount, ifAbsent: () => amount));
}

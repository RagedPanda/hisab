/// What an entry costs *me*, and the month roll-ups built from that.
///
/// A personal entry counts in full. A group entry counts only for my split
/// share: the rest was paid for other people and lives in the group ledger.
library;

/// The amount an entry contributes to my personal spend or income.
int myAmountMinorOf({required int amountMinor, required bool isGroupEntry, required int? myShareMinor}) =>
    isGroupEntry ? (myShareMinor ?? 0) : amountMinor;

/// One entry reduced to the fields the roll-ups need.
class LedgerLine {
  const LedgerLine({required this.kind, required this.amountMinor, required this.occurredAt, this.categoryId});
  final String kind;
  final int amountMinor;
  final DateTime occurredAt;
  final String? categoryId;
}

({int expense, int income}) totalsByKind(Iterable<LedgerLine> lines) {
  var expense = 0;
  var income = 0;
  for (final line in lines) {
    if (line.kind == 'expense') expense += line.amountMinor;
    if (line.kind == 'income') income += line.amountMinor;
  }
  return (expense: expense, income: income);
}

/// Total per category id for [kind]; entries without a category key on ''.
Map<String, int> totalsByCategory(Iterable<LedgerLine> lines, {String kind = 'expense'}) {
  final totals = <String, int>{};
  for (final line in lines.where((l) => l.kind == kind)) {
    totals.update(line.categoryId ?? '', (v) => v + line.amountMinor, ifAbsent: () => line.amountMinor);
  }
  return totals;
}

/// Expense total per calendar day (local midnight).
Map<DateTime, int> expenseByDay(Iterable<LedgerLine> lines) {
  final totals = <DateTime, int>{};
  for (final line in lines.where((l) => l.kind == 'expense')) {
    final day = DateTime(line.occurredAt.year, line.occurredAt.month, line.occurredAt.day);
    totals.update(day, (v) => v + line.amountMinor, ifAbsent: () => line.amountMinor);
  }
  return totals;
}

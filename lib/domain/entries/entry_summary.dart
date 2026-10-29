// Totals for a filtered list of entries: what the user spent and earned, and
// how much of each item they bought ("Buffalo milk 31.5 L · ₹2,362").

/// One listed entry as the summary sees it.
typedef SummaryEntry = ({String kind, int amountMinor, List<SummaryItem> items});

/// One item line on an entry.
typedef SummaryItem = ({String name, double quantity, String? unit, int amountMinor});

/// The same item summed across entries. Items group by name (case and spaces
/// ignored) and unit, so "1 L" and "1 kg" of the same name stay apart.
typedef ItemTotal = ({String name, double quantity, String? unit, int amountMinor, int entryCount});

typedef EntrySummary = ({int spentMinor, int incomeMinor, int expenseCount, List<ItemTotal> items});

EntrySummary summarizeEntries(Iterable<SummaryEntry> entries) {
  final expenses = entries.where((entry) => entry.kind == 'expense').toList();
  return (
    spentMinor: expenses.fold(0, (sum, entry) => sum + entry.amountMinor),
    incomeMinor: entries.where((entry) => entry.kind == 'income').fold(0, (sum, entry) => sum + entry.amountMinor),
    expenseCount: expenses.length,
    items: itemTotals(expenses),
  );
}

/// Item totals across [entries], biggest spend first.
List<ItemTotal> itemTotals(Iterable<SummaryEntry> entries) {
  final totals = <String, ItemTotal>{};
  for (final entry in entries) {
    for (final item in entry.items) {
      final key = '${item.name.trim().toLowerCase()}|${item.unit?.trim().toLowerCase() ?? ''}';
      final previous = totals[key];
      totals[key] = (
        name: previous?.name ?? item.name.trim(),
        quantity: (previous?.quantity ?? 0) + item.quantity,
        unit: previous?.unit ?? item.unit,
        amountMinor: (previous?.amountMinor ?? 0) + item.amountMinor,
        entryCount: (previous?.entryCount ?? 0) + 1,
      );
    }
  }
  return totals.values.toList()..sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
}

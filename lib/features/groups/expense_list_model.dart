/// Pure assembly of the group Expenses tab: filtering, the settled-up divider
/// and month sections. Rows carry their own payload so the widget layer
/// decides how each one renders.
library;

import '../../core/dates.dart';

enum ExpenseFilter { all, mine, unsettled }

/// One expense or payment as the list sees it.
class LedgerRow<T> {
  const LedgerRow({required this.source, required this.occurredAt, required this.totalMinor, required this.involvesMe, this.isPayment = false});
  final T source;
  final DateTime occurredAt;

  /// Counted in the month total; payments move money but are not spending.
  final int totalMinor;
  final bool involvesMe;
  final bool isPayment;
}

sealed class ExpenseListItem<T> {
  const ExpenseListItem();
}

class MonthHeaderItem<T> extends ExpenseListItem<T> {
  const MonthHeaderItem({required this.month, required this.totalMinor});

  /// First day of the month.
  final DateTime month;

  /// Sum of the expenses listed under this header.
  final int totalMinor;
}

class RowItem<T> extends ExpenseListItem<T> {
  const RowItem(this.row);
  final LedgerRow<T> row;
}

/// "Settled up to `day`": a toggle under Unsettled, a plain marker otherwise.
class SettledDividerItem<T> extends ExpenseListItem<T> {
  const SettledDividerItem({required this.day, required this.olderCount, required this.collapsible, required this.expanded});
  final DateTime day;
  final int olderCount;
  final bool collapsible;
  final bool expanded;
}

/// The filter a group opens with: Unsettled once it has been square at some
/// point, otherwise All.
ExpenseFilter defaultExpenseFilter(DateTime? settledUpTo) => settledUpTo == null ? ExpenseFilter.all : ExpenseFilter.unsettled;

/// Rows newest first, filtered, with month headers and the settled-up divider.
/// Rows dated on or before [settledUpTo] are "older"; under
/// [ExpenseFilter.unsettled] they stay hidden until [showOlder].
List<ExpenseListItem<T>> buildExpenseList<T>({
  required List<LedgerRow<T>> rows,
  required ExpenseFilter filter,
  required DateTime? settledUpTo,
  required bool showOlder,
}) {
  final visible = [
    for (final row in rows)
      if (filter != ExpenseFilter.mine || row.involvesMe) row,
  ]..sort((first, second) => second.occurredAt.compareTo(first.occurredAt));
  bool isOlder(LedgerRow<T> row) => settledUpTo != null && !startOfDay(row.occurredAt).isAfter(settledUpTo);
  final newer = visible.where((row) => !isOlder(row)).toList();
  final older = visible.where(isOlder).toList();
  if (settledUpTo == null || older.isEmpty) return _sectioned(visible);

  final collapsible = filter == ExpenseFilter.unsettled;
  final expanded = !collapsible || showOlder;
  return [
    ..._sectioned(newer),
    SettledDividerItem(day: settledUpTo, olderCount: older.length, collapsible: collapsible, expanded: expanded),
    if (expanded) ..._sectioned(older),
  ];
}

List<ExpenseListItem<T>> _sectioned<T>(List<LedgerRow<T>> newestFirst) {
  final items = <ExpenseListItem<T>>[];
  DateTime? currentMonth;
  for (final (index, row) in newestFirst.indexed) {
    final month = DateTime(row.occurredAt.year, row.occurredAt.month);
    if (month != currentMonth) {
      currentMonth = month;
      final monthTotal = newestFirst
          .skip(index)
          .takeWhile((other) => other.occurredAt.year == month.year && other.occurredAt.month == month.month)
          .fold(0, (sum, other) => sum + other.totalMinor);
      items.add(MonthHeaderItem(month: month, totalMinor: monthTotal));
    }
    items.add(RowItem(row));
  }
  return items;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/features/groups/expense_list_model.dart';

LedgerRow<String> _row(String name, DateTime when, {int total = 100, bool mine = true, bool payment = false}) =>
    LedgerRow(source: name, occurredAt: when, totalMinor: payment ? 0 : total, involvesMe: mine, isPayment: payment);

List<String> _describe(List<ExpenseListItem<String>> items) => [
      for (final item in items)
        switch (item) {
          MonthHeaderItem(:final month, :final totalMinor) => 'month ${month.month} $totalMinor',
          RowItem(:final row) => row.source,
          SettledDividerItem(:final olderCount, :final collapsible, :final expanded) => 'divider $olderCount ${collapsible ? 'toggle' : 'marker'} ${expanded ? 'open' : 'closed'}',
        },
    ];

void main() {
  final rows = [
    _row('villa', DateTime(2026, 9, 20), total: 9000),
    _row('settle', DateTime(2026, 10, 2), payment: true),
    _row('scooter', DateTime(2026, 10, 10), total: 2400, mine: false),
    _row('dinner', DateTime(2026, 10, 15), total: 4500),
  ];

  test('without a settled point everything is listed newest first under month headers', () {
    final items = buildExpenseList(rows: rows, filter: ExpenseFilter.all, settledUpTo: null, showOlder: false);
    expect(_describe(items), ['month 10 6900', 'dinner', 'scooter', 'settle', 'month 9 9000', 'villa']);
  });

  test('Unsettled hides rows on or before the settled day behind a closed toggle', () {
    final items = buildExpenseList(rows: rows, filter: ExpenseFilter.unsettled, settledUpTo: DateTime(2026, 10, 2), showOlder: false);
    expect(_describe(items), ['month 10 6900', 'dinner', 'scooter', 'divider 2 toggle closed']);
  });

  test('opening the toggle lists the older rows under their own month headers', () {
    final items = buildExpenseList(rows: rows, filter: ExpenseFilter.unsettled, settledUpTo: DateTime(2026, 10, 2), showOlder: true);
    expect(_describe(items), ['month 10 6900', 'dinner', 'scooter', 'divider 2 toggle open', 'month 10 0', 'settle', 'month 9 9000', 'villa']);
  });

  test('All keeps every row and marks the settled point without a toggle', () {
    final items = buildExpenseList(rows: rows, filter: ExpenseFilter.all, settledUpTo: DateTime(2026, 10, 2), showOlder: false);
    expect(_describe(items), ['month 10 6900', 'dinner', 'scooter', 'divider 2 marker open', 'month 10 0', 'settle', 'month 9 9000', 'villa']);
  });

  test('Mine drops rows that do not involve me and totals only what is left', () {
    final items = buildExpenseList(rows: rows, filter: ExpenseFilter.mine, settledUpTo: null, showOlder: false);
    expect(_describe(items), ['month 10 4500', 'dinner', 'settle', 'month 9 9000', 'villa']);
  });

  test('Mine with nothing involving me is empty', () {
    final others = [_row('scooter', DateTime(2026, 10, 10), mine: false)];
    expect(buildExpenseList(rows: others, filter: ExpenseFilter.mine, settledUpTo: null, showOlder: false), isEmpty);
  });

  test('a settled point after every row leaves only the divider under Unsettled', () {
    final items = buildExpenseList(rows: rows, filter: ExpenseFilter.unsettled, settledUpTo: DateTime(2026, 10, 15), showOlder: false);
    expect(_describe(items), ['divider 4 toggle closed']);
  });

  test('a group opens on Unsettled only once it has a settled point', () {
    expect(defaultExpenseFilter(null), ExpenseFilter.all);
    expect(defaultExpenseFilter(DateTime(2026, 10, 2)), ExpenseFilter.unsettled);
  });
}

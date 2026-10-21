import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/ledger/personal_totals.dart';

void main() {
  test('P2-1: group entries count only my share, personal entries in full', () {
    expect(myAmountMinorOf(amountMinor: 140000, isGroupEntry: true, myShareMinor: 46700), 46700);
    expect(myAmountMinorOf(amountMinor: 140000, isGroupEntry: true, myShareMinor: null), 0);
    expect(myAmountMinorOf(amountMinor: 140000, isGroupEntry: false, myShareMinor: null), 140000);
  });

  final lines = [
    LedgerLine(kind: 'expense', amountMinor: 6000, occurredAt: DateTime(2026, 10, 3, 9), categoryId: 'food'),
    LedgerLine(kind: 'expense', amountMinor: 46700, occurredAt: DateTime(2026, 10, 3, 21), categoryId: 'travel'),
    LedgerLine(kind: 'expense', amountMinor: 2500, occurredAt: DateTime(2026, 10, 4), categoryId: null),
    LedgerLine(kind: 'income', amountMinor: 500000, occurredAt: DateTime(2026, 10, 1), categoryId: 'salary'),
    LedgerLine(kind: 'transfer', amountMinor: 100000, occurredAt: DateTime(2026, 10, 2)),
  ];

  test('totals by kind ignore transfers', () {
    expect(totalsByKind(lines), (expense: 55200, income: 500000));
  });

  test('totals by category key uncategorised on empty string', () {
    expect(totalsByCategory(lines), {'food': 6000, 'travel': 46700, '': 2500});
    expect(totalsByCategory(lines, kind: 'income'), {'salary': 500000});
  });

  test('expense by day buckets on local midnight', () {
    expect(expenseByDay(lines), {DateTime(2026, 10, 3): 52700, DateTime(2026, 10, 4): 2500});
  });
}

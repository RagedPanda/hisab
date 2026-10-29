import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/entries/entry_summary.dart';

SummaryItem _item(String name, double quantity, String? unit, int amountMinor) => (name: name, quantity: quantity, unit: unit, amountMinor: amountMinor);

void main() {
  test('spent sums expenses only; income is kept apart', () {
    final summary = summarizeEntries([
      (kind: 'expense', amountMinor: 7500, items: const []),
      (kind: 'expense', amountMinor: 10500, items: const []),
      (kind: 'income', amountMinor: 8500000, items: const []),
      (kind: 'transfer', amountMinor: 600000, items: const []),
    ]);
    expect(summary.spentMinor, 18000);
    expect(summary.incomeMinor, 8500000);
    expect(summary.expenseCount, 2);
  });

  test('items add up by name and unit, biggest spend first', () {
    final totals = itemTotals([
      (kind: 'expense', amountMinor: 10500, items: [_item('Buffalo milk', 1, 'L', 7500), _item('Cow milk', 0.5, 'L', 3000)]),
      (kind: 'expense', amountMinor: 11250, items: [_item('buffalo milk ', 1.5, 'L', 11250)]),
      (kind: 'expense', amountMinor: 4000, items: [_item('Curd', 0.5, 'kg', 4000), _item('Curd', 1, 'L', 8000)]),
    ]);
    expect(totals.map((total) => total.name), ['Buffalo milk', 'Curd', 'Curd', 'Cow milk']);
    expect(totals.first.quantity, 2.5);
    expect(totals.first.amountMinor, 18750);
    expect(totals.first.entryCount, 2);
    expect(totals[1].unit, 'L', reason: 'the same name in another unit stays its own line');
  });

  test('income items do not count as purchases', () {
    final summary = summarizeEntries([
      (kind: 'income', amountMinor: 5000, items: [_item('Old newspaper', 3, 'kg', 5000)]),
    ]);
    expect(summary.items, isEmpty);
  });
}

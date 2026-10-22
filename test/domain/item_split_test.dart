import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/split/item_split.dart';
import 'package:hisab/domain/split/split_calculator.dart';

void main() {
  const items = [
    ItemSplitInput(amountMinor: 6000, memberIds: ['rahul', 'me'], label: 'Pizza'),
    ItemSplitInput(amountMinor: 2000, memberIds: ['rahul'], label: 'Coke'),
    ItemSplitInput(amountMinor: 2000, memberIds: [], label: 'Delivery', shared: true),
  ];

  test('summaries count non-shared items and give whole percentages', () {
    final outcome = computeSplit(totalMinor: 10000, method: SplitMethod.byItem, inputs: const [], items: items);
    expect(itemShareSummaries(outcome, items), const [
      ItemShareSummary(memberId: 'rahul', amountMinor: 6000, itemCount: 2, percent: 60),
      ItemShareSummary(memberId: 'me', amountMinor: 4000, itemCount: 1, percent: 40),
    ]);
  });

  test('a zero total gives zero percent', () {
    const zeroItems = [ItemSplitInput(amountMinor: 0, memberIds: ['me'])];
    final outcome = computeSplit(totalMinor: 0, method: SplitMethod.byItem, inputs: const [], items: zeroItems);
    expect(itemShareSummaries(outcome, zeroItems).single.percent, 0);
  });

  test('toggling a member keeps the group order', () {
    const order = ['me', 'rahul', 'priya'];
    expect(toggleItemMember(const ['priya'], 'me', order), ['me', 'priya']);
    expect(toggleItemMember(const ['me', 'priya'], 'me', order), ['priya']);
    expect(defaultItemMembers(order), order);
  });
}

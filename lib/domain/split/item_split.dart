/// Per-person view of a by-item split, for the line under the items list:
/// "Rahul ₹620 · 3 items · 31%". Pure, no Flutter imports.
library;

import 'split_calculator.dart';

class ItemShareSummary {
  const ItemShareSummary({required this.memberId, required this.amountMinor, required this.itemCount, required this.percent});

  final String memberId;
  final int amountMinor;

  /// Non-shared items this member is on; shared items count for nobody.
  final int itemCount;

  /// Whole-number share of the total, 0 when the total is 0.
  final int percent;

  @override
  bool operator ==(Object other) =>
      other is ItemShareSummary && other.memberId == memberId && other.amountMinor == amountMinor && other.itemCount == itemCount && other.percent == percent;

  @override
  int get hashCode => Object.hash(memberId, amountMinor, itemCount, percent);

  @override
  String toString() => '$memberId:$amountMinor/$itemCount/$percent%';
}

/// One summary per share in [outcome], in the outcome's order.
List<ItemShareSummary> itemShareSummaries(SplitOutcome outcome, List<ItemSplitInput> items) {
  final total = outcome.totalMinor;
  return [
    for (final share in outcome.shares)
      ItemShareSummary(
        memberId: share.memberId,
        amountMinor: share.amountMinor,
        itemCount: items.where((item) => !item.shared && item.memberIds.contains(share.memberId)).length,
        percent: total == 0 ? 0 : (share.amountMinor * 100 / total).round(),
      ),
  ];
}

/// Default assignment for a new item: everyone in the group shares it.
List<String> defaultItemMembers(List<String> memberIds) => List.unmodifiable(memberIds);

/// Toggles [memberId] on an item's member list, keeping the group's order.
List<String> toggleItemMember(List<String> current, String memberId, List<String> groupOrder) {
  final next = current.contains(memberId) ? current.where((id) => id != memberId).toSet() : {...current, memberId};
  return [for (final id in groupOrder) if (next.contains(id)) id];
}

/// Pure split arithmetic for group expenses. No I/O, no Flutter imports.
library;

import '../../core/money.dart';

/// Stored by [name]; UI labels live in the l10n dictionaries (see
/// `splitMethodLabel` in the split editor).
enum SplitMethod { equal, exact, percent, shares, adjustment, byItem }

/// One member's input for a split. Which field matters depends on the method:
/// - [included]   equal, adjustment: takes part in the equal share
/// - [amountMinor] exact: the member's exact amount; adjustment: +/- extra
/// - [weight]     percent: percentage; shares: number of shares
class SplitInput {
  const SplitInput({
    required this.memberId,
    this.included = true,
    this.amountMinor = 0,
    this.weight = 0,
  });

  final String memberId;
  final bool included;
  final int amountMinor;
  final double weight;

  SplitInput copyWith({bool? included, int? amountMinor, double? weight}) =>
      SplitInput(
        memberId: memberId,
        included: included ?? this.included,
        amountMinor: amountMinor ?? this.amountMinor,
        weight: weight ?? this.weight,
      );
}

/// A line item assigned to one or more members (itemised split).
///
/// A [shared] item (tax, delivery, service charge) ignores [memberIds] and is
/// split equally among everyone who holds at least one non-shared item.
class ItemSplitInput {
  const ItemSplitInput({
    required this.amountMinor,
    required this.memberIds,
    this.label = '',
    this.shared = false,
  });
  final int amountMinor;
  final List<String> memberIds;
  final String label;
  final bool shared;
}

class SplitShare {
  const SplitShare(this.memberId, this.amountMinor);
  final String memberId;
  final int amountMinor;

  @override
  String toString() => '$memberId:$amountMinor';

  @override
  bool operator ==(Object other) =>
      other is SplitShare &&
      other.memberId == memberId &&
      other.amountMinor == amountMinor;

  @override
  int get hashCode => Object.hash(memberId, amountMinor);
}

/// Why a split could not be computed. Language-free: the widget layer maps a
/// code plus its payload to a translated message (see `splitErrorMessage`).
enum SplitErrorCode {
  negativeTotal,
  nobodyIncluded,
  negativeAmounts,
  amountLeft,
  amountOver,
  negativeValues,
  percentMustTotal,
  noShares,
  percentLeft,
  percentOver,
  adjustmentsExceed,
  adjustmentNegativeShare,
  noItems,
  itemsExceed,
  itemUnassigned,
}

class SplitError {
  const SplitError(this.code, {this.amountMinor = 0, this.percent = 0, this.label = ''});

  final SplitErrorCode code;

  /// Money payload for `amountLeft`, `amountOver`, `adjustmentsExceed`, `itemsExceed`.
  final int amountMinor;

  /// Percentage payload for `percentLeft`, `percentOver`.
  final double percent;

  /// Item label payload for `itemUnassigned`.
  final String label;

  @override
  bool operator ==(Object other) =>
      other is SplitError && other.code == code && other.amountMinor == amountMinor && other.percent == percent && other.label == label;

  @override
  int get hashCode => Object.hash(code, amountMinor, percent, label);
}

class SplitOutcome {
  const SplitOutcome(this.shares, {this.error});
  const SplitOutcome.invalid(this.error) : shares = const [];

  final List<SplitShare> shares;
  final SplitError? error;
  bool get isValid => error == null;

  int get totalMinor => shares.fold(0, (sum, s) => sum + s.amountMinor);

  Map<String, int> asMap() => {for (final s in shares) s.memberId: s.amountMinor};
}

/// Computes how much each member owes for an expense of [totalMinor].
/// Always returns shares that sum exactly to [totalMinor] when valid.
SplitOutcome computeSplit({
  required int totalMinor,
  required SplitMethod method,
  required List<SplitInput> inputs,
  List<ItemSplitInput> items = const [],
  String? payerId,
}) {
  if (totalMinor < 0) return const SplitOutcome.invalid(SplitError(SplitErrorCode.negativeTotal));
  switch (method) {
    case SplitMethod.equal:
      return _equal(totalMinor, inputs);
    case SplitMethod.exact:
      return _exact(totalMinor, inputs);
    case SplitMethod.percent:
      return _weighted(totalMinor, inputs, requirePercentTotal: true);
    case SplitMethod.shares:
      return _weighted(totalMinor, inputs, requirePercentTotal: false);
    case SplitMethod.adjustment:
      return _adjustment(totalMinor, inputs);
    case SplitMethod.byItem:
      return _byItem(totalMinor, inputs, items, payerId);
  }
}

SplitOutcome _equal(int total, List<SplitInput> inputs) {
  final included = inputs.where((i) => i.included).toList();
  if (included.isEmpty) return const SplitOutcome.invalid(SplitError(SplitErrorCode.nobodyIncluded));
  final amounts = allocateProportionally(total, List.filled(included.length, 1));
  return SplitOutcome([
    for (var i = 0; i < included.length; i++)
      SplitShare(included[i].memberId, amounts[i]),
  ]);
}

SplitOutcome _exact(int total, List<SplitInput> inputs) {
  final sum = inputs.fold<int>(0, (acc, i) => acc + i.amountMinor);
  if (inputs.any((i) => i.amountMinor < 0)) {
    return const SplitOutcome.invalid(SplitError(SplitErrorCode.negativeAmounts));
  }
  if (sum != total) {
    final diff = total - sum;
    return SplitOutcome.invalid(
      diff > 0
          ? SplitError(SplitErrorCode.amountLeft, amountMinor: diff)
          : SplitError(SplitErrorCode.amountOver, amountMinor: -diff),
    );
  }
  return SplitOutcome([
    for (final i in inputs)
      if (i.amountMinor > 0) SplitShare(i.memberId, i.amountMinor),
  ]);
}

SplitOutcome _weighted(
  int total,
  List<SplitInput> inputs, {
  required bool requirePercentTotal,
}) {
  final active = inputs.where((i) => i.weight > 0).toList();
  if (inputs.any((i) => i.weight < 0)) {
    return const SplitOutcome.invalid(SplitError(SplitErrorCode.negativeValues));
  }
  if (active.isEmpty) {
    return SplitOutcome.invalid(
      SplitError(requirePercentTotal ? SplitErrorCode.percentMustTotal : SplitErrorCode.noShares),
    );
  }
  if (requirePercentTotal) {
    final sum = active.fold<double>(0, (acc, i) => acc + i.weight);
    if ((sum - 100).abs() > 0.001) {
      final diff = 100 - sum;
      return SplitOutcome.invalid(
        diff > 0
            ? SplitError(SplitErrorCode.percentLeft, percent: diff)
            : SplitError(SplitErrorCode.percentOver, percent: -diff),
      );
    }
  }
  final amounts = allocateProportionally(total, active.map((i) => i.weight).toList());
  return SplitOutcome([
    for (var i = 0; i < active.length; i++)
      SplitShare(active[i].memberId, amounts[i]),
  ]);
}

SplitOutcome _adjustment(int total, List<SplitInput> inputs) {
  final included = inputs.where((i) => i.included).toList();
  if (included.isEmpty) return const SplitOutcome.invalid(SplitError(SplitErrorCode.nobodyIncluded));
  final adjustments = included.fold<int>(0, (acc, i) => acc + i.amountMinor);
  final remainder = total - adjustments;
  if (remainder < 0) {
    return SplitOutcome.invalid(SplitError(SplitErrorCode.adjustmentsExceed, amountMinor: -remainder));
  }
  final equal = allocateProportionally(remainder, List.filled(included.length, 1));
  final shares = <SplitShare>[];
  for (var i = 0; i < included.length; i++) {
    final amount = included[i].amountMinor + equal[i];
    if (amount < 0) {
      return const SplitOutcome.invalid(SplitError(SplitErrorCode.adjustmentNegativeShare));
    }
    shares.add(SplitShare(included[i].memberId, amount));
  }
  return SplitOutcome(shares);
}

/// Each item is split equally among its members; whatever is left of the
/// total (tax, tip, delivery) is spread in proportion to each member's
/// item subtotal. Members with no items pay nothing.
/// Each non-shared item is split equally among its members. Shared items and
/// whatever the items leave of [total] (delivery, tax, tip) are split equally
/// among the members holding at least one non-shared item, or among the
/// included [inputs] when every item is shared. Every rounding remainder goes
/// to [payerId] when the payer has a share, so nobody else pays a stray paisa.
SplitOutcome _byItem(int total, List<SplitInput> inputs, List<ItemSplitInput> items, String? payerId) {
  if (items.isEmpty) return const SplitOutcome.invalid(SplitError(SplitErrorCode.noItems));
  final itemSum = items.fold<int>(0, (acc, item) => acc + item.amountMinor);
  if (itemSum > total) {
    return SplitOutcome.invalid(SplitError(SplitErrorCode.itemsExceed, amountMinor: itemSum - total));
  }
  final ownItems = items.where((item) => !item.shared).toList();
  for (final item in ownItems) {
    if (item.memberIds.isEmpty) {
      return SplitOutcome.invalid(SplitError(SplitErrorCode.itemUnassigned, label: item.label));
    }
  }
  final holders = _distinct([for (final item in ownItems) ...item.memberIds]);
  final sharers = holders.isNotEmpty ? holders : [for (final input in inputs) if (input.included) input.memberId];
  if (sharers.isEmpty) return const SplitOutcome.invalid(SplitError(SplitErrorCode.nobodyIncluded));
  final sharedPool = total - ownItems.fold<int>(0, (acc, item) => acc + item.amountMinor);
  final floors = <String, int>{for (final member in sharers) member: 0};
  void addFloors(int amount, List<String> members) {
    final distinctMembers = _distinct(members);
    final part = amount ~/ distinctMembers.length;
    for (final member in distinctMembers) {
      floors.update(member, (value) => value + part, ifAbsent: () => part);
    }
  }

  for (final item in ownItems) {
    addFloors(item.amountMinor, item.memberIds);
  }
  addFloors(sharedPool, sharers);
  final members = floors.keys.toList();
  final leftover = total - floors.values.fold<int>(0, (acc, value) => acc + value);
  final remainderParts = members.contains(payerId)
      ? [for (final member in members) member == payerId ? leftover : 0]
      : allocateProportionally(leftover, List.filled(members.length, 1));
  return SplitOutcome([
    for (var i = 0; i < members.length; i++) SplitShare(members[i], floors[members[i]]! + remainderParts[i]),
  ]);
}

List<String> _distinct(List<String> ids) => ids.toSet().toList();


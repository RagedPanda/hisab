/// Pure split arithmetic for group expenses. No I/O, no Flutter imports.
library;

import '../../core/money.dart';

enum SplitMethod {
  equal('Equally'),
  exact('Exact amounts'),
  percent('Percentages'),
  shares('Shares / ratio'),
  adjustment('Adjustments'),
  byItem('By item');

  const SplitMethod(this.label);
  final String label;
}

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
class ItemSplitInput {
  const ItemSplitInput({
    required this.amountMinor,
    required this.memberIds,
    this.label = '',
  });
  final int amountMinor;
  final List<String> memberIds;
  final String label;
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

class SplitOutcome {
  const SplitOutcome(this.shares, {this.error});
  const SplitOutcome.invalid(String message)
      : shares = const [],
        error = message;

  final List<SplitShare> shares;
  final String? error;
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
}) {
  if (totalMinor < 0) return const SplitOutcome.invalid('Amount cannot be negative');
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
      return _byItem(totalMinor, inputs, items);
  }
}

SplitOutcome _equal(int total, List<SplitInput> inputs) {
  final included = inputs.where((i) => i.included).toList();
  if (included.isEmpty) return const SplitOutcome.invalid('Select at least one person');
  final amounts = allocateProportionally(total, List.filled(included.length, 1));
  return SplitOutcome([
    for (var i = 0; i < included.length; i++)
      SplitShare(included[i].memberId, amounts[i]),
  ]);
}

SplitOutcome _exact(int total, List<SplitInput> inputs) {
  final sum = inputs.fold<int>(0, (acc, i) => acc + i.amountMinor);
  if (inputs.any((i) => i.amountMinor < 0)) {
    return const SplitOutcome.invalid('Amounts cannot be negative');
  }
  if (sum != total) {
    final diff = total - sum;
    return SplitOutcome.invalid(
      diff > 0
          ? '${formatMinor(diff)} left to assign'
          : '${formatMinor(-diff)} over the total',
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
    return const SplitOutcome.invalid('Values cannot be negative');
  }
  if (active.isEmpty) {
    return SplitOutcome.invalid(
      requirePercentTotal ? 'Percentages must add up to 100' : 'Enter at least one share',
    );
  }
  if (requirePercentTotal) {
    final sum = active.fold<double>(0, (acc, i) => acc + i.weight);
    if ((sum - 100).abs() > 0.001) {
      final diff = 100 - sum;
      return SplitOutcome.invalid(
        diff > 0
            ? '${_trim(diff)}% left to assign'
            : '${_trim(-diff)}% over 100',
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
  if (included.isEmpty) return const SplitOutcome.invalid('Select at least one person');
  final adjustments = included.fold<int>(0, (acc, i) => acc + i.amountMinor);
  final remainder = total - adjustments;
  if (remainder < 0) {
    return SplitOutcome.invalid('Adjustments exceed the total by ${formatMinor(-remainder)}');
  }
  final equal = allocateProportionally(remainder, List.filled(included.length, 1));
  final shares = <SplitShare>[];
  for (var i = 0; i < included.length; i++) {
    final amount = included[i].amountMinor + equal[i];
    if (amount < 0) {
      return const SplitOutcome.invalid('An adjustment makes a share negative');
    }
    shares.add(SplitShare(included[i].memberId, amount));
  }
  return SplitOutcome(shares);
}

/// Each item is split equally among its members; whatever is left of the
/// total (tax, tip, delivery) is spread in proportion to each member's
/// item subtotal. Members with no items pay nothing.
SplitOutcome _byItem(int total, List<SplitInput> inputs, List<ItemSplitInput> items) {
  if (items.isEmpty) return const SplitOutcome.invalid('Add at least one item');
  final itemSum = items.fold<int>(0, (acc, i) => acc + i.amountMinor);
  if (itemSum > total) {
    return SplitOutcome.invalid('Items exceed the total by ${formatMinor(itemSum - total)}');
  }
  final subtotal = <String, int>{};
  for (final item in items) {
    if (item.memberIds.isEmpty) {
      return SplitOutcome.invalid(
        'Assign "${item.label.isEmpty ? 'item' : item.label}" to someone',
      );
    }
    final parts = allocateProportionally(
      item.amountMinor,
      List.filled(item.memberIds.length, 1),
    );
    for (var i = 0; i < item.memberIds.length; i++) {
      subtotal.update(item.memberIds[i], (v) => v + parts[i], ifAbsent: () => parts[i]);
    }
  }
  final members = subtotal.keys.toList();
  final extras = allocateProportionally(
    total - itemSum,
    members.map((m) => subtotal[m]!.toDouble()).toList(),
  );
  return SplitOutcome([
    for (var i = 0; i < members.length; i++)
      SplitShare(members[i], subtotal[members[i]]! + extras[i]),
  ]);
}

String _trim(double value) {
  final text = value.toStringAsFixed(2);
  return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
}

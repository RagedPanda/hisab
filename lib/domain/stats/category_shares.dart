/// Category slices for the donut: sub-categories rolled into their parent,
/// the biggest [top] kept and the rest bucketed as "Others". Pure.
library;

class CategoryShare {
  const CategoryShare({required this.categoryId, required this.minor, required this.fraction});

  /// Null for the "Others" bucket; '' for entries without a category.
  final String? categoryId;
  final int minor;
  final double fraction;

  bool get isOthers => categoryId == null;
}

/// Sums each category's total into its parent (or itself when it has none).
/// Ids missing from [parentOf] are treated as uncategorised.
Map<String, int> rollUpToParents(Map<String, int> totals, Map<String, String?> parentOf) {
  final rolled = <String, int>{};
  for (final entry in totals.entries) {
    final known = parentOf.containsKey(entry.key);
    final key = known ? (parentOf[entry.key] ?? entry.key) : '';
    rolled.update(key, (value) => value + entry.value, ifAbsent: () => entry.value);
  }
  return rolled;
}

/// Largest [top] categories by amount, descending, followed by one "Others"
/// share when more remain. Zero and negative totals are dropped.
List<CategoryShare> categoryShares(Map<String, int> totals, {int top = 5}) {
  final sorted = totals.entries.where((entry) => entry.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
  final total = sorted.fold<int>(0, (sum, entry) => sum + entry.value);
  if (total == 0) return const [];
  final kept = sorted.take(top);
  final rest = sorted.skip(top).fold<int>(0, (sum, entry) => sum + entry.value);
  return [
    for (final entry in kept) CategoryShare(categoryId: entry.key, minor: entry.value, fraction: entry.value / total),
    if (rest > 0) CategoryShare(categoryId: null, minor: rest, fraction: rest / total),
  ];
}

/// Whole percents for [shares], in order, that always total 100 (largest
/// remainder): each share gets its floor, then the shares that lost the most
/// to rounding get one more point until the total is reached. Ties go to the
/// earlier (bigger) share. Rounding each share alone can total 99 or 101.
List<int> sharePercents(List<CategoryShare> shares) => largestRemainderPercents([for (final share in shares) share.minor]);

/// Largest-remainder split of [amounts] into whole percents summing to 100.
/// Non-positive amounts get 0; all-zero input gives all zeros. Exact on ints.
List<int> largestRemainderPercents(List<int> amounts) {
  final total = amounts.fold<int>(0, (sum, amount) => sum + (amount > 0 ? amount : 0));
  if (total == 0) return [for (final _ in amounts) 0];
  final scaled = [for (final amount in amounts) amount > 0 ? amount * 100 : 0];
  final floors = [for (final value in scaled) value ~/ total];
  final remainders = [for (final value in scaled) value % total];
  final shortfall = 100 - floors.fold<int>(0, (sum, value) => sum + value);
  final byRemainder = [for (var index = 0; index < amounts.length; index++) index]
    ..sort((a, b) {
      final larger = remainders[b].compareTo(remainders[a]);
      return larger != 0 ? larger : a.compareTo(b);
    });
  final bumped = byRemainder.take(shortfall).toSet();
  return [for (var index = 0; index < amounts.length; index++) floors[index] + (bumped.contains(index) ? 1 : 0)];
}

/// Rotation (degrees, fl_chart `startDegreeOffset`) that puts the middle of
/// slice [index] at 12 o'clock; 0 when nothing is selected.
double startDegreeForShare(List<CategoryShare> shares, int? index) {
  if (index == null || index < 0 || index >= shares.length) return 0;
  final before = shares.take(index).fold<double>(0, (sum, share) => sum + share.fraction);
  return -90 - before * 360 - shares[index].fraction * 180;
}

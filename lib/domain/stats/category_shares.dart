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

/// Whole percent for a legend row, so a list of rows reads 44, 30, 26.
int sharePercent(CategoryShare share) => (share.fraction * 100).round();

/// Rotation (degrees, fl_chart `startDegreeOffset`) that puts the middle of
/// slice [index] at 12 o'clock; 0 when nothing is selected.
double startDegreeForShare(List<CategoryShare> shares, int? index) {
  if (index == null || index < 0 || index >= shares.length) return 0;
  final before = shares.take(index).fold<double>(0, (sum, share) => sum + share.fraction);
  return -90 - before * 360 - shares[index].fraction * 180;
}

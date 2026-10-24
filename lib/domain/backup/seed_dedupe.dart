/// Picks which copy of a seeded row to keep when the same seed exists more
/// than once (a backup restored over a fresh install's seed). Pure.
library;

class SeedCandidate {
  const SeedCandidate({required this.id, required this.key, this.references = 0, this.removable = true});

  final String id;

  /// What makes two rows the same seed: a category's seed key, or "cash:Cash".
  final String key;

  /// How many rows point at this one; the busiest copy is the natural keeper.
  final int references;

  /// False when dropping the row would lose data (an account with a balance
  /// or entries), so it stays even if it is a duplicate.
  final bool removable;
}

/// Duplicate id to the id that replaces it. Per key the keeper is, in order:
/// an id in [preferIds] (rows just restored), the most referenced copy, a
/// copy that cannot be removed, then the smallest id so the choice is stable.
Map<String, String> planSeedDedupe(List<SeedCandidate> candidates, {Set<String> preferIds = const {}}) {
  final byKey = <String, List<SeedCandidate>>{};
  for (final candidate in candidates) {
    byKey.putIfAbsent(candidate.key, () => []).add(candidate);
  }
  int rank(SeedCandidate a, SeedCandidate b) {
    final preferred = (preferIds.contains(b.id) ? 1 : 0).compareTo(preferIds.contains(a.id) ? 1 : 0);
    if (preferred != 0) return preferred;
    final busier = b.references.compareTo(a.references);
    if (busier != 0) return busier;
    final kept = (b.removable ? 0 : 1).compareTo(a.removable ? 0 : 1);
    if (kept != 0) return kept;
    return a.id.compareTo(b.id);
  }

  final plan = <String, String>{};
  for (final copies in byKey.values.where((copies) => copies.length > 1)) {
    final ranked = [...copies]..sort(rank);
    for (final duplicate in ranked.skip(1).where((copy) => copy.removable)) {
      plan[duplicate.id] = ranked.first.id;
    }
  }
  return plan;
}

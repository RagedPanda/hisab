/// Which quick entries Home shows as chips and how many wait behind
/// "+N more". Pure.
library;

const kQuickEntriesShownKey = 'quickEntriesShown';
const kDefaultQuickEntriesShown = 4;
const kMinQuickEntriesShown = 1;
const kMaxQuickEntriesShown = 8;

/// [count] kept within what the Home strip can show.
int clampQuickEntriesShown(int count) => count.clamp(kMinQuickEntriesShown, kMaxQuickEntriesShown);

/// The first [shownCount] of [entries] in order, and how many are left for
/// "+N more". When only one would be left it is shown instead, since a
/// "+1 more" chip takes the same room as the entry itself.
({List<T> shown, int hidden}) splitQuickEntries<T>(List<T> entries, int shownCount) {
  final limit = clampQuickEntriesShown(shownCount);
  if (entries.length <= limit + 1) return (shown: entries, hidden: 0);
  return (shown: entries.take(limit).toList(), hidden: entries.length - limit);
}

/// The ids in [ids] with the one at [oldIndex] moved to [newIndex], the
/// position it ends up at once moved.
List<String> reorderedIds(List<String> ids, int oldIndex, int newIndex) {
  final rest = [...ids]..removeAt(oldIndex);
  return [...rest.take(newIndex), ids[oldIndex], ...rest.skip(newIndex)];
}

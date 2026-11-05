/// Helpers for making a category straight from the picker's search: the name
/// to offer, whether one already exists, and which parent to suggest. Pure.
library;

/// What these helpers need to know of one category: its stored and
/// localised names (so a Hindi label counts as a match too).
typedef CategoryOption = ({String id, String? parentId, String? seedKey, List<String> names});

const _accentFolds = {
  'a': 'àáâãäåā', 'c': 'çć', 'e': 'èéêëē', 'i': 'ìíîïī', 'n': 'ñ', 'o': 'òóôõöøō', 'u': 'ùúûüū', 'y': 'ýÿ',
};

final Map<String, String> _foldByChar = {
  for (final entry in _accentFolds.entries)
    for (final accented in entry.value.split('')) accented: entry.key,
};

/// [text] lower-cased, trimmed, inner whitespace collapsed and common Latin
/// accents dropped, for comparing category names: `  Café ` == `cafe`.
String foldCategoryName(String text) =>
    text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').split('').map((char) => _foldByChar[char] ?? char).join();

/// The name to offer for a search [query]: trimmed, inner whitespace
/// collapsed, first letter capitalised and the rest kept as typed.
String categoryNameFromQuery(String query) {
  final tidy = query.trim().replaceAll(RegExp(r'\s+'), ' ');
  return tidy.isEmpty ? tidy : tidy[0].toUpperCase() + tidy.substring(1);
}

bool _namedAs(CategoryOption option, String folded) => option.names.any((name) => foldCategoryName(name) == folded);

/// Whether any of [options] is called exactly [query] (see [foldCategoryName]).
bool hasCategoryNamed(String query, Iterable<CategoryOption> options) {
  final folded = foldCategoryName(query);
  return folded.isNotEmpty && options.any((option) => _namedAs(option, folded));
}

/// The category called [name] directly under [parentId] (top level when
/// null), so creating it again picks that one instead of a duplicate.
CategoryOption? existingCategoryNamed(String name, Iterable<CategoryOption> options, {String? parentId}) {
  final folded = foldCategoryName(name);
  if (folded.isEmpty) return null;
  for (final option in options) {
    if (option.parentId == parentId && _namedAs(option, folded)) return option;
  }
  return null;
}

/// Words of three or more letters, for loose matching.
List<String> _words(String text) => foldCategoryName(text).split(RegExp(r'[^\p{L}\p{N}\p{M}]+', unicode: true)).where((word) => word.length >= 3).toList();

bool _wordsMeet(String a, String b) => a.startsWith(b) || b.startsWith(a);

int _overlap(List<String> wanted, CategoryOption option) {
  final words = [for (final name in option.names) ..._words(name)];
  return wanted.where((want) => words.any((word) => _wordsMeet(want, word))).length;
}

/// The top-level category a new category called [name] most likely belongs
/// under: the parent of the category sharing the most words with it, else
/// the parent of the category whose seed key is [keywordKey] (a merchant
/// keyword guess), else null. Ties go to the earlier option.
String? suggestParentId(String name, List<CategoryOption> options, {String? keywordKey}) {
  final wanted = _words(name);
  CategoryOption? best;
  var bestScore = 0;
  for (final option in options) {
    final score = wanted.isEmpty ? 0 : _overlap(wanted, option);
    if (score > bestScore) {
      best = option;
      bestScore = score;
    }
  }
  best ??= keywordKey == null ? null : options.where((option) => option.seedKey == keywordKey).firstOrNull;
  return best == null ? null : best.parentId ?? best.id;
}

/// Colour for a new top-level category: the first of [palette] no top-level
/// category uses yet, else the palette cycled by how many there are.
int nextCategoryColor(List<int> topLevelColors, List<int> palette) {
  final used = topLevelColors.toSet();
  return palette.where((color) => !used.contains(color)).firstOrNull ?? palette[topLevelColors.length % palette.length];
}

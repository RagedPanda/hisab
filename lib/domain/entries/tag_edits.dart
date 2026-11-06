/// Counting, renaming, merging and removing tags across entries' tags text.
/// Pure; tag text is read and written with [parseTags] and [formatTags].
library;

import 'entry_filter.dart';

/// One tag in use and how many entries carry it.
typedef TagCount = ({String tag, int count});

/// Every tag across [rawTags] (one tags text per entry) with the number of
/// entries carrying it, most used first, then by name ignoring case. Tags
/// differing only in case count as one, under the first spelling seen.
List<TagCount> countTags(Iterable<String> rawTags) {
  final spelling = <String, String>{};
  final counts = <String, int>{};
  for (final raw in rawTags) {
    for (final tag in parseTags(raw)) {
      final key = tag.toLowerCase();
      spelling.putIfAbsent(key, () => tag);
      counts.update(key, (count) => count + 1, ifAbsent: () => 1);
    }
  }
  return [for (final MapEntry(:key, value: count) in counts.entries) (tag: spelling[key]!, count: count)]
    ..sort((a, b) => b.count != a.count ? b.count.compareTo(a.count) : a.tag.toLowerCase().compareTo(b.tag.toLowerCase()));
}

/// The tag among [tags] that is [name] ignoring case, other than [except]
/// (the tag being renamed), so a rename onto it can be offered as a merge.
String? otherTagNamed(String name, Iterable<String> tags, {required String except}) {
  final key = name.toLowerCase();
  final skip = except.toLowerCase();
  return tags.where((tag) => tag.toLowerCase() == key && tag.toLowerCase() != skip).firstOrNull;
}

bool _carries(List<String> tags, String tag) => tags.any((each) => each.toLowerCase() == tag.toLowerCase());

/// [raw] with tag [from] (any case) renamed to [to]. When the entry already
/// carries [to] (in any spelling) the two merge into one, spelled [to], in
/// the place of the first. [raw] comes back as is when it lacks [from].
String withTagRenamed(String raw, String from, String to) {
  final tags = parseTags(raw);
  if (!_carries(tags, from)) return raw;
  final renamed = [for (final tag in tags) _carries([from, to], tag) ? to : tag];
  return formatTags(parseTags(formatTags(renamed)));
}

/// [raw] without tag [tag] (any case); as is when it lacks it.
String withoutTag(String raw, String tag) {
  final tags = parseTags(raw);
  if (!_carries(tags, tag)) return raw;
  return formatTags(tags.where((each) => each.toLowerCase() != tag.toLowerCase()));
}

/// What saving a rename of tag [current] as [input] does.
enum TagRenameKind {
  /// [input] is not one tag name (see [tagNameFrom]).
  invalid,

  /// Same name, same spelling: nothing to do.
  unchanged,

  /// A new name, or [current] respelled.
  rename,

  /// The name of another tag in use: the two become one.
  merge,
}

/// The outcome of renaming [current] to [input] given every tag in use
/// ([tags]), with the name to rename to: [input] tidied, or the other tag's
/// own spelling for a merge.
({TagRenameKind kind, String? to}) planTagRename(String current, String input, Iterable<String> tags) {
  final name = tagNameFrom(input);
  if (name == null) return (kind: TagRenameKind.invalid, to: null);
  if (name == current) return (kind: TagRenameKind.unchanged, to: name);
  final other = otherTagNamed(name, tags, except: current);
  return other == null ? (kind: TagRenameKind.rename, to: name) : (kind: TagRenameKind.merge, to: other);
}

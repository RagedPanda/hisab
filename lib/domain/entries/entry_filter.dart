/// Search and filter rules for the Entries list. Pure, no Flutter or Drift.
library;

import '../categories/category_filter.dart';

const Object _keep = Object();

/// The filters chosen in the Entries filter sheet. Every field is optional;
/// an unset field lets every entry through. [from] and [to] are whole days,
/// both inclusive.
class EntryFilter {
  const EntryFilter({
    this.projectId,
    this.categoryId,
    this.accountId,
    this.minAmountMinor,
    this.maxAmountMinor,
    this.from,
    this.to,
    this.tag,
  });

  final String? projectId;
  final String? categoryId;
  final String? accountId;
  final int? minAmountMinor;
  final int? maxAmountMinor;
  final DateTime? from;
  final DateTime? to;
  final String? tag;

  bool get hasAmount => minAmountMinor != null || maxAmountMinor != null;
  bool get hasDates => from != null || to != null;

  /// How many filters are on; an amount range or a date range counts once.
  int get activeCount => [projectId != null, categoryId != null, accountId != null, hasAmount, hasDates, tag != null].where((on) => on).length;
  bool get isEmpty => activeCount == 0;

  /// Pass a value to change a field, `null` to clear it; omitted fields stay.
  EntryFilter copyWith({
    Object? projectId = _keep,
    Object? categoryId = _keep,
    Object? accountId = _keep,
    Object? minAmountMinor = _keep,
    Object? maxAmountMinor = _keep,
    Object? from = _keep,
    Object? to = _keep,
    Object? tag = _keep,
  }) =>
      EntryFilter(
        projectId: identical(projectId, _keep) ? this.projectId : projectId as String?,
        categoryId: identical(categoryId, _keep) ? this.categoryId : categoryId as String?,
        accountId: identical(accountId, _keep) ? this.accountId : accountId as String?,
        minAmountMinor: identical(minAmountMinor, _keep) ? this.minAmountMinor : minAmountMinor as int?,
        maxAmountMinor: identical(maxAmountMinor, _keep) ? this.maxAmountMinor : maxAmountMinor as int?,
        from: identical(from, _keep) ? this.from : from as DateTime?,
        to: identical(to, _keep) ? this.to : to as DateTime?,
        tag: identical(tag, _keep) ? this.tag : tag as String?,
      );

  /// The period to load when dates are set: the first day's midnight up to
  /// (not including) the midnight after the last day.
  ({DateTime start, DateTime end})? get dateWindow {
    if (!hasDates) return null;
    final first = from ?? DateTime(1900);
    final last = to ?? DateTime(9999);
    return (start: DateTime(first.year, first.month, first.day), end: DateTime(last.year, last.month, last.day + 1));
  }
}

/// The parts of an entry that search and filters look at.
class EntryFacts {
  const EntryFacts({
    required this.amountMinor,
    required this.occurredAt,
    this.note = '',
    this.payee,
    this.categoryId,
    this.categoryParentId,
    this.categoryNames = const [],
    this.itemNames = const [],
    this.accountId,
    this.toAccountId,
    this.projectId,
    this.tags = '',
  });

  final int amountMinor;
  final DateTime occurredAt;
  final String note;
  final String? payee;
  final String? categoryId;
  final String? categoryParentId;

  /// Stored and localised names, so a Hindi search finds Hindi labels.
  final List<String> categoryNames;
  final List<String> itemNames;
  final String? accountId;
  final String? toAccountId;
  final String? projectId;

  /// Raw tags text as stored on the entry.
  final String tags;
}

/// Tags written as `#home, trip` or `home trip`: split on commas and spaces,
/// `#` dropped, duplicates removed ignoring case, first spelling kept.
List<String> parseTags(String raw) {
  final seen = <String>{};
  return [
    for (final part in raw.split(RegExp(r'[,\s]+')))
      if (part.replaceFirst(RegExp('^#+'), '') case final tag when tag.isNotEmpty && seen.add(tag.toLowerCase())) tag,
  ];
}

/// Every tag used across [rawTags], sorted case-insensitively.
List<String> distinctTags(Iterable<String> rawTags) {
  final byLower = <String, String>{};
  for (final raw in rawTags) {
    for (final tag in parseTags(raw)) {
      byLower.putIfAbsent(tag.toLowerCase(), () => tag);
    }
  }
  return byLower.values.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
}

/// Whether [query] appears (ignoring case) in the payee, note, item names,
/// category names or tags. A blank query matches everything.
bool matchesSearch(String query, EntryFacts facts) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  return [facts.payee ?? '', facts.note, facts.tags, ...facts.itemNames, ...facts.categoryNames].any((text) => text.toLowerCase().contains(needle));
}

/// Whether the entry passes every filter that is on.
bool matchesEntryFilter(EntryFilter filter, EntryFacts facts) {
  if (filter.projectId != null && facts.projectId != filter.projectId) return false;
  if (filter.categoryId != null &&
      !matchesCategoryFilter(selectedId: filter.categoryId!, categoryId: facts.categoryId, parentId: facts.categoryParentId)) {
    return false;
  }
  if (filter.accountId != null && facts.accountId != filter.accountId && facts.toAccountId != filter.accountId) return false;
  final amount = facts.amountMinor.abs();
  if (filter.minAmountMinor != null && amount < filter.minAmountMinor!) return false;
  if (filter.maxAmountMinor != null && amount > filter.maxAmountMinor!) return false;
  final window = filter.dateWindow;
  if (window != null && (facts.occurredAt.isBefore(window.start) || !facts.occurredAt.isBefore(window.end))) return false;
  if (filter.tag != null && !parseTags(facts.tags).any((tag) => tag.toLowerCase() == filter.tag!.toLowerCase())) return false;
  return true;
}

/// Why an amount range cannot be applied, or null when it can.
enum AmountRangeError { minAboveMax }

AmountRangeError? validateAmountRange(int? minMinor, int? maxMinor) =>
    minMinor != null && maxMinor != null && minMinor > maxMinor ? AmountRangeError.minAboveMax : null;

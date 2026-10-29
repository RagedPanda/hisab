/// "Split this": turning a saved personal expense into a group expense.
/// Pure, no Flutter or Drift.
///
/// The entry keeps its id and becomes the group expense, so it is never
/// counted twice: from then on the ledger counts only my share of it
/// (`myAmountMinorOf` in `lib/domain/ledger/personal_totals.dart`).
library;

/// Whether a saved entry can be split with a group: a personal expense.
/// Income, transfers and entries already in a group cannot.
bool canSplitEntry({required String kind, required String? groupId}) => kind == 'expense' && groupId == null;

/// Groups an entry can be split into, in their given order: live groups I am
/// still a member of. Archived groups and ones I left are left out.
List<T> splitTargetGroups<T>(
  Iterable<T> groups, {
  required bool Function(T group) isArchived,
  required bool Function(T group) includesMe,
}) =>
    [for (final group in groups) if (!isArchived(group) && includesMe(group)) group];

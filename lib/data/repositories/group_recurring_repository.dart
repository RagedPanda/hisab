import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../domain/split/group_recurring.dart';
import '../db/database.dart';
import 'entries_repository.dart';
import 'recurring_repository.dart';

/// What happened to one occurrence of a recurring rule.
enum OccurrencePost {
  posted,

  /// The occurrence's entry already exists (posting twice is a no-op).
  alreadyPosted,

  /// A group rule whose remembered split no longer works; the rule waits
  /// for the person instead of guessing.
  blocked,
}

/// Recurring group expenses (rent, maid, wifi). The schedule
/// and catch-up loop are the shared engine in [RecurringRepository]; this
/// class only knows how a group occurrence is split and paid.
class GroupRecurringRepository {
  GroupRecurringRepository(this.db);
  final AppDatabase db;

  /// Ids of a posted occurrence's split and payer rows, stable per member so
  /// re-posting the same occurrence writes the same rows.
  static String occurrenceSplitId(String entryId, String memberId) => stableId('$entryId:split:$memberId');
  static String occurrencePayerId(String entryId, String memberId) => stableId('$entryId:payer:$memberId');

  /// Turns a personal rule companion into a group rule.
  static RecurringRulesCompanion asGroupRule(RecurringRulesCompanion rule, {required String groupId, required GroupExpenseTemplate template}) =>
      rule.copyWith(groupId: Value(groupId), groupSplit: Value(template.encode()), accountId: const Value(null), toAccountId: const Value(null));

  /// Writes the entry, splits and payers for one occurrence of a group rule.
  Future<OccurrencePost> postOccurrence(RecurringRule rule, DateTime occurrence) async {
    final groupId = rule.groupId!;
    // Group rules are expense-only: income or transfers have no shared split.
    if (!isGroupRuleKind(rule.kind)) return OccurrencePost.blocked;
    final entryId = occurrenceEntryId(rule.id, occurrence);
    final exists = await (db.select(db.entries)..where((t) => t.id.equals(entryId))).getSingleOrNull();
    if (exists != null) return OccurrencePost.alreadyPosted;
    final template = GroupExpenseTemplate.decode(rule.groupSplit);
    final group = await (db.select(db.groups)..where((t) => t.id.equals(groupId) & t.deletedAt.isNull())).getSingleOrNull();
    if (template == null || group == null) return OccurrencePost.blocked;
    final members = await (db.select(db.members)..where((t) => t.groupId.equals(groupId) & t.deletedAt.isNull())).get();
    final result = groupOccurrence(template, amountMinor: rule.amountMinor, activeMemberIds: {for (final member in members) member.id});
    if (!result.canPost) return OccurrencePost.blocked;
    await EntriesRepository(db).saveEntry(
      entryForOccurrence(rule, occurrence).copyWith(
        groupId: Value(groupId),
        paidByMemberId: Value(result.paidByMemberId),
        splitMethod: Value(template.method.name),
        accountId: const Value(null),
        toAccountId: const Value(null),
      ),
      splits: [
        for (final split in result.splits)
          SplitsCompanion.insert(
            id: occurrenceSplitId(entryId, split.memberId),
            entryId: entryId,
            memberId: split.memberId,
            amountMinor: split.amountMinor,
            shareValue: Value(split.shareValue),
          ),
      ],
      payers: [
        for (final payer in result.payers)
          EntryPayersCompanion.insert(id: occurrencePayerId(entryId, payer.memberId), entryId: entryId, memberId: payer.memberId, amountMinor: payer.amountMinor),
      ],
    );
    return OccurrencePost.posted;
  }
}

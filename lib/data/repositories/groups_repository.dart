import 'dart:math';

import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../domain/split/debt_simplifier.dart';
import '../../domain/split/group_net.dart';
import '../../domain/split/group_settings.dart';
import '../../domain/split/group_activity.dart';
import '../../domain/split/group_timeline.dart';
import '../../domain/split/group_totals.dart';
import '../../domain/split/split_calculator.dart';
import '../db/database.dart';
import '../db/watch_tables.dart';
import 'entries_repository.dart';
import 'people_repository.dart';

/// [Reminders.kind] for "please settle up" nudges sent from the balances tab.
const settleUpReminderKind = 'settle_up';

class GroupSummary {
  const GroupSummary({required this.group, required this.members, required this.myNetMinor, required this.totalSpentMinor});
  final Group group;
  final List<Member> members;

  /// Positive: others owe me. Negative: I owe.
  final int myNetMinor;
  final int totalSpentMinor;
}

class GroupBalances {
  const GroupBalances({required this.net, required this.suggested, required this.pairwise});
  final Map<String, int> net;

  /// Transfers shown under Settle up: simplified or pairwise per the group setting.
  final List<Transfer> suggested;

  /// Direct debts regardless of the simplify setting; the removal guard uses
  /// these so a member sitting inside a chain can never be removed (AND-08).
  final List<Transfer> pairwise;

  /// Repayments the simplify setting saves over paying every debt directly.
  int get repaymentsSaved => pairwise.length - simplifyDebts(net).length;
}

/// Everything the group detail screen shows, recomputed as one unit so the
/// tabs never mix snapshots taken at different times.
class GroupDetail {
  const GroupDetail({
    required this.group,
    required this.members,
    required this.allMembers,
    required this.entries,
    required this.settlements,
    required this.balances,
    required this.timelineByEntryId,
    required this.settledUpTo,
    this.lastRemindedAt = const {},
  });
  final Group group;

  /// Current members, me first.
  final List<Member> members;

  /// Every member ever in the group, soft-deleted ones included, so names in
  /// history never fall back to "Unknown".
  final List<Member> allMembers;
  final List<GroupEntry> entries;
  final List<Settlement> settlements;
  final GroupBalances balances;

  /// Each expense as payers and shares, keyed by entry id.
  final Map<String, TimelineExpense> timelineByEntryId;

  /// Last day everyone was square, or null if never (see [settledUpPoint]).
  final DateTime? settledUpTo;

  /// When I last sent each member a settle-up reminder, keyed by member id.
  final Map<String, DateTime> lastRemindedAt;

  Member? get me => members.where((member) => member.isMe).firstOrNull;

  /// Every expense with a payer, with its category, for the totals screen.
  List<GroupTotalsExpense> get totalsExpenses => [
        for (final (entry, _, _) in entries)
          if (timelineByEntryId[entry.id] case final expense?) GroupTotalsExpense(expense: expense, categoryId: entry.categoryId, amountMinor: entry.amountMinor),
      ];

  /// Settle-up payments between members, for my balance change on the totals screen.
  List<TimelinePayment> get totalsPayments => settlements.map(timelinePaymentOf).toList();

  /// Whether I can leave: I am a member and no debt, direct or simplified,
  /// involves me (the same rule as removing any other member).
  bool get canLeave {
    final myId = me?.id;
    return myId != null && isMemberSettled(memberId: myId, net: balances.net, transfers: balances.pairwise);
  }
}

/// What I am owed and owe across the active groups in [summaries], one total
/// per currency (each group's label, or [appSymbol]), app currency first.
/// Labels are never converted, so different currencies are never added.
List<CurrencyTotals> groupTotalsByCurrency(Iterable<GroupSummary> summaries, {required String appSymbol}) => groupNetTotalsByCurrency([
      for (final summary in summaries)
        if (summary.group.archivedAt == null) (symbol: groupSymbol(currencyLabel: summary.group.currencyLabel, appSymbol: appSymbol), net: summary.myNetMinor),
    ], appSymbol: appSymbol);

/// A group expense with its splits and, when several members paid, its payer
/// rows (empty for a single payer).
typedef GroupEntry = (Entry, List<Split>, List<EntryPayer>);

/// The activity log as a feed shows it: decoded rows (newest first) with the
/// names and groups they mention.
class ActivityFeed {
  const ActivityFeed({required this.activities, required this.membersById, required this.groupsById, required this.restorableIds, this.deletedExpenseIds = const {}});
  final List<ActivityRecord> activities;

  /// Every member of the groups shown, removed ones included.
  final Map<String, Member> membersById;

  /// The groups the rows belong to. Deleted groups appear only with their
  /// own deletion and restore rows.
  final Map<String, Group> groupsById;

  /// Rows that offer Restore (see [restorableActivityIds]).
  final Set<String> restorableIds;

  /// Expenses the feed mentions that are deleted now, so rows do not open them.
  final Set<String> deletedExpenseIds;
}

class GroupsRepository {
  GroupsRepository(this.db) : _entries = EntriesRepository(db);
  final AppDatabase db;
  final EntriesRepository _entries;

  Stream<List<Group>> watchGroups() => (db.select(db.groups)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  Future<Group?> getGroup(String id) => (db.select(db.groups)..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();

  Stream<Group?> watchGroup(String id) =>
      (db.select(db.groups)..where((t) => t.id.equals(id))).watchSingleOrNull();

  SimpleSelectStatement<$MembersTable, Member> _membersQuery(String groupId) => db.select(db.members)
    ..where((t) => t.groupId.equals(groupId) & t.deletedAt.isNull())
    ..orderBy([(t) => OrderingTerm.desc(t.isMe), (t) => OrderingTerm.asc(t.name)]);

  SimpleSelectStatement<$SettlementsTable, Settlement> _settlementsQuery(String groupId) => db.select(db.settlements)
    ..where((t) => t.groupId.equals(groupId) & t.deletedAt.isNull())
    ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]);

  SimpleSelectStatement<$EntriesTable, Entry> _entriesQuery(String groupId) => db.select(db.entries)
    ..where((t) => t.groupId.equals(groupId) & t.deletedAt.isNull())
    ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]);

  Stream<List<Member>> watchMembers(String groupId) => _membersQuery(groupId).watch();
  Future<List<Member>> getMembers(String groupId) => _membersQuery(groupId).get();

  /// Members including soft-deleted ones, for resolving names in history.
  Future<List<Member>> getAllMembers(String groupId) => (db.select(db.members)
        ..where((t) => t.groupId.equals(groupId))
        ..orderBy([(t) => OrderingTerm.desc(t.isMe), (t) => OrderingTerm.asc(t.name)]))
      .get();

  Stream<List<Settlement>> watchSettlements(String groupId) => _settlementsQuery(groupId).watch();
  Future<List<Settlement>> getSettlements(String groupId) => _settlementsQuery(groupId).get();

  /// Group entries with their splits and payers; emits whenever the entries change.
  Stream<List<GroupEntry>> watchGroupEntries(String groupId) =>
      _entriesQuery(groupId).watch().asyncMap(_withSplits);

  Future<List<GroupEntry>> getGroupEntries(String groupId) async =>
      _withSplits(await _entriesQuery(groupId).get());

  /// Loads the splits and payer rows of [entries] in one query each.
  Future<List<GroupEntry>> _withSplits(List<Entry> entries) async {
    final ids = entries.map((e) => e.id).toList();
    if (ids.isEmpty) return const [];
    final splits = await (db.select(db.splits)..where((t) => t.entryId.isIn(ids) & t.deletedAt.isNull())).get();
    final payers = await (db.select(db.entryPayers)..where((t) => t.entryId.isIn(ids) & t.deletedAt.isNull())).get();
    final splitsByEntry = _groupByEntry(splits, (split) => split.entryId);
    final payersByEntry = _groupByEntry(payers, (payer) => payer.entryId);
    return [for (final e in entries) (e, splitsByEntry[e.id] ?? const <Split>[], payersByEntry[e.id] ?? const <EntryPayer>[])];
  }

  static Map<String, List<T>> _groupByEntry<T>(List<T> rows, String Function(T row) entryIdOf) {
    final grouped = <String, List<T>>{};
    for (final row in rows) {
      (grouped[entryIdOf(row)] ??= []).add(row);
    }
    return grouped;
  }

  /// Tables whose changes can move a group's balances.
  List<TableInfo> get _ledgerTables => [db.groups, db.members, db.entries, db.splits, db.entryPayers, db.settlements];

  Stream<GroupBalances> watchBalances(String groupId) => db.watchTables(_ledgerTables, () => getBalances(groupId));

  Future<GroupBalances> getBalances(String groupId) async => (await getGroupDetail(groupId))?.balances ?? computeBalances(members: const [], entries: const [], settlements: const [], simplify: true);

  Stream<GroupDetail?> watchGroupDetail(String groupId) => db.watchTables([..._ledgerTables, db.reminders], () => getGroupDetail(groupId));

  /// Null when the group does not exist (or was deleted and the screen is closing).
  Future<GroupDetail?> getGroupDetail(String groupId) async {
    final group = await (db.select(db.groups)..where((t) => t.id.equals(groupId) & t.deletedAt.isNull())).getSingleOrNull();
    if (group == null) return null;
    final allMembers = await getAllMembers(groupId);
    final members = allMembers.where((member) => member.deletedAt == null).toList();
    final entries = await getGroupEntries(groupId);
    final settlements = await getSettlements(groupId);
    final timelineByEntryId = timelineOf(entries);
    final lastRemindedAt = await getLastRemindedAt(groupId);
    return GroupDetail(
      group: group,
      members: members,
      allMembers: allMembers,
      entries: entries,
      settlements: settlements,
      balances: computeBalances(members: members, entries: entries, settlements: settlements, simplify: group.simplifyDebts),
      timelineByEntryId: timelineByEntryId,
      settledUpTo: settledUpPoint(
        expenses: timelineByEntryId.values.toList(),
        payments: settlements.map(timelinePaymentOf).toList(),
      ),
      lastRemindedAt: lastRemindedAt,
    );
  }

  /// Latest settle-up reminder sent to each member of the group, in one query.
  Future<Map<String, DateTime>> getLastRemindedAt(String groupId) async {
    final lastSent = db.reminders.sentAt.max();
    final rows = await (db.selectOnly(db.reminders)
          ..addColumns([db.reminders.memberId, lastSent])
          ..where(db.reminders.groupId.equals(groupId) &
              db.reminders.kind.equals(settleUpReminderKind) &
              db.reminders.deletedAt.isNull() &
              db.reminders.memberId.isNotNull() &
              db.reminders.sentAt.isNotNull())
          ..groupBy([db.reminders.memberId]))
        .get();
    return {
      for (final row in rows) row.read(db.reminders.memberId)!: ?row.read(lastSent),
    };
  }

  /// Logs that I asked [memberId] to settle up, through [channel].
  Future<String> recordSettleUpReminder({required String groupId, required String memberId, required String channel, required String message, DateTime? sentAt}) async {
    final id = newId();
    await db.into(db.reminders).insert(RemindersCompanion.insert(
          id: id,
          kind: settleUpReminderKind,
          groupId: Value(groupId),
          memberId: Value(memberId),
          sentAt: Value(sentAt ?? DateTime.now()),
          channel: Value(channel),
          message: Value(message),
        ));
    return id;
  }

  /// Expenses with a payer, as timeline entries keyed by entry id.
  static Map<String, TimelineExpense> timelineOf(List<GroupEntry> entries) => {
        for (final (entry, splits, payers) in entries)
          if (ledgerExpenseOf(entry, splits, payers) case final expense?) entry.id: timelineExpenseOf(entry.occurredAt, expense),
      };

  /// The ledger form of a group expense, or null when it has no payer. Payer
  /// rows win over [Entry.paidByMemberId] when several members paid.
  static LedgerExpense? ledgerExpenseOf(Entry entry, List<Split> splits, [List<EntryPayer> payers = const []]) {
    final shares = [for (final split in splits) SplitShare(split.memberId, split.amountMinor)];
    if (payers.isNotEmpty) {
      return LedgerExpense.multi(payers: [for (final payer in payers) SplitShare(payer.memberId, payer.amountMinor)], shares: shares);
    }
    final payerId = entry.paidByMemberId;
    return payerId == null ? null : LedgerExpense(paidByMemberId: payerId, shares: shares);
  }

  static GroupBalances computeBalances({
    required List<Member> members,
    required List<GroupEntry> entries,
    required List<Settlement> settlements,
    required bool simplify,
  }) {
    final ledger = [
      for (final (entry, splits, payers) in entries)
        ?ledgerExpenseOf(entry, splits, payers),
    ];
    final paid = [
      for (final s in settlements)
        LedgerSettlement(fromMemberId: s.fromMemberId, toMemberId: s.toMemberId, amountMinor: s.amountMinor),
    ];
    final net = computeNetBalances(memberIds: members.map((m) => m.id), expenses: ledger, settlements: paid);
    final pairwise = pairwiseDebts(expenses: ledger, settlements: paid);
    return GroupBalances(net: net, suggested: simplify ? simplifyDebts(net) : pairwise, pairwise: pairwise);
  }

  Stream<List<GroupSummary>> watchSummaries() => db.watchTables(_ledgerTables, getSummaries);

  Future<List<GroupSummary>> getSummaries() async {
    final groups = await (db.select(db.groups)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return [for (final group in groups) await _summarise(group)];
  }

  Future<GroupSummary> _summarise(Group group) async {
    final members = await getMembers(group.id);
    final entries = await getGroupEntries(group.id);
    final settlements = await getSettlements(group.id);
    final balances = computeBalances(members: members, entries: entries, settlements: settlements, simplify: group.simplifyDebts);
    final me = members.where((m) => m.isMe).firstOrNull;
    return GroupSummary(
      group: group,
      members: members,
      myNetMinor: me == null ? 0 : balances.net[me.id] ?? 0,
      totalSpentMinor: entries.fold(0, (sum, e) => sum + e.$1.amountMinor),
    );
  }

  Future<String> createGroup({required String name, required String icon, required String myName, List<String> otherMembers = const []}) async {
    final id = newId();
    await db.transaction(() async {
      await db.into(db.groups).insert(GroupsCompanion.insert(
            id: id,
            name: name,
            icon: Value(icon),
            inviteCode: Value(_inviteCode()),
          ));
      await db.into(db.members).insert(MembersCompanion.insert(id: newId(), groupId: id, name: myName, isMe: const Value(true)));
      for (final other in otherMembers) {
        if (other.trim().isEmpty) continue;
        await db.into(db.members).insert(MembersCompanion.insert(id: newId(), groupId: id, name: other.trim()));
      }
    });
    return id;
  }

  Future<void> updateGroup(GroupsCompanion group) =>
      (db.update(db.groups)..where((t) => t.id.equals(group.id.value))).write(group.copyWith(updatedAt: Value(DateTime.now())));

  /// Soft-deletes a group and its live expenses, logging which expenses
  /// those were so [restoreGroup] brings back exactly them. Members and
  /// payments are left as they are; they disappear with the group.
  Future<void> deleteGroup(String id) => db.transaction(() async {
        final group = await (db.select(db.groups)..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
        if (group == null) return;
        final liveExpenses = await (db.select(db.entries)..where((t) => t.groupId.equals(id) & t.deletedAt.isNull())).get();
        final now = DateTime.now();
        await (db.update(db.groups)..where((t) => t.id.equals(id))).write(GroupsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
        await (db.update(db.entries)..where((t) => t.groupId.equals(id) & t.deletedAt.isNull())).write(EntriesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
        await _log(groupId: id, action: ActivityAction.deleted, subject: ActivitySubject.group, subjectId: id, before: _groupSnapshotOf(group, [for (final entry in liveExpenses) entry.id]));
      });

  /// Hides the group under "Archived" on the groups list; nothing is deleted.
  Future<void> archiveGroup(String id) => _setArchived(id, DateTime.now());

  Future<void> unarchiveGroup(String id) => _setArchived(id, null);

  Future<void> _setArchived(String id, DateTime? archivedAt) =>
      updateGroup(GroupsCompanion(id: Value(id), archivedAt: Value(archivedAt)));

  /// Leaves the group on this device: removes my member and archives the
  /// group so its history stays readable. Returns false, changing nothing,
  /// while any debt still involves me.
  Future<bool> leaveGroup(String groupId) async {
    final detail = await getGroupDetail(groupId);
    final me = detail?.me;
    if (detail == null || me == null || !detail.canLeave) return false;
    await db.transaction(() async {
      await removeMember(me.id);
      await archiveGroup(groupId);
    });
    return true;
  }

  /// Weight a member starts with when an expense is split by shares.
  Future<void> setMemberWeight(String memberId, double weight) =>
      updateMember(MembersCompanion(id: Value(memberId), weight: Value(weight)));

  /// Labels the group's amounts with [label] (null: follow the app setting).
  Future<void> setCurrencyLabel(Group group, String? label) => updateGroup(GroupsCompanion(
        id: Value(group.id),
        currencyLabel: Value(label),
        currency: Value(currencyCodeFor(label, fallbackCode: group.currency)),
      ));

  /// Brings back a deleted group with the expenses it had when deleted (not
  /// ones deleted before it), so every balance is as it was. Older logs
  /// without that list fall back to the expenses tombstoned with the group.
  Future<void> restoreGroup(String id) => db.transaction(() async {
        final group = await (db.select(db.groups)..where((t) => t.id.equals(id))).getSingleOrNull();
        final deletedAt = group?.deletedAt;
        if (group == null || deletedAt == null) return;
        final deletedState = switch (await _lastDeletedSnapshot(id)) {
          final GroupSnapshot snapshot => snapshot,
          _ => null,
        };
        final now = DateTime.now();
        await (db.update(db.groups)..where((t) => t.id.equals(id))).write(GroupsCompanion(deletedAt: const Value(null), updatedAt: Value(now)));
        await (db.update(db.entries)
              ..where((t) => t.groupId.equals(id) & (deletedState == null ? t.deletedAt.equals(deletedAt) : t.id.isIn(deletedState.expenseIds))))
            .write(EntriesCompanion(deletedAt: const Value(null), updatedAt: Value(now)));
        await _log(groupId: id, action: ActivityAction.restored, subject: ActivitySubject.group, subjectId: id, after: _groupSnapshotOf(group, deletedState?.expenseIds ?? const []));
      });

  static GroupSnapshot _groupSnapshotOf(Group group, List<String> expenseIds) => GroupSnapshot(name: group.name, icon: group.icon, expenseIds: expenseIds);

  /// Restores whatever a feed row's deletion removed.
  Future<void> restoreDeleted(ActivityRecord deletion) => switch (deletion.subject) {
        ActivitySubject.expense => restoreGroupExpense(deletion.subjectId),
        ActivitySubject.payment => restoreSettlement(deletion.subjectId),
        ActivitySubject.group => restoreGroup(deletion.subjectId),
      };

  /// Adds a member; one with an email also goes on the People list.
  Future<String> addMember(String groupId, String name, {String? phone, String? upiId, String? email}) async {
    final id = newId();
    await db.transaction(() async {
      await db.into(db.members).insert(MembersCompanion.insert(id: id, groupId: groupId, name: name.trim(), phone: Value(phone), upiId: Value(upiId), email: Value(email)));
      await rememberPerson(db, name: name, email: email);
    });
    return id;
  }

  /// Saves a member's edited details; one with an email also goes on the People list.
  Future<void> editMember(String id, {required String name, String? phone, String? upiId, String? email}) => db.transaction(() async {
        await updateMember(MembersCompanion(id: Value(id), name: Value(name.trim()), phone: Value(phone), upiId: Value(upiId), email: Value(email)));
        await rememberPerson(db, name: name, email: email);
      });

  Future<void> updateMember(MembersCompanion member) =>
      (db.update(db.members)..where((t) => t.id.equals(member.id.value))).write(member.copyWith(updatedAt: Value(DateTime.now())));

  Future<void> removeMember(String id) => updateMember(MembersCompanion(id: Value(id), deletedAt: Value(DateTime.now())));

  /// Records a payment and returns its id so the caller can offer Undo.
  Future<String> addSettlement({
    required String groupId,
    required String fromMemberId,
    required String toMemberId,
    required int amountMinor,
    DateTime? occurredAt,
    String note = '',
    String method = 'cash',
  }) async {
    final id = newId();
    await db.transaction(() async {
      await db.into(db.settlements).insert(SettlementsCompanion.insert(
            id: id,
            groupId: groupId,
            fromMemberId: fromMemberId,
            toMemberId: toMemberId,
            amountMinor: amountMinor,
            occurredAt: occurredAt ?? DateTime.now(),
            note: Value(note),
            method: Value(method),
          ));
      await _logSettlementChange(id, ActivityAction.added, before: null);
    });
    return id;
  }

  /// Edits a recorded payment in place; every field is rewritten so the row
  /// mirrors the sheet exactly.
  Future<void> updateSettlement({
    required String id,
    required String fromMemberId,
    required String toMemberId,
    required int amountMinor,
    required DateTime occurredAt,
    required String note,
    required String method,
  }) =>
      db.transaction(() async {
        final before = await _settlementById(id);
        await (db.update(db.settlements)..where((t) => t.id.equals(id))).write(SettlementsCompanion(
          fromMemberId: Value(fromMemberId),
          toMemberId: Value(toMemberId),
          amountMinor: Value(amountMinor),
          occurredAt: Value(occurredAt),
          note: Value(note),
          method: Value(method),
          updatedAt: Value(DateTime.now()),
        ));
        await _logSettlementChange(id, ActivityAction.edited, before: before);
      });

  Future<void> deleteSettlement(String id) => _setSettlementDeleted(id, DateTime.now());

  /// Brings back a deleted payment; does nothing if it is live or its group
  /// is deleted.
  Future<void> restoreSettlement(String id) async {
    final settlement = await _settlementById(id);
    if (settlement == null || settlement.deletedAt == null) return;
    final group = await (db.select(db.groups)..where((t) => t.id.equals(settlement.groupId) & t.deletedAt.isNull())).getSingleOrNull();
    if (group == null) return;
    await _setSettlementDeleted(id, null);
  }

  Future<void> _setSettlementDeleted(String id, DateTime? deletedAt) => db.transaction(() async {
        final before = await _settlementById(id);
        await (db.update(db.settlements)..where((t) => t.id.equals(id)))
            .write(SettlementsCompanion(deletedAt: Value(deletedAt), updatedAt: Value(DateTime.now())));
        await _logSettlementChange(id, deletedAt == null ? ActivityAction.restored : ActivityAction.deleted, before: before);
      });

  Future<Settlement?> _settlementById(String id) => (db.select(db.settlements)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Logs [action] on a payment, comparing [before] with the row as it is now.
  /// An edit that changed nothing visible is not logged.
  Future<void> _logSettlementChange(String id, ActivityAction action, {required Settlement? before}) async {
    final after = await _settlementById(id);
    final settlement = after ?? before;
    if (settlement == null) return;
    final beforeSnapshot = before == null || action == ActivityAction.restored ? null : paymentSnapshotOf(before);
    final afterSnapshot = after == null || action == ActivityAction.deleted ? null : paymentSnapshotOf(after);
    if (action == ActivityAction.edited && beforeSnapshot != null && afterSnapshot != null && !isMeaningfulEdit(beforeSnapshot, afterSnapshot)) return;
    await _log(groupId: settlement.groupId, action: action, subject: ActivitySubject.payment, subjectId: id, before: beforeSnapshot, after: afterSnapshot);
  }

  static PaymentSnapshot paymentSnapshotOf(Settlement settlement) => PaymentSnapshot(
        fromMemberId: settlement.fromMemberId,
        toMemberId: settlement.toMemberId,
        amountMinor: settlement.amountMinor,
        occurredAt: settlement.occurredAt,
        method: settlement.method,
        note: settlement.note,
      );

  /// Saves a group expense through [EntriesRepository.saveEntry] and logs it
  /// as added or edited in the same transaction. The arguments are those of
  /// [EntriesRepository.saveEntry].
  Future<void> saveGroupExpense(
    EntriesCompanion entry, {
    List<EntryItemsCompanion> items = const [],
    List<SplitsCompanion> splits = const [],
    List<EntryFieldValuesCompanion>? fieldValues,
    List<EntryPayersCompanion>? payers,
    Map<String, List<String>>? itemAssignments,
  }) {
    final entryId = entry.id.value;
    return db.transaction(() async {
      final before = await _expenseSnapshot(entryId, liveOnly: true);
      await _entries.saveEntry(entry, items: items, splits: splits, fieldValues: fieldValues, payers: payers, itemAssignments: itemAssignments);
      final after = await _expenseSnapshot(entryId, liveOnly: true);
      final groupId = entry.groupId.present ? entry.groupId.value : null;
      if (after == null || groupId == null) return;
      if (before != null && !isMeaningfulEdit(before, after)) return;
      await _log(
        groupId: groupId,
        action: before == null ? ActivityAction.added : ActivityAction.edited,
        subject: ActivitySubject.expense,
        subjectId: entryId,
        before: before,
        after: after,
      );
    });
  }

  /// Soft-deletes a group expense with its splits and payers and logs it, so
  /// it can be put back by [restoreGroupExpense].
  Future<void> deleteGroupExpense(String entryId) => db.transaction(() async {
        final entry = await _entryById(entryId);
        final before = await _expenseSnapshot(entryId, liveOnly: true);
        await _entries.deleteEntry(entryId);
        if (entry?.groupId == null || before == null) return;
        await _log(groupId: entry!.groupId!, action: ActivityAction.deleted, subject: ActivitySubject.expense, subjectId: entryId, before: before);
      });

  /// Brings back a deleted group expense with exactly the split, payer and
  /// item-assignment rows it had when it was deleted, and logs the restore. Does nothing if
  /// the expense is not deleted or its group is gone.
  Future<void> restoreGroupExpense(String entryId) => db.transaction(() async {
        final entry = await _entryById(entryId);
        final deletedAt = entry?.deletedAt;
        final groupId = entry?.groupId;
        if (entry == null || deletedAt == null || groupId == null) return;
        final group = await (db.select(db.groups)..where((t) => t.id.equals(groupId) & t.deletedAt.isNull())).getSingleOrNull();
        if (group == null) return;
        final deletedState = switch (await _lastDeletedSnapshot(entryId)) {
          final ExpenseSnapshot snapshot => snapshot,
          _ => null,
        };
        final splitIds = [for (final share in deletedState?.shares ?? const <MemberAmount>[]) ?share.rowId];
        final payerIds = [for (final payer in deletedState?.payers ?? const <MemberAmount>[]) ?payer.rowId];
        final now = DateTime.now();
        await (db.update(db.entries)..where((t) => t.id.equals(entryId))).write(EntriesCompanion(deletedAt: const Value(null), updatedAt: Value(now)));
        // Rows logged at deletion win; older logs without row ids fall back to
        // the rows tombstoned in the same delete.
        await (db.update(db.splits)
              ..where((t) => t.entryId.equals(entryId) & (splitIds.isEmpty ? t.deletedAt.equals(deletedAt) : t.id.isIn(splitIds))))
            .write(SplitsCompanion(deletedAt: const Value(null), updatedAt: Value(now)));
        await (db.update(db.entryPayers)
              ..where((t) => t.entryId.equals(entryId) & (deletedState == null ? t.deletedAt.equals(deletedAt) : t.id.isIn(payerIds))))
            .write(EntryPayersCompanion(deletedAt: const Value(null), updatedAt: Value(now)));
        await _entries.restoreAssignments(entryId, ids: deletedState?.assignmentIds, deletedAt: deletedAt);
        await _log(groupId: groupId, action: ActivityAction.restored, subject: ActivitySubject.expense, subjectId: entryId, after: await _expenseSnapshot(entryId, liveOnly: true));
      });

  Future<Entry?> _entryById(String id) => (db.select(db.entries)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// The state a deleted expense had when it was last deleted, from the log.
  /// The state logged by the latest deletion of [subjectId], if readable.
  Future<ActivitySnapshot?> _lastDeletedSnapshot(String subjectId) async {
    final row = await (db.select(db.groupActivities)
          ..where((t) => t.subjectId.equals(subjectId) & t.action.equals(ActivityAction.deleted.name) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt), (t) => OrderingTerm.desc(t.rowId)])
          ..limit(1))
        .getSingleOrNull();
    return ActivitySnapshot.decode(row?.beforeJson);
  }

  /// A group expense as the log stores it; null when it does not exist (or,
  /// with [liveOnly], is deleted).
  Future<ExpenseSnapshot?> _expenseSnapshot(String entryId, {required bool liveOnly}) async {
    final entry = await _entryById(entryId);
    if (entry == null || (liveOnly && entry.deletedAt != null)) return null;
    final splits = await (db.select(db.splits)..where((t) => t.entryId.equals(entryId) & t.deletedAt.isNull())).get();
    final payers = await (db.select(db.entryPayers)..where((t) => t.entryId.equals(entryId) & t.deletedAt.isNull())).get();
    final assignments = await _entries.getItemAssignmentRows(entryId);
    return expenseSnapshotOf(entry, splits, payers, assignments: assignments);
  }

  static ExpenseSnapshot expenseSnapshotOf(Entry entry, List<Split> splits, List<EntryPayer> payers, {List<ItemAssignment> assignments = const []}) => ExpenseSnapshot(
        amountMinor: entry.amountMinor,
        occurredAt: entry.occurredAt,
        note: entry.note,
        payee: entry.payee,
        categoryId: entry.categoryId,
        payers: payers.isNotEmpty
            ? [for (final payer in payers) MemberAmount(memberId: payer.memberId, amountMinor: payer.amountMinor, rowId: payer.id)]
            : [if (entry.paidByMemberId case final payerId?) MemberAmount(memberId: payerId, amountMinor: entry.amountMinor)],
        shares: [for (final split in splits) MemberAmount(memberId: split.memberId, amountMinor: split.amountMinor, rowId: split.id)],
        splitMethod: entry.splitMethod,
        assignmentIds: [for (final assignment in assignments) assignment.id],
      );

  /// Writes one activity row, attributed to my member in the group.
  Future<void> _log({
    required String groupId,
    required ActivityAction action,
    required ActivitySubject subject,
    required String subjectId,
    ActivitySnapshot? before,
    ActivitySnapshot? after,
  }) async {
    final me = await (db.select(db.members)
          ..where((t) => t.groupId.equals(groupId) & t.isMe.equals(true))
          ..limit(1))
        .getSingleOrNull();
    await db.into(db.groupActivities).insert(GroupActivitiesCompanion.insert(
          id: newId(),
          groupId: groupId,
          action: action.name,
          subjectKind: subject.name,
          subjectId: subjectId,
          actorMemberId: Value(me?.id),
          occurredAt: DateTime.now(),
          beforeJson: Value(before?.encode()),
          afterJson: Value(after?.encode()),
        ));
  }

  /// The activity log, newest first: one group's, or every live group's when
  /// [groupId] is null.
  Stream<ActivityFeed> watchActivityFeed({String? groupId, int limit = 300}) =>
      db.watchTables([db.groupActivities, db.groups, db.members, db.entries, db.settlements], () => getActivityFeed(groupId: groupId, limit: limit));

  /// Live groups show all their activity; a deleted group shows only its own
  /// deletion and restore rows, so it can be restored from the feed.
  Future<ActivityFeed> getActivityFeed({String? groupId, int limit = 300}) async {
    final groups = await (db.select(db.groups)..where((t) => groupId == null ? const Constant(true) : t.id.equals(groupId))).get();
    if (groups.isEmpty) return const ActivityFeed(activities: [], membersById: {}, groupsById: {}, restorableIds: {});
    final liveGroupIds = [for (final group in groups) if (group.deletedAt == null) group.id];
    final deletedGroupIds = {for (final group in groups) if (group.deletedAt != null) group.id};
    final rows = await (db.select(db.groupActivities)
          ..where((t) =>
              (t.groupId.isIn(liveGroupIds) | (t.groupId.isIn(deletedGroupIds) & t.subjectKind.equals(ActivitySubject.group.name))) & t.deletedAt.isNull())
          // Times are stored to the second; insertion order breaks ties so an
          // Undo right after a delete still lists after it.
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt), (t) => OrderingTerm.desc(t.rowId)])
          ..limit(limit))
        .get();
    final members = await (db.select(db.members)..where((t) => t.groupId.isIn([for (final group in groups) group.id]))).get();
    final activities = [for (final row in rows) activityRecordOf(row)];
    Set<String> mentioned(ActivitySubject subject) => {for (final activity in activities) if (activity.subject == subject) activity.subjectId};
    final expenseIds = mentioned(ActivitySubject.expense);
    final paymentIds = mentioned(ActivitySubject.payment);
    final deletedExpenseIds = expenseIds.isEmpty
        ? const <String>{}
        : {for (final entry in await (db.select(db.entries)..where((t) => t.id.isIn(expenseIds) & t.deletedAt.isNotNull())).get()) entry.id};
    final deletedPaymentIds = paymentIds.isEmpty
        ? const <String>{}
        : {for (final payment in await (db.select(db.settlements)..where((t) => t.id.isIn(paymentIds) & t.deletedAt.isNotNull())).get()) payment.id};
    return ActivityFeed(
      activities: activities,
      membersById: {for (final member in members) member.id: member},
      groupsById: {for (final group in groups) group.id: group},
      restorableIds: restorableActivityIds(activities, deletedIds: {
        ActivitySubject.expense: deletedExpenseIds,
        ActivitySubject.payment: deletedPaymentIds,
        ActivitySubject.group: deletedGroupIds,
      }),
      deletedExpenseIds: deletedExpenseIds,
    );
  }

  static ActivityRecord activityRecordOf(GroupActivity row) => ActivityRecord(
        id: row.id,
        groupId: row.groupId,
        action: activityActionFrom(row.action),
        subject: activitySubjectFrom(row.subjectKind),
        subjectId: row.subjectId,
        actorMemberId: row.actorMemberId,
        occurredAt: row.occurredAt,
        before: ActivitySnapshot.decode(row.beforeJson),
        after: ActivitySnapshot.decode(row.afterJson),
      );

  /// Keeps every group's "me" member in sync with the name chosen in Settings.
  Future<void> renameMyMembers(String name) => (db.update(db.members)..where((t) => t.isMe.equals(true) & t.deletedAt.isNull()))
      .write(MembersCompanion(name: Value(name.trim()), updatedAt: Value(DateTime.now())));

  static String _inviteCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(6, (_) => alphabet[random.nextInt(alphabet.length)]).join();
  }
}

/// The timeline form of a recorded settle-up payment.
TimelinePayment timelinePaymentOf(Settlement settlement) =>
    TimelinePayment(occurredAt: settlement.occurredAt, fromMemberId: settlement.fromMemberId, toMemberId: settlement.toMemberId, amountMinor: settlement.amountMinor);

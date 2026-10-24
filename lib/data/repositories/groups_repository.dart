import 'dart:math';

import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../domain/split/debt_simplifier.dart';
import '../../domain/split/group_timeline.dart';
import '../../domain/split/split_calculator.dart';
import '../db/database.dart';
import '../db/watch_tables.dart';

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
}

/// A group expense with its splits and, when several members paid, its payer
/// rows (empty for a single payer).
typedef GroupEntry = (Entry, List<Split>, List<EntryPayer>);

class GroupsRepository {
  GroupsRepository(this.db);
  final AppDatabase db;

  Stream<List<Group>> watchGroups() => (db.select(db.groups)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

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
        payments: [
          for (final settlement in settlements)
            TimelinePayment(occurredAt: settlement.occurredAt, fromMemberId: settlement.fromMemberId, toMemberId: settlement.toMemberId, amountMinor: settlement.amountMinor),
        ],
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

  Future<void> deleteGroup(String id) => db.transaction(() async {
        final now = DateTime.now();
        await (db.update(db.groups)..where((t) => t.id.equals(id))).write(GroupsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
        await (db.update(db.entries)..where((t) => t.groupId.equals(id))).write(EntriesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      });

  Future<String> addMember(String groupId, String name, {String? phone, String? upiId}) async {
    final id = newId();
    await db.into(db.members).insert(MembersCompanion.insert(id: id, groupId: groupId, name: name.trim(), phone: Value(phone), upiId: Value(upiId)));
    return id;
  }

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
      (db.update(db.settlements)..where((t) => t.id.equals(id))).write(SettlementsCompanion(
        fromMemberId: Value(fromMemberId),
        toMemberId: Value(toMemberId),
        amountMinor: Value(amountMinor),
        occurredAt: Value(occurredAt),
        note: Value(note),
        method: Value(method),
        updatedAt: Value(DateTime.now()),
      ));

  Future<void> deleteSettlement(String id) => _setSettlementDeleted(id, DateTime.now());

  Future<void> restoreSettlement(String id) => _setSettlementDeleted(id, null);

  Future<void> _setSettlementDeleted(String id, DateTime? deletedAt) => (db.update(db.settlements)..where((t) => t.id.equals(id)))
      .write(SettlementsCompanion(deletedAt: Value(deletedAt), updatedAt: Value(DateTime.now())));

  /// Keeps every group's "me" member in sync with the name chosen in Settings.
  Future<void> renameMyMembers(String name) => (db.update(db.members)..where((t) => t.isMe.equals(true) & t.deletedAt.isNull()))
      .write(MembersCompanion(name: Value(name.trim()), updatedAt: Value(DateTime.now())));

  static String _inviteCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(6, (_) => alphabet[random.nextInt(alphabet.length)]).join();
  }
}

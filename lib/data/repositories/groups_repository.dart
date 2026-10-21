import 'dart:math';

import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../domain/split/debt_simplifier.dart';
import '../../domain/split/split_calculator.dart';
import '../db/database.dart';

class GroupSummary {
  const GroupSummary({required this.group, required this.members, required this.myNetMinor, required this.totalSpentMinor});
  final Group group;
  final List<Member> members;

  /// Positive: others owe me. Negative: I owe.
  final int myNetMinor;
  final int totalSpentMinor;
}

class GroupBalances {
  const GroupBalances({required this.net, required this.suggested});
  final Map<String, int> net;
  final List<Transfer> suggested;
}

class GroupsRepository {
  GroupsRepository(this.db);
  final AppDatabase db;

  Stream<List<Group>> watchGroups() => (db.select(db.groups)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  Stream<Group?> watchGroup(String id) =>
      (db.select(db.groups)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Stream<List<Member>> watchMembers(String groupId) => (db.select(db.members)
        ..where((t) => t.groupId.equals(groupId) & t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.isMe), (t) => OrderingTerm.asc(t.name)]))
      .watch();

  Stream<List<Settlement>> watchSettlements(String groupId) => (db.select(db.settlements)
        ..where((t) => t.groupId.equals(groupId) & t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
      .watch();

  /// Group entries with their splits; emits whenever either changes.
  Stream<List<(Entry, List<Split>)>> watchGroupEntries(String groupId) {
    final entriesQuery = db.select(db.entries)
      ..where((t) => t.groupId.equals(groupId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]);
    return entriesQuery.watch().asyncMap((entries) async {
      final ids = entries.map((e) => e.id).toList();
      final splits = ids.isEmpty
          ? <Split>[]
          : await (db.select(db.splits)..where((t) => t.entryId.isIn(ids) & t.deletedAt.isNull())).get();
      return [for (final e in entries) (e, splits.where((s) => s.entryId == e.id).toList())];
    });
  }

  Stream<GroupBalances> watchBalances(String groupId) {
    return watchMembers(groupId).asyncExpand((members) {
      return watchGroupEntries(groupId).asyncExpand((entries) {
        return watchSettlements(groupId).asyncMap((settlements) async {
          final group = await (db.select(db.groups)..where((t) => t.id.equals(groupId))).getSingleOrNull();
          return computeBalances(
            members: members,
            entries: entries,
            settlements: settlements,
            simplify: group?.simplifyDebts ?? true,
          );
        });
      });
    });
  }

  static GroupBalances computeBalances({
    required List<Member> members,
    required List<(Entry, List<Split>)> entries,
    required List<Settlement> settlements,
    required bool simplify,
  }) {
    final ledger = [
      for (final (entry, splits) in entries)
        if (entry.paidByMemberId != null)
          LedgerExpense(
            paidByMemberId: entry.paidByMemberId!,
            shares: [for (final s in splits) SplitShare(s.memberId, s.amountMinor)],
          ),
    ];
    final paid = [
      for (final s in settlements)
        LedgerSettlement(fromMemberId: s.fromMemberId, toMemberId: s.toMemberId, amountMinor: s.amountMinor),
    ];
    final net = computeNetBalances(memberIds: members.map((m) => m.id), expenses: ledger, settlements: paid);
    final suggested = simplify ? simplifyDebts(net) : pairwiseDebts(expenses: ledger, settlements: paid);
    return GroupBalances(net: net, suggested: suggested);
  }

  Stream<List<GroupSummary>> watchSummaries() {
    return watchGroups().asyncExpand((groups) async* {
      final summaries = <GroupSummary>[];
      for (final group in groups) {
        final members = await watchMembers(group.id).first;
        final entries = await watchGroupEntries(group.id).first;
        final settlements = await watchSettlements(group.id).first;
        final balances = computeBalances(members: members, entries: entries, settlements: settlements, simplify: group.simplifyDebts);
        final me = members.where((m) => m.isMe).firstOrNull;
        summaries.add(GroupSummary(
          group: group,
          members: members,
          myNetMinor: me == null ? 0 : balances.net[me.id] ?? 0,
          totalSpentMinor: entries.fold(0, (sum, e) => sum + e.$1.amountMinor),
        ));
      }
      yield summaries;
    });
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

  Future<String> addMember(String groupId, String name, {String? phone}) async {
    final id = newId();
    await db.into(db.members).insert(MembersCompanion.insert(id: id, groupId: groupId, name: name.trim(), phone: Value(phone)));
    return id;
  }

  Future<void> updateMember(MembersCompanion member) =>
      (db.update(db.members)..where((t) => t.id.equals(member.id.value))).write(member.copyWith(updatedAt: Value(DateTime.now())));

  Future<void> removeMember(String id) => updateMember(MembersCompanion(id: Value(id), deletedAt: Value(DateTime.now())));

  Future<void> addSettlement({
    required String groupId,
    required String fromMemberId,
    required String toMemberId,
    required int amountMinor,
    DateTime? occurredAt,
    String note = '',
  }) =>
      db.into(db.settlements).insert(SettlementsCompanion.insert(
            id: newId(),
            groupId: groupId,
            fromMemberId: fromMemberId,
            toMemberId: toMemberId,
            amountMinor: amountMinor,
            occurredAt: occurredAt ?? DateTime.now(),
            note: Value(note),
          ));

  Future<void> deleteSettlement(String id) => (db.update(db.settlements)..where((t) => t.id.equals(id)))
      .write(SettlementsCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())));

  static String _inviteCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(6, (_) => alphabet[random.nextInt(alphabet.length)]).join();
  }
}

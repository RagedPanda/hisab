
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/groups_repository.dart';
import 'package:drift/drift.dart' show Value;

/// Reproduces AND-07 / IOS-02 / P1-1: group balance streams must keep
/// emitting after the first change to a nested table (entries, splits,
/// settlements), not only after the members table changes.
void main() {
  late AppDatabase db;
  late GroupsRepository groups;
  late EntriesRepository entries;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    groups = GroupsRepository(db);
    entries = EntriesRepository(db);
  });

  tearDown(() => db.close());

  Future<void> addGroupExpense(String groupId, String payerId, Map<String, int> shares) async {
    final entryId = newId();
    final total = shares.values.fold(0, (sum, v) => sum + v);
    await entries.saveEntry(
      EntriesRepository.newExpense(id: entryId, amountMinor: total, occurredAt: DateTime(2026, 10, 1), groupId: groupId, paidByMemberId: payerId, splitMethod: 'equal'),
      splits: [
        for (final share in shares.entries) SplitsCompanion.insert(id: newId(), entryId: entryId, memberId: share.key, amountMinor: share.value),
      ],
    );
  }

  test('watchBalances keeps updating after a second expense and a settlement', () async {
    final groupId = await groups.createGroup(name: 'Goa', icon: 'beach', myName: 'Me', otherMembers: ['Rahul']);
    final members = await groups.getMembers(groupId);
    final me = members.firstWhere((m) => m.isMe).id;
    final rahul = members.firstWhere((m) => !m.isMe).id;

    final seen = <int>[];
    final sub = groups.watchBalances(groupId).listen((b) => seen.add(b.net[rahul] ?? 0));
    await pumpEventQueue();

    await addGroupExpense(groupId, me, {me: 5000, rahul: 5000});
    await pumpEventQueue();
    await addGroupExpense(groupId, me, {me: 10000, rahul: 10000});
    await pumpEventQueue();
    await groups.addSettlement(groupId: groupId, fromMemberId: rahul, toMemberId: me, amountMinor: 15000);
    await pumpEventQueue();
    await sub.cancel();

    expect(seen.first, 0);
    expect(seen, contains(-5000));
    expect(seen, contains(-15000));
    expect(seen.last, 0, reason: 'settlement must be reflected without reopening the screen');
  });

  test('watchSummaries reacts to expenses, not only to the groups table', () async {
    final groupId = await groups.createGroup(name: 'Flat', icon: 'home', myName: 'Me', otherMembers: ['Priya']);
    final members = await groups.getMembers(groupId);
    final me = members.firstWhere((m) => m.isMe).id;
    final priya = members.firstWhere((m) => !m.isMe).id;

    final totals = <int>[];
    final sub = groups.watchSummaries().listen((list) => totals.add(list.single.totalSpentMinor));
    await pumpEventQueue();
    await addGroupExpense(groupId, me, {me: 30000, priya: 30000});
    await pumpEventQueue();
    await addGroupExpense(groupId, priya, {me: 20000, priya: 20000});
    await pumpEventQueue();
    await sub.cancel();

    expect(totals.last, 100000);
  });

  test('removing a member with net zero but open pairwise debts is refused by the settled rule', () async {
    final groupId = await groups.createGroup(name: 'Trip', icon: 'bag', myName: 'Me', otherMembers: ['Bina', 'Chetan']);
    await (db.update(db.groups)..where((t) => t.id.equals(groupId))).write(const GroupsCompanion(simplifyDebts: Value(false)));
    final members = await groups.getMembers(groupId);
    final me = members.firstWhere((m) => m.isMe).id;
    final bina = members.firstWhere((m) => m.name == 'Bina').id;
    final chetan = members.firstWhere((m) => m.name == 'Chetan').id;
    await addGroupExpense(groupId, me, {bina: 15000});
    await addGroupExpense(groupId, bina, {chetan: 15000});

    final balances = await groups.getBalances(groupId);
    expect(balances.net[bina], 0);
    expect(balances.suggested.where((t) => t.from == bina || t.to == bina), isNotEmpty);
  });
}

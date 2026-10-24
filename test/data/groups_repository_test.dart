
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/data/backup/backup_service.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/groups_repository.dart';
import 'package:hisab/domain/split/debt_simplifier.dart';
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

  test('with simplify on, a chain member nets to zero and leaves the simplified list but stays unsettled pairwise', () async {
    final groupId = await groups.createGroup(name: 'Trip', icon: 'bag', myName: 'Me', otherMembers: ['Bina', 'Chetan']);
    final members = await groups.getMembers(groupId);
    final me = members.firstWhere((m) => m.isMe).id;
    final bina = members.firstWhere((m) => m.name == 'Bina').id;
    final chetan = members.firstWhere((m) => m.name == 'Chetan').id;
    await addGroupExpense(groupId, me, {bina: 15000});
    await addGroupExpense(groupId, bina, {chetan: 15000});

    final balances = await groups.getBalances(groupId);
    expect(balances.net[bina], 0);
    expect(balances.suggested.where((t) => t.from == bina || t.to == bina), isEmpty, reason: 'simplified: Chetan pays Me directly');
    expect(balances.pairwise.where((t) => t.from == bina || t.to == bina), hasLength(2));
    expect(isMemberSettled(memberId: bina, net: balances.net, transfers: balances.suggested), isTrue, reason: 'the old guard let Bina go');
    expect(isMemberSettled(memberId: bina, net: balances.net, transfers: balances.pairwise), isFalse, reason: 'the pairwise guard keeps her');
    expect(balances.repaymentsSaved, 1);
  });

  test('group detail keeps removed members for name resolution but not in the member list', () async {
    final groupId = await groups.createGroup(name: 'Trip', icon: 'bag', myName: 'Me', otherMembers: ['Bina']);
    final members = await groups.getMembers(groupId);
    final me = members.firstWhere((m) => m.isMe).id;
    final bina = members.firstWhere((m) => m.name == 'Bina').id;
    await addGroupExpense(groupId, bina, {me: 5000, bina: 5000});
    await groups.addSettlement(groupId: groupId, fromMemberId: me, toMemberId: bina, amountMinor: 5000);
    await groups.removeMember(bina);

    final detail = (await groups.getGroupDetail(groupId))!;
    expect(detail.members.map((m) => m.id), [me]);
    expect(detail.allMembers.map((m) => m.name), containsAll(['Me', 'Bina']));
    expect(detail.entries.single.$1.paidByMemberId, bina);
    expect(detail.settlements.single.toMemberId, bina);
    expect(detail.balances.pairwise, isEmpty);
  });

  test('group detail is null once the group is deleted', () async {
    final groupId = await groups.createGroup(name: 'Gone', icon: 'bag', myName: 'Me', otherMembers: ['Bina']);
    expect(await groups.getGroupDetail(groupId), isNotNull);
    await groups.deleteGroup(groupId);
    expect(await groups.getGroupDetail(groupId), isNull);
  });

  test('a payment stores its method and can be edited in place', () async {
    final groupId = await groups.createGroup(name: 'Flat', icon: 'home', myName: 'Me', otherMembers: ['Bina']);
    final members = await groups.getMembers(groupId);
    final me = members.firstWhere((m) => m.isMe).id;
    final bina = members.firstWhere((m) => m.name == 'Bina').id;
    final id = await groups.addSettlement(groupId: groupId, fromMemberId: bina, toMemberId: me, amountMinor: 1000, method: 'upi', note: 'rent');
    var saved = (await groups.getSettlements(groupId)).single;
    expect(saved.method, 'upi');
    expect(saved.note, 'rent');

    await groups.updateSettlement(id: id, fromMemberId: me, toMemberId: bina, amountMinor: 2500, occurredAt: DateTime(2026, 10, 2), note: '', method: 'bank');
    saved = (await groups.getSettlements(groupId)).single;
    expect(saved.fromMemberId, me);
    expect(saved.toMemberId, bina);
    expect(saved.amountMinor, 2500);
    expect(saved.occurredAt, DateTime(2026, 10, 2));
    expect(saved.method, 'bank');
    final balances = await groups.getBalances(groupId);
    expect(balances.net[bina], -2500, reason: 'paying Bina without any expense means she now owes it back');
    expect(balances.net[me], 2500);
  });

  test('group detail carries each expense as payer and shares and the last settled day', () async {
    final groupId = await groups.createGroup(name: 'Goa', icon: 'beach', myName: 'Me', otherMembers: ['Rahul']);
    final members = await groups.getMembers(groupId);
    final me = members.firstWhere((m) => m.isMe).id;
    final rahul = members.firstWhere((m) => !m.isMe).id;
    await addGroupExpense(groupId, me, {me: 500, rahul: 500});

    var detail = (await groups.getGroupDetail(groupId))!;
    expect(detail.settledUpTo, isNull);
    final timeline = detail.timelineByEntryId.values.single;
    expect(timeline.paidMinor, {me: 1000});
    expect(timeline.shareMinor, {me: 500, rahul: 500});

    await groups.addSettlement(groupId: groupId, fromMemberId: rahul, toMemberId: me, amountMinor: 500, occurredAt: DateTime(2026, 10, 4, 18));
    detail = (await groups.getGroupDetail(groupId))!;
    expect(detail.settledUpTo, DateTime(2026, 10, 4));
  });

  test('renaming yourself in Settings renames the me member of every group', () async {
    final goa = await groups.createGroup(name: 'Goa', icon: 'beach', myName: 'You', otherMembers: ['Rahul']);
    final flat = await groups.createGroup(name: 'Flat', icon: 'home', myName: 'You', otherMembers: ['Priya']);
    await groups.renameMyMembers('Ankur');
    for (final groupId in [goa, flat]) {
      final members = await groups.getMembers(groupId);
      expect(members.firstWhere((m) => m.isMe).name, 'Ankur');
      expect(members.where((m) => !m.isMe).map((m) => m.name), isNot(contains('Ankur')));
    }
  });

  test('a removed payment can be restored by Undo', () async {
    final groupId = await groups.createGroup(name: 'Goa', icon: 'beach', myName: 'You', otherMembers: ['Rahul']);
    final members = await groups.getMembers(groupId);
    final me = members.firstWhere((m) => m.isMe).id;
    final rahul = members.firstWhere((m) => !m.isMe).id;
    final id = await groups.addSettlement(groupId: groupId, fromMemberId: rahul, toMemberId: me, amountMinor: 5000);
    expect((await groups.getSettlements(groupId)).map((s) => s.id), [id]);
    await groups.deleteSettlement(id);
    expect(await groups.getSettlements(groupId), isEmpty);
    await groups.restoreSettlement(id);
    expect((await groups.getSettlements(groupId)).map((s) => s.id), [id]);
  });

  test('group detail carries the latest settle-up reminder per member and refreshes on a new one', () async {
    final groupId = await groups.createGroup(name: 'Goa', icon: 'flight', myName: 'Me', otherMembers: ['Rahul', 'Priya']);
    final members = await groups.getMembers(groupId);
    final rahul = members.firstWhere((m) => m.name == 'Rahul').id;
    final priya = members.firstWhere((m) => m.name == 'Priya').id;
    await groups.recordSettleUpReminder(groupId: groupId, memberId: rahul, channel: 'share', message: 'old', sentAt: DateTime(2026, 10, 1));
    await groups.recordSettleUpReminder(groupId: groupId, memberId: rahul, channel: 'copy', message: 'new', sentAt: DateTime(2026, 10, 9));
    final otherGroup = await groups.createGroup(name: 'Flat', icon: 'home', myName: 'Me', otherMembers: ['Priya']);
    await groups.recordSettleUpReminder(groupId: otherGroup, memberId: priya, channel: 'share', message: 'elsewhere', sentAt: DateTime(2026, 10, 5));

    expect((await groups.getGroupDetail(groupId))!.lastRemindedAt, {rahul: DateTime(2026, 10, 9)});

    final updates = groups.watchGroupDetail(groupId).map((detail) => detail!.lastRemindedAt.length);
    final seen = <int>[];
    final subscription = updates.listen(seen.add);
    await pumpEventQueue();
    await groups.recordSettleUpReminder(groupId: groupId, memberId: priya, channel: 'whatsapp', message: 'hi');
    await pumpEventQueue();
    await subscription.cancel();
    expect(seen, [1, 2]);
  });

  test('a member can be added with a phone and UPI ID', () async {
    final groupId = await groups.createGroup(name: 'Goa', icon: 'flight', myName: 'Me');
    await groups.addMember(groupId, ' Rahul ', phone: '98100 12345', upiId: 'rahul@ybl');
    final rahul = (await groups.getMembers(groupId)).firstWhere((m) => m.name == 'Rahul');
    expect((rahul.phone, rahul.upiId), ('98100 12345', 'rahul@ybl'));
  });

  test('backup carries member UPI IDs and settle-up reminders', () async {
    final groupId = await groups.createGroup(name: 'Goa', icon: 'flight', myName: 'Me');
    final rahul = await groups.addMember(groupId, 'Rahul', upiId: 'rahul@ybl');
    await groups.recordSettleUpReminder(groupId: groupId, memberId: rahul, channel: 'copy', message: 'pay up', sentAt: DateTime(2026, 10, 9));

    final restored = AppDatabase(NativeDatabase.memory());
    addTearDown(restored.close);
    await BackupService(restored).importSnapshot(await BackupService(db).snapshot());
    final restoredGroups = GroupsRepository(restored);
    expect((await restoredGroups.getMembers(groupId)).firstWhere((member) => member.id == rahul).upiId, 'rahul@ybl');
    expect((await restoredGroups.getGroupDetail(groupId))!.lastRemindedAt, {rahul: DateTime(2026, 10, 9)});
  });

  group('several payers', () {
    late String groupId;
    late String me;
    late String rahul;
    late String priya;
    const entryId = 'dinner';

    Future<void> saveDinner({required Map<String, int> paid}) => entries.saveEntry(
          EntriesRepository.newExpense(id: entryId, amountMinor: 90000, occurredAt: DateTime(2026, 10, 2), groupId: groupId, paidByMemberId: paid.keys.first, splitMethod: 'equal'),
          splits: [
            for (final member in [me, rahul, priya]) SplitsCompanion.insert(id: '$entryId-$member', entryId: entryId, memberId: member, amountMinor: 30000),
          ],
          payers: paid.length < 2
              ? const []
              : [for (final payer in paid.entries) EntryPayersCompanion.insert(id: '$entryId-paid-${payer.key}', entryId: entryId, memberId: payer.key, amountMinor: payer.value)],
        );

    setUp(() async {
      groupId = await groups.createGroup(name: 'Goa', icon: 'beach', myName: 'Me', otherMembers: ['Priya', 'Rahul']);
      final members = await groups.getMembers(groupId);
      me = members.firstWhere((m) => m.isMe).id;
      rahul = members.firstWhere((m) => m.name == 'Rahul').id;
      priya = members.firstWhere((m) => m.name == 'Priya').id;
    });

    test('balances credit every payer with what they paid', () async {
      await saveDinner(paid: {rahul: 60000, me: 30000});
      final detail = (await groups.getGroupDetail(groupId))!;
      expect(detail.balances.net, {me: 0, rahul: 30000, priya: -30000});
      expect(detail.timelineByEntryId[entryId]!.paidMinor, {rahul: 60000, me: 30000});
      expect(detail.entries.single.$3, hasLength(2));
    });

    test('switching back to one payer drops the old payer rows', () async {
      await saveDinner(paid: {rahul: 60000, me: 30000});
      await saveDinner(paid: {me: 90000});
      expect(await entries.getPayers(entryId), isEmpty);
      expect((await groups.getGroupDetail(groupId))!.balances.net, {me: 60000, rahul: -30000, priya: -30000});
    });

    test('deleting the expense removes its payers', () async {
      await saveDinner(paid: {rahul: 60000, me: 30000});
      await entries.deleteEntry(entryId);
      expect(await entries.getPayers(entryId), isEmpty);
      expect((await groups.getGroupDetail(groupId))!.balances.net.values.every((amount) => amount == 0), isTrue);
    });

    test('backup round-trips the payer rows', () async {
      await saveDinner(paid: {rahul: 60000, me: 30000});
      final restored = AppDatabase(NativeDatabase.memory());
      addTearDown(restored.close);
      await BackupService(restored).importSnapshot(await BackupService(db).snapshot());
      expect((await GroupsRepository(restored).getGroupDetail(groupId))!.balances.net, {me: 0, rahul: 30000, priya: -30000});
    });
  });

  group('item assignments', () {
    const entryId = 'pizza-night';

    Future<void> savePizza(Map<String, List<String>>? assignments, {List<String> itemIds = const ['pizza', 'coke']}) => entries.saveEntry(
          EntriesRepository.newExpense(id: entryId, amountMinor: 80000, occurredAt: DateTime(2026, 10, 3), groupId: 'g1', paidByMemberId: 'me', splitMethod: 'byItem'),
          items: [
            for (final itemId in itemIds) EntryItemsCompanion.insert(id: itemId, entryId: entryId, name: itemId, unitPriceMinor: 40000, amountMinor: 40000),
          ],
          itemAssignments: assignments,
        );

    test('save and load who shares each item', () async {
      await savePizza({'pizza': ['me', 'rahul'], 'coke': ['rahul']});
      expect(await entries.getItemAssignments(entryId), {'pizza': ['me', 'rahul'], 'coke': ['rahul']});
    });

    test('saving again replaces assignments and revives a re-added member', () async {
      await savePizza({'pizza': ['me', 'rahul'], 'coke': ['rahul']});
      await savePizza({'pizza': ['me'], 'coke': ['rahul']});
      expect(await entries.getItemAssignments(entryId), {'pizza': ['me'], 'coke': ['rahul']});
      await savePizza({'pizza': ['me', 'rahul'], 'coke': ['rahul']});
      expect((await entries.getItemAssignments(entryId))['pizza'], unorderedEquals(['me', 'rahul']));
      expect(await db.select(db.itemAssignments).get(), hasLength(3), reason: 'one row per item and member, reused');
    });

    test('null keeps assignments, an empty map clears them, a dropped item hides its row', () async {
      await savePizza({'pizza': ['me'], 'coke': ['rahul']});
      await savePizza(null);
      expect(await entries.getItemAssignments(entryId), hasLength(2));
      await savePizza(null, itemIds: ['pizza']);
      expect(await entries.getItemAssignments(entryId), {'pizza': ['me']});
      await savePizza(const {});
      expect(await entries.getItemAssignments(entryId), isEmpty);
    });

    test('deleting the entry tombstones its assignments', () async {
      await savePizza({'pizza': ['me']});
      await entries.deleteEntry(entryId);
      final rows = await db.select(db.itemAssignments).get();
      expect(rows.single.deletedAt, isNotNull);
    });
  });

  group('group settings', () {
    test('a new group is an active other-type group with an equal default split', () async {
      final groupId = await groups.createGroup(name: 'Flat', icon: 'groups', myName: 'Me');
      final group = (await groups.getGroup(groupId))!;
      expect((group.type, group.defaultSplitMethod, group.notes, group.currencyLabel, group.archivedAt), ('other', 'equal', '', null, null));
    });

    test('archive and unarchive keep the group and its expenses', () async {
      final groupId = await groups.createGroup(name: 'Goa', icon: 'flight', myName: 'Me', otherMembers: ['Rahul']);
      final members = await groups.getMembers(groupId);
      await addGroupExpense(groupId, members.first.id, {members.first.id: 500, members.last.id: 500});

      await groups.archiveGroup(groupId);
      final summaries = await groups.getSummaries();
      expect(summaries.single.group.archivedAt, isNotNull, reason: 'archived groups stay listed, under Archived');
      expect((await groups.getGroupDetail(groupId))!.entries, hasLength(1));

      await groups.unarchiveGroup(groupId);
      expect((await groups.getGroup(groupId))!.archivedAt, isNull);
    });

    test('leaving is refused while I owe or am owed, and archives the group once settled', () async {
      final groupId = await groups.createGroup(name: 'Goa', icon: 'flight', myName: 'Me', otherMembers: ['Rahul']);
      final members = await groups.getMembers(groupId);
      final me = members.firstWhere((member) => member.isMe);
      final rahul = members.firstWhere((member) => !member.isMe);
      await addGroupExpense(groupId, me.id, {me.id: 500, rahul.id: 500});

      expect((await groups.getGroupDetail(groupId))!.canLeave, isFalse);
      expect(await groups.leaveGroup(groupId), isFalse);
      expect((await groups.getGroup(groupId))!.archivedAt, isNull, reason: 'a refused leave changes nothing');

      await groups.addSettlement(groupId: groupId, fromMemberId: rahul.id, toMemberId: me.id, amountMinor: 500);
      expect(await groups.leaveGroup(groupId), isTrue);
      final detail = (await groups.getGroupDetail(groupId))!;
      expect(detail.me, isNull);
      expect(detail.group.archivedAt, isNotNull);
      expect(detail.allMembers.map((member) => member.name), contains('Me'), reason: 'history still names me');
    });

    test('member weights and the currency label are saved', () async {
      final groupId = await groups.createGroup(name: 'Euro trip', icon: 'flight', myName: 'Me', otherMembers: ['Rahul']);
      final rahul = (await groups.getMembers(groupId)).firstWhere((member) => !member.isMe);
      await groups.setMemberWeight(rahul.id, 2);
      expect((await groups.getMembers(groupId)).firstWhere((member) => member.id == rahul.id).weight, 2);

      await groups.setCurrencyLabel((await groups.getGroup(groupId))!, '€');
      var group = (await groups.getGroup(groupId))!;
      expect((group.currencyLabel, group.currency), ('€', 'EUR'));
      await groups.setCurrencyLabel(group, null);
      group = (await groups.getGroup(groupId))!;
      expect((group.currencyLabel, group.currency), (null, 'EUR'));
    });

    test('app totals skip groups labelled in another currency', () async {
      final home = await groups.createGroup(name: 'Flat', icon: 'home', myName: 'Me', otherMembers: ['Rahul']);
      final trip = await groups.createGroup(name: 'Paris', icon: 'flight', myName: 'Me', otherMembers: ['Rahul']);
      for (final groupId in [home, trip]) {
        final members = await groups.getMembers(groupId);
        final me = members.firstWhere((member) => member.isMe);
        final rahul = members.firstWhere((member) => !member.isMe);
        await addGroupExpense(groupId, me.id, {me.id: 300, rahul.id: 300});
      }
      await groups.setCurrencyLabel((await groups.getGroup(trip))!, '€');
      final totals = groupTotalsInAppCurrency(await groups.getSummaries(), appSymbol: '₹');
      expect((totals.owedToMe, totals.iOwe), (300, 0));
    });

    test('app totals leave out archived groups', () async {
      final home = await groups.createGroup(name: 'Flat', icon: 'home', myName: 'Me', otherMembers: ['Rahul']);
      final trip = await groups.createGroup(name: 'Goa', icon: 'flight', myName: 'Me', otherMembers: ['Rahul']);
      for (final groupId in [home, trip]) {
        final members = await groups.getMembers(groupId);
        final me = members.firstWhere((member) => member.isMe);
        final rahul = members.firstWhere((member) => !member.isMe);
        await addGroupExpense(groupId, me.id, {me.id: 300, rahul.id: 300});
      }
      await groups.archiveGroup(trip);
      final archived = groupTotalsInAppCurrency(await groups.getSummaries(), appSymbol: '₹');
      expect((archived.owedToMe, archived.iOwe), (300, 0));
      await groups.unarchiveGroup(trip);
      final restored = groupTotalsInAppCurrency(await groups.getSummaries(), appSymbol: '₹');
      expect((restored.owedToMe, restored.iOwe), (600, 0));
    });

    test('backup carries group settings and fills them in for older backups', () async {
      final groupId = await groups.createGroup(name: 'Flat', icon: 'home', myName: 'Me');
      await groups.updateGroup(GroupsCompanion(id: Value(groupId), type: const Value('home'), defaultSplitMethod: const Value('shares'), notes: const Value('Rent on the 1st')));
      final payload = await BackupService(db).snapshot();

      final restored = AppDatabase(NativeDatabase.memory());
      addTearDown(restored.close);
      await BackupService(restored).importSnapshot(payload);
      final group = (await GroupsRepository(restored).getGroup(groupId))!;
      expect((group.type, group.defaultSplitMethod, group.notes), ('home', 'shares', 'Rent on the 1st'));

      final oldRows = [
        for (final row in payload['groups'] as List)
          {...Map<String, dynamic>.from(row as Map)}..removeWhere((key, _) => const {'type', 'defaultSplitMethod', 'notes', 'currencyLabel', 'archivedAt'}.contains(key)),
      ];
      final older = AppDatabase(NativeDatabase.memory());
      addTearDown(older.close);
      await BackupService(older).importSnapshot({...payload, 'groups': oldRows});
      final fromOld = (await GroupsRepository(older).getGroup(groupId))!;
      expect((fromOld.type, fromOld.defaultSplitMethod, fromOld.notes, fromOld.archivedAt), ('other', 'equal', '', null));
    });
  });
}

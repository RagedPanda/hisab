import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/data/backup/backup_service.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/groups_repository.dart';
import 'package:hisab/domain/split/group_activity.dart';

void main() {
  // The backup test restores into a second, independent in-memory database.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late GroupsRepository groups;
  late String groupId;
  late String meId;
  late String rahulId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    groups = GroupsRepository(db);
    groupId = await groups.createGroup(name: 'Goa', icon: 'beach', myName: 'Me', otherMembers: ['Rahul']);
    final members = await groups.getMembers(groupId);
    meId = members.firstWhere((member) => member.isMe).id;
    rahulId = members.firstWhere((member) => !member.isMe).id;
  });

  tearDown(() => db.close());

  Future<void> saveExpense(String entryId, {int amountMinor = 90000, String note = 'Dinner', List<EntryPayersCompanion>? payers}) => groups.saveGroupExpense(
        EntriesRepository.newExpense(id: entryId, amountMinor: amountMinor, occurredAt: DateTime(2026, 10, 20), note: note, groupId: groupId, paidByMemberId: meId, splitMethod: 'equal'),
        splits: [
          SplitsCompanion.insert(id: newId(), entryId: entryId, memberId: meId, amountMinor: amountMinor ~/ 2),
          SplitsCompanion.insert(id: newId(), entryId: entryId, memberId: rahulId, amountMinor: amountMinor - amountMinor ~/ 2),
        ],
        payers: payers ?? const [],
      );

  Future<List<ActivityRecord>> feed({String? group}) async => (await groups.getActivityFeed(groupId: group)).activities;

  test('adding and editing an expense logs who did it with before and after', () async {
    await saveExpense('e1');
    await saveExpense('e1', amountMinor: 120000, note: 'Late dinner');
    final activities = await feed();
    expect(activities.map((activity) => activity.action), [ActivityAction.edited, ActivityAction.added]);
    final edit = activities.first;
    expect(edit.actorMemberId, meId);
    expect(edit.subject, ActivitySubject.expense);
    expect((edit.before! as ExpenseSnapshot).amountMinor, 90000);
    expect((edit.after! as ExpenseSnapshot).amountMinor, 120000);
    expect(edit.changes.map((change) => change.runtimeType), containsAll([AmountChange, DescriptionChange, ShareChange]));
    final added = activities.last.after! as ExpenseSnapshot;
    expect(added.payers.single.memberId, meId);
    expect(added.shares.map((share) => share.memberId), unorderedEquals([meId, rahulId]));
  });

  test('saving an expense unchanged logs nothing new', () async {
    await saveExpense('e1');
    await saveExpense('e1');
    expect(await feed(), hasLength(1));
  });

  test('an edit that only changes what each payer paid is logged', () async {
    List<EntryPayersCompanion> paidBy(int mine, int rahuls) => [
          EntryPayersCompanion.insert(id: newId(), entryId: 'e1', memberId: meId, amountMinor: mine),
          EntryPayersCompanion.insert(id: newId(), entryId: 'e1', memberId: rahulId, amountMinor: rahuls),
        ];
    await saveExpense('e1', amountMinor: 120000, payers: paidBy(40000, 80000));
    await saveExpense('e1', amountMinor: 120000, payers: paidBy(50000, 70000));
    final activities = await feed();
    expect(activities.map((activity) => activity.action), [ActivityAction.edited, ActivityAction.added]);
    expect(activities.first.changes.single, isA<PayersChange>());
  });

  test('a deleted expense comes back with the splits and payers it had', () async {
    await saveExpense('e1', payers: [
      EntryPayersCompanion.insert(id: 'p1', entryId: 'e1', memberId: meId, amountMinor: 50000),
      EntryPayersCompanion.insert(id: 'p2', entryId: 'e1', memberId: rahulId, amountMinor: 40000),
    ]);
    final balancesBefore = await groups.getBalances(groupId);
    await groups.deleteGroupExpense('e1');
    expect(await groups.getGroupEntries(groupId), isEmpty);
    final afterDelete = await groups.getActivityFeed(groupId: groupId);
    expect(afterDelete.activities.first.action, ActivityAction.deleted);
    expect(afterDelete.restorableIds, {afterDelete.activities.first.id});
    expect(afterDelete.deletedExpenseIds, {'e1'});

    await groups.restoreGroupExpense('e1');
    final restored = await groups.getGroupEntries(groupId);
    expect(restored.single.$2, hasLength(2));
    expect(restored.single.$3.map((payer) => payer.id), unorderedEquals(['p1', 'p2']));
    expect((await groups.getBalances(groupId)).net, balancesBefore.net);
    final afterRestore = await groups.getActivityFeed(groupId: groupId);
    expect(afterRestore.activities.map((activity) => activity.action), [ActivityAction.restored, ActivityAction.deleted, ActivityAction.added]);
    expect(afterRestore.restorableIds, isEmpty);
  });

  test('restore keeps splits that an earlier edit replaced deleted', () async {
    await saveExpense('e1');
    await saveExpense('e1', amountMinor: 60000);
    await groups.deleteGroupExpense('e1');
    await groups.restoreGroupExpense('e1');
    final splits = (await groups.getGroupEntries(groupId)).single.$2;
    expect(splits.map((split) => split.amountMinor).fold(0, (sum, amount) => sum + amount), 60000);
  });

  test('restoring a live expense, or one in a deleted group, does nothing', () async {
    await saveExpense('e1');
    await groups.restoreGroupExpense('e1');
    expect(await feed(), hasLength(1));
    await groups.deleteGroupExpense('e1');
    await groups.deleteGroup(groupId);
    await groups.restoreGroupExpense('e1');
    expect((await db.select(db.entries).getSingle()).deletedAt, isNotNull);
  });

  test('payments log add, edit, delete and restore', () async {
    final id = await groups.addSettlement(groupId: groupId, fromMemberId: rahulId, toMemberId: meId, amountMinor: 45000, occurredAt: DateTime(2026, 10, 21));
    await groups.updateSettlement(id: id, fromMemberId: rahulId, toMemberId: meId, amountMinor: 40000, occurredAt: DateTime(2026, 10, 21), note: '', method: 'upi');
    await groups.deleteSettlement(id);
    await groups.restoreSettlement(id);
    final activities = await feed();
    expect(activities.map((activity) => activity.action), [ActivityAction.restored, ActivityAction.deleted, ActivityAction.edited, ActivityAction.added]);
    expect(activities.every((activity) => activity.subject == ActivitySubject.payment), isTrue);
    expect(activities[2].changes.map((change) => change.runtimeType), [AmountChange, MethodChange]);
    expect(activities[1].before, isA<PaymentSnapshot>());
    expect(activities[1].after, isNull);
  });

  test('the overall feed spans groups and drops deleted ones', () async {
    final otherId = await groups.createGroup(name: 'Flat', icon: 'home', myName: 'Me', otherMembers: ['Priya']);
    final others = await groups.getMembers(otherId);
    await saveExpense('e1');
    await groups.addSettlement(groupId: otherId, fromMemberId: others.last.id, toMemberId: others.first.id, amountMinor: 100);
    final everything = await groups.getActivityFeed();
    expect(everything.activities, hasLength(2));
    expect(everything.groupsById.keys, unorderedEquals([groupId, otherId]));
    expect(everything.membersById.keys, containsAll([meId, rahulId]));
    expect(await feed(group: groupId), hasLength(1));
    await groups.deleteGroup(otherId);
    final afterDelete = (await groups.getActivityFeed()).activities;
    expect([for (final activity in afterDelete) (activity.groupId, activity.subject)], [(otherId, ActivitySubject.group), (groupId, ActivitySubject.expense)],
        reason: 'a deleted group keeps only its own deletion row');
  });

  test('a deleted payment offers Restore and comes back with the balances it had', () async {
    await saveExpense('e1');
    final paymentId = await groups.addSettlement(groupId: groupId, fromMemberId: rahulId, toMemberId: meId, amountMinor: 20000);
    final balancesBefore = (await groups.getBalances(groupId)).net;
    await groups.deleteSettlement(paymentId);
    expect((await groups.getBalances(groupId)).net, isNot(balancesBefore));
    final feedAfterDelete = await groups.getActivityFeed(groupId: groupId);
    final deletion = feedAfterDelete.activities.firstWhere((activity) => activity.subject == ActivitySubject.payment && activity.action == ActivityAction.deleted);
    expect(feedAfterDelete.restorableIds, {deletion.id});
    await groups.restoreDeleted(deletion);
    expect((await groups.getBalances(groupId)).net, balancesBefore);
    final feedAfterRestore = await groups.getActivityFeed(groupId: groupId);
    expect(feedAfterRestore.restorableIds, isEmpty);
    expect(feedAfterRestore.activities.first.action, ActivityAction.restored);
  });

  test('a deleted group comes back with its members, expenses, payments and balances', () async {
    await saveExpense('e1', payers: [
      EntryPayersCompanion.insert(id: 'p1', entryId: 'e1', memberId: meId, amountMinor: 60000),
      EntryPayersCompanion.insert(id: 'p2', entryId: 'e1', memberId: rahulId, amountMinor: 30000),
    ]);
    await saveExpense('e2', amountMinor: 40000, note: 'Taxi');
    await saveExpense('gone', amountMinor: 10000, note: 'Chai');
    await groups.deleteGroupExpense('gone');
    await groups.addSettlement(groupId: groupId, fromMemberId: rahulId, toMemberId: meId, amountMinor: 5000);
    final balancesBefore = (await groups.getBalances(groupId)).net;
    final membersBefore = [for (final member in await groups.getMembers(groupId)) member.id];

    await groups.deleteGroup(groupId);
    expect(await groups.getSummaries(), isEmpty);
    final overall = await groups.getActivityFeed();
    final deletion = overall.activities.single;
    expect((deletion.subject, deletion.action), (ActivitySubject.group, ActivityAction.deleted));
    expect((deletion.before! as GroupSnapshot).expenseIds, unorderedEquals(['e1', 'e2']));
    expect(overall.restorableIds, {deletion.id});
    expect(overall.groupsById[groupId]?.name, 'Goa');

    await groups.restoreDeleted(deletion);
    expect((await groups.getSummaries()).map((summary) => summary.group.id), [groupId]);
    expect([for (final member in await groups.getMembers(groupId)) member.id], membersBefore);
    expect((await groups.getBalances(groupId)).net, balancesBefore);
    expect((await groups.getSettlements(groupId)), hasLength(1));
    expect([for (final expense in await groups.getGroupEntries(groupId)) expense.$1.id], unorderedEquals(['e1', 'e2']),
        reason: 'an expense deleted before the group stays deleted');
    final restoredFeed = await groups.getActivityFeed();
    expect(restoredFeed.restorableIds.map((id) => restoredFeed.activities.firstWhere((activity) => activity.id == id).subjectId), ['gone'],
        reason: 'only the earlier expense deletion is still restorable');
    expect(restoredFeed.activities.first.action, ActivityAction.restored);
  });

  test('restoring a payment or group that is live, or a payment in a deleted group, does nothing', () async {
    final paymentId = await groups.addSettlement(groupId: groupId, fromMemberId: rahulId, toMemberId: meId, amountMinor: 5000);
    await groups.restoreSettlement(paymentId);
    await groups.restoreGroup(groupId);
    await groups.deleteSettlement(paymentId);
    await groups.deleteGroup(groupId);
    await groups.restoreSettlement(paymentId);
    final rows = await db.select(db.groupActivities).get();
    expect(rows.where((row) => row.action == ActivityAction.restored.name), isEmpty);
    expect(await groups.getSettlements(groupId), isEmpty);
  });

  test('a removed member still resolves in the feed', () async {
    await saveExpense('e1');
    await groups.removeMember(rahulId);
    expect((await groups.getActivityFeed(groupId: groupId)).membersById[rahulId]?.deletedAt, isNotNull);
  });

  test('backup round-trips the activity log', () async {
    await saveExpense('e1');
    await groups.deleteGroupExpense('e1');
    final snapshot = await BackupService(db).snapshot();
    expect(snapshot['groupActivities'], hasLength(2));

    final restoredDb = AppDatabase(NativeDatabase.memory());
    addTearDown(restoredDb.close);
    await BackupService(restoredDb).importSnapshot(snapshot);
    final rows = await restoredDb.select(restoredDb.groupActivities).get();
    expect(rows.map((row) => row.action), unorderedEquals(['added', 'deleted']));
    expect(rows.firstWhere((row) => row.action == 'deleted').beforeJson, isNotNull);
    await GroupsRepository(restoredDb).restoreGroupExpense('e1');
    expect((await GroupsRepository(restoredDb).getGroupEntries(groupId)).single.$2, hasLength(2));
  });

  test('a log row without a snapshot still reads as an activity', () async {
    await db.into(db.groupActivities).insert(GroupActivitiesCompanion.insert(id: 'a1', groupId: groupId, action: 'deleted', subjectKind: 'expense', subjectId: 'gone', occurredAt: DateTime(2026, 1, 1), beforeJson: const Value('not json')));
    final record = (await feed()).single;
    expect(record.before, isNull);
    expect(record.latest, isNull);
  });

  group('a deleted by-item expense keeps who shared each item (#127)', () {
    const entryId = 'pizza-night';

    Future<void> savePizza(Map<String, List<String>> assignments) => groups.saveGroupExpense(
          EntriesRepository.newExpense(id: entryId, amountMinor: 80000, occurredAt: DateTime(2026, 10, 20), note: 'Pizza night', groupId: groupId, paidByMemberId: meId, splitMethod: 'byItem'),
          items: [
            EntryItemsCompanion.insert(id: 'pizza', entryId: entryId, name: 'Pizza', unitPriceMinor: 60000, amountMinor: 60000),
            EntryItemsCompanion.insert(id: 'coke', entryId: entryId, name: 'Coke', unitPriceMinor: 20000, amountMinor: 20000),
          ],
          splits: [
            SplitsCompanion.insert(id: 's-me', entryId: entryId, memberId: meId, amountMinor: 30000),
            SplitsCompanion.insert(id: 's-rahul', entryId: entryId, memberId: rahulId, amountMinor: 50000),
          ],
          itemAssignments: assignments,
        );

    Map<String, List<String>> sorted(Map<String, List<String>> assignments) => {
          for (final item in assignments.entries) item.key: [...item.value]..sort(),
        };

    Future<Map<String, List<String>>> assignmentsNow() async => sorted(await EntriesRepository(db).getItemAssignments(entryId));

    test('Restore from the activity feed brings the item assignments back', () async {
      await savePizza({'pizza': [meId, rahulId], 'coke': [rahulId]});
      final expected = await assignmentsNow();
      await groups.deleteGroupExpense(entryId);
      expect(await assignmentsNow(), isEmpty);
      final deletion = (await feed()).firstWhere((activity) => activity.subject == ActivitySubject.expense && activity.action == ActivityAction.deleted);

      await groups.restoreDeleted(deletion);

      expect(await assignmentsNow(), expected);
      expect(await db.select(db.itemAssignments).get(), hasLength(3), reason: 'the same rows come back, none are duplicated');
    });

    test('Undo after delete brings the item assignments back, not ones an earlier edit removed', () async {
      await savePizza({'pizza': [meId, rahulId], 'coke': [rahulId]});
      await savePizza({'pizza': [meId], 'coke': [rahulId]});
      final expected = await assignmentsNow();
      await groups.deleteGroupExpense(entryId);

      await groups.restoreGroupExpense(entryId);

      expect(await assignmentsNow(), expected);
      expect(expected['pizza'], [meId]);
    });
  });
}

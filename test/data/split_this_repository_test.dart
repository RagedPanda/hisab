import 'package:drift/drift.dart' show BooleanExpressionOperators, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/groups_repository.dart';
import 'package:hisab/domain/split/group_activity.dart';

/// "Split this" converts a personal expense into a group expense in place, so
/// my totals count only my share and nothing is counted twice.
void main() {
  late AppDatabase db;
  late EntriesRepository entries;
  late GroupsRepository groups;
  late String groupId;
  late String meId;
  late String rahulId;
  final day = DateTime(2026, 10, 20, 20);
  final october = DateRange(DateTime(2026, 10), DateTime(2026, 11));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    entries = EntriesRepository(db);
    groups = GroupsRepository(db);
    groupId = await groups.createGroup(name: 'Goa', icon: 'beach', myName: 'Me', otherMembers: ['Rahul']);
    final members = await groups.getMembers(groupId);
    meId = members.firstWhere((member) => member.isMe).id;
    rahulId = members.firstWhere((member) => !member.isMe).id;
    await entries.saveEntry(
      EntriesRepository.newExpense(id: 'dinner', amountMinor: 90000, occurredAt: day, payee: 'Fisherman’s Wharf', note: 'Dinner', accountId: 'cash'),
      items: [EntryItemsCompanion.insert(id: 'fish', entryId: 'dinner', name: 'Fish thali', unitPriceMinor: 90000, amountMinor: 90000)],
      fieldValues: [EntryFieldValuesCompanion.insert(id: 'fv1', entryId: 'dinner', fieldKey: 'guests', numberValue: const Value(2))],
    );
  });

  tearDown(() => db.close());

  /// Saves the entry into the group the way the editor does: same id, me
  /// paying, split equally between the two of us.
  Future<void> splitDinner() => groups.saveGroupExpense(
        EntriesRepository.newExpense(id: 'dinner', amountMinor: 90000, occurredAt: day, payee: 'Fisherman’s Wharf', note: 'Dinner', groupId: groupId, paidByMemberId: meId, splitMethod: 'equal'),
        items: [EntryItemsCompanion.insert(id: 'fish', entryId: 'dinner', name: 'Fish thali', unitPriceMinor: 90000, amountMinor: 90000)],
        splits: [
          SplitsCompanion.insert(id: newId(), entryId: 'dinner', memberId: meId, amountMinor: 45000),
          SplitsCompanion.insert(id: newId(), entryId: 'dinner', memberId: rahulId, amountMinor: 45000),
        ],
        payers: const [],
        fieldValues: const [],
      );

  Future<List<Entry>> live() => (db.select(db.entries)..where((t) => t.deletedAt.isNull())).get();
  Future<List<ActivityAction>> activity() async => [for (final row in (await groups.getActivityFeed(groupId: groupId)).activities) row.action];

  test('the source keeps what the personal entry had', () async {
    final source = (await groups.splitSourceOf('dinner'))!;
    expect((source.entry.accountId, source.entry.payee), ('cash', 'Fisherman’s Wharf'));
    expect(source.items.single.name, 'Fish thali');
    expect(source.fieldValues.single.fieldKey, 'guests');
  });

  test('income, group expenses and missing entries have no split source', () async {
    await entries.saveEntry(EntriesRepository.newExpense(id: 'salary', kind: 'income', amountMinor: 1, occurredAt: day));
    expect(await groups.splitSourceOf('salary'), isNull);
    expect(await groups.splitSourceOf('gone'), isNull);
    await splitDinner();
    expect(await groups.splitSourceOf('dinner'), isNull);
  });

  test('splitting replaces the entry and my totals count only my share', () async {
    expect((await entries.watchTotals(october).first).expense, 90000);
    await splitDinner();

    final rows = await live();
    expect(rows.map((row) => row.id), ['dinner'], reason: 'converted, not duplicated');
    expect((rows.single.groupId, rows.single.accountId), (groupId, null));
    expect((await entries.watchTotals(october).first).expense, 45000);
    expect((await entries.watchDailyExpense(october).first).values.single, 45000);
    expect(await activity(), [ActivityAction.added], reason: 'new to the group, not an edit');
  });

  test('undo puts the personal entry back as it was', () async {
    final source = (await groups.splitSourceOf('dinner'))!;
    await splitDinner();
    await groups.unsplitExpense(source);

    final entry = (await entries.getEntry('dinner'))!;
    expect((entry.entry.groupId, entry.entry.accountId, entry.entry.splitMethod), (null, 'cash', null));
    expect(entry.splits, isEmpty);
    expect(entry.items.single.name, 'Fish thali');
    final values = await (db.select(db.entryFieldValues)..where((t) => t.entryId.equals('dinner') & t.deletedAt.isNull())).get();
    expect(values.single.numberValue, 2);
    expect((await entries.watchTotals(october).first).expense, 90000);
    expect(await activity(), [ActivityAction.deleted, ActivityAction.added]);
    expect((await groups.getBalances(groupId)).net.values.every((net) => net == 0), isTrue);
  });
}

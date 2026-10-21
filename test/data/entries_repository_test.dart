import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/categories_repository.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/groups_repository.dart';

void main() {
  late AppDatabase db;
  late EntriesRepository entries;
  final range = DateRange(DateTime(2026, 10, 1), DateTime(2026, 11, 1));

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    entries = EntriesRepository(db);
  });

  tearDown(() => db.close());

  test('AND-06: a deleted category reads as uncategorised on its entries', () async {
    final categories = CategoriesRepository(db);
    final categoryId = await categories.create(name: 'Chai Tapri Stall', icon: 'local_cafe', color: 0xFF000000, kind: 'expense');
    final id = newId();
    await entries.saveEntry(EntriesRepository.newExpense(id: id, amountMinor: 6000, occurredAt: DateTime(2026, 10, 5), categoryId: categoryId));
    expect((await entries.getEntry(id))!.category?.name, 'Chai Tapri Stall');

    await categories.delete(categoryId);

    expect((await entries.getEntry(id))!.category, isNull);
    final listed = await entries.watchEntries(range: range, myLedger: true).first;
    expect(listed.single.category, isNull);
    expect(await entries.watchCategoryTotals(range).first, {'': 6000});
  });

  test('P2-1: my share of a group expense counts in month lists and totals', () async {
    final groups = GroupsRepository(db);
    final groupId = await groups.createGroup(name: 'Goa Trip', icon: 'beach', myName: 'Me', otherMembers: ['Priya']);
    final members = await groups.getMembers(groupId);
    final me = members.firstWhere((m) => m.isMe).id;
    final priya = members.firstWhere((m) => !m.isMe).id;
    final dinner = newId();
    await entries.saveEntry(
      EntriesRepository.newExpense(id: dinner, amountMinor: 124000, occurredAt: DateTime(2026, 10, 8), groupId: groupId, paidByMemberId: priya, splitMethod: 'equal'),
      splits: [
        SplitsCompanion.insert(id: newId(), entryId: dinner, memberId: me, amountMinor: 62000),
        SplitsCompanion.insert(id: newId(), entryId: dinner, memberId: priya, amountMinor: 62000),
      ],
    );
    await entries.saveEntry(EntriesRepository.newExpense(amountMinor: 2500, occurredAt: DateTime(2026, 10, 9)));

    final listed = await entries.watchEntries(range: range, myLedger: true).first;
    final groupRow = listed.firstWhere((d) => d.entry.id == dinner);
    expect(groupRow.group?.name, 'Goa Trip');
    expect(groupRow.myShareMinor, 62000);
    expect(groupRow.myAmountMinor, 62000);
    expect(await entries.watchTotals(range).first, (expense: 64500, income: 0));
    expect(await entries.watchDailyExpense(range).first, {DateTime(2026, 10, 8): 62000, DateTime(2026, 10, 9): 2500});
  });

  test('a group expense I have no share in stays out of my ledger', () async {
    final groups = GroupsRepository(db);
    final groupId = await groups.createGroup(name: 'Office', icon: 'work', myName: 'Me', otherMembers: ['A', 'B']);
    final members = await groups.getMembers(groupId);
    final others = members.where((m) => !m.isMe).toList();
    final id = newId();
    await entries.saveEntry(
      EntriesRepository.newExpense(id: id, amountMinor: 1000, occurredAt: DateTime(2026, 10, 8), groupId: groupId, paidByMemberId: others.first.id, splitMethod: 'equal'),
      splits: [for (final m in others) SplitsCompanion.insert(id: newId(), entryId: id, memberId: m.id, amountMinor: 500)],
    );
    expect(await entries.watchEntries(range: range, myLedger: true).first, isEmpty);
    expect(await entries.watchTotals(range).first, (expense: 0, income: 0));
  });

  test('transfer rows carry both accounts', () async {
    await db.into(db.accounts).insert(AccountsCompanion.insert(id: 'bank', name: 'HDFC', type: 'bank', color: 1));
    await db.into(db.accounts).insert(AccountsCompanion.insert(id: 'cash', name: 'Cash', type: 'cash', color: 2));
    await entries.saveEntry(EntriesRepository.newExpense(kind: 'transfer', amountMinor: 30000, occurredAt: DateTime(2026, 10, 2), accountId: 'bank').copyWith(toAccountId: const Value('cash')));
    final row = (await entries.watchEntries(range: range, myLedger: true).first).single;
    expect(row.account?.name, 'HDFC');
    expect(row.toAccount?.name, 'Cash');
  });
}

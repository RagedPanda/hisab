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

  test('watchEntries narrows to one project when projectId is given', () async {
    await entries.saveEntry(EntriesRepository.newExpense(id: newId(), amountMinor: 1000, occurredAt: DateTime(2026, 10, 5), projectId: 'car'));
    await entries.saveEntry(EntriesRepository.newExpense(id: newId(), amountMinor: 2000, occurredAt: DateTime(2026, 10, 6), projectId: 'house'));
    await entries.saveEntry(EntriesRepository.newExpense(id: newId(), amountMinor: 3000, occurredAt: DateTime(2026, 10, 7)));

    final car = await entries.watchEntries(projectId: 'car').first;
    expect(car.map((details) => details.entry.amountMinor), [1000]);
    expect((await entries.watchEntries(range: range, myLedger: true).first).length, 3, reason: 'no project filter keeps every entry');
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

  test('watchAccountMovements lists entries charged to or paid into one account since a date', () async {
    await entries.saveEntry(EntriesRepository.newExpense(amountMinor: 1000, occurredAt: DateTime(2026, 10, 5), accountId: 'card'));
    await entries.saveEntry(EntriesRepository.newExpense(amountMinor: 2000, occurredAt: DateTime(2026, 9, 30), accountId: 'card'));
    await entries.saveEntry(EntriesRepository.newExpense(amountMinor: 3000, occurredAt: DateTime(2026, 10, 6), accountId: 'bank'));
    await entries.saveEntry(EntriesRepository.newExpense(kind: 'transfer', amountMinor: 4000, occurredAt: DateTime(2026, 10, 7), accountId: 'bank').copyWith(toAccountId: const Value('card')));
    final deletedId = newId();
    await entries.saveEntry(EntriesRepository.newExpense(id: deletedId, amountMinor: 5000, occurredAt: DateTime(2026, 10, 8), accountId: 'card'));
    await entries.deleteEntry(deletedId);

    final movements = await entries.watchAccountMovements('card', since: DateTime(2026, 10, 1)).first;
    expect(movements.map((movement) => (movement.kind, movement.amountMinor)).toSet(), {('expense', 1000), ('transfer', 4000)});
    expect(movements.firstWhere((movement) => movement.kind == 'transfer').toAccountId, 'card');
  });

  test('transfer rows carry both accounts', () async {
    await db.into(db.accounts).insert(AccountsCompanion.insert(id: 'bank', name: 'HDFC', type: 'bank', color: 1));
    await db.into(db.accounts).insert(AccountsCompanion.insert(id: 'cash', name: 'Cash', type: 'cash', color: 2));
    await entries.saveEntry(EntriesRepository.newExpense(kind: 'transfer', amountMinor: 30000, occurredAt: DateTime(2026, 10, 2), accountId: 'bank').copyWith(toAccountId: const Value('cash')));
    final row = (await entries.watchEntries(range: range, myLedger: true).first).single;
    expect(row.account?.name, 'HDFC');
    expect(row.toAccount?.name, 'Cash');
  });

  test('ledger lines carry my share of group entries and key deleted categories on null', () async {
    final groups = GroupsRepository(db);
    final groupId = await groups.createGroup(name: 'Trip', icon: 'beach', myName: '', otherMembers: ['Priya']);
    final members = await groups.getMembers(groupId);
    final me = members.firstWhere((member) => member.isMe);
    final other = members.firstWhere((member) => !member.isMe);
    final groupEntryId = newId();
    await entries.saveEntry(
      EntriesRepository.newExpense(id: groupEntryId, amountMinor: 50000, occurredAt: DateTime(2026, 10, 9), groupId: groupId, paidByMemberId: me.id, splitMethod: 'equal'),
      splits: [
        SplitsCompanion.insert(id: newId(), entryId: groupEntryId, memberId: me.id, amountMinor: 20000),
        SplitsCompanion.insert(id: newId(), entryId: groupEntryId, memberId: other.id, amountMinor: 30000),
      ],
    );
    await entries.saveEntry(EntriesRepository.newExpense(amountMinor: 7000, occurredAt: DateTime(2026, 10, 2)));
    await entries.saveEntry(EntriesRepository.newExpense(amountMinor: 9000, occurredAt: DateTime(2026, 9, 30)));

    final lines = await entries.watchLedgerLines(range).first;
    expect(lines.map((line) => line.amountMinor), [20000, 7000]);
    expect(lines.every((line) => line.categoryId == null), isTrue);
    expect(await entries.watchTotals(range).first, (expense: 27000, income: 0));
  });

  test('watchTagTexts lists distinct tags of live entries only', () async {
    final deletedId = newId();
    await entries.saveEntry(EntriesRepository.newExpense(id: newId(), amountMinor: 1000, occurredAt: DateTime(2026, 10, 5)).copyWith(tags: const Value('#home')));
    await entries.saveEntry(EntriesRepository.newExpense(id: newId(), amountMinor: 2000, occurredAt: DateTime(2026, 10, 6)).copyWith(tags: const Value('#home')));
    await entries.saveEntry(EntriesRepository.newExpense(id: newId(), amountMinor: 3000, occurredAt: DateTime(2026, 10, 7)));
    await entries.saveEntry(EntriesRepository.newExpense(id: deletedId, amountMinor: 4000, occurredAt: DateTime(2026, 10, 8)).copyWith(tags: const Value('old')));
    await entries.deleteEntry(deletedId);
    expect(await entries.watchTagTexts().first, ['#home']);
  });

  group('watchEntries filters', () {
    late String travelId;

    setUp(() async {
      travelId = await CategoriesRepository(db).create(name: 'Road Trips', icon: 'flight', color: 0xFF000000, kind: 'expense');
      await entries.saveEntry(EntriesRepository.newExpense(id: 'fuel', amountMinor: 3000, occurredAt: DateTime(2026, 10, 4), accountId: 'hdfc', categoryId: travelId, note: 'Fuel for Goa'));
      await entries.saveEntry(EntriesRepository.newExpense(id: 'dinner', amountMinor: 9000, occurredAt: DateTime(2026, 10, 5), groupId: 'flatmates', payee: 'Toit'));
      await entries.saveEntry(EntriesRepository.newExpense(id: 'snacks', amountMinor: 500, occurredAt: DateTime(2026, 10, 6)).copyWith(tags: const Value('goa')));
    });

    Future<List<String>> idsOf(Stream<List<EntryDetails>> stream) async => [for (final details in await stream.first) details.entry.id];

    test('narrow by group, account and category', () async {
      expect(await idsOf(entries.watchEntries(groupId: 'flatmates')), ['dinner']);
      expect(await idsOf(entries.watchEntries(accountId: 'hdfc')), ['fuel']);
      expect(await idsOf(entries.watchEntries(categoryId: travelId)), ['fuel']);
    });

    test('search matches note, payee, category name or tags, ignoring case', () async {
      expect(await idsOf(entries.watchEntries(search: ' GOA ')), unorderedEquals(['fuel', 'snacks']));
      expect(await idsOf(entries.watchEntries(search: 'toit')), ['dinner']);
      expect(await idsOf(entries.watchEntries(search: 'road')), ['fuel']);
      expect(await idsOf(entries.watchEntries(search: '   ')), hasLength(3), reason: 'a blank search does not filter');
    });

    test('limit keeps the newest entries', () async {
      expect(await idsOf(entries.watchEntries(limit: 2)), ['snacks', 'dinner']);
    });

    test('watching one entry by id follows it', () async {
      final line = (await entries.watchEntriesById('fuel').first).single.ledgerLine;
      expect((line.amountMinor, line.categoryId), (3000, travelId));
      expect(await entries.watchEntriesById('missing').first, isEmpty);
    });
  });

  test('recent payees and categories list the newest distinct values', () async {
    final categories = await CategoriesRepository(db).getAll();
    final food = categories.firstWhere((category) => category.kind == 'expense').id;
    final salary = categories.firstWhere((category) => category.kind == 'income').id;
    await entries.saveEntry(EntriesRepository.newExpense(amountMinor: 100, occurredAt: DateTime(2026, 10, 1), payee: 'Swiggy', categoryId: food));
    await entries.saveEntry(EntriesRepository.newExpense(amountMinor: 200, occurredAt: DateTime(2026, 10, 3), payee: 'Zomato', categoryId: food));
    await entries.saveEntry(EntriesRepository.newExpense(kind: 'income', amountMinor: 900, occurredAt: DateTime(2026, 10, 2), categoryId: salary));

    expect(await entries.recentPayees(), ['Zomato', 'Swiggy']);
    expect(await entries.recentPayees(limit: 1), ['Zomato']);
    expect(await entries.recentCategoryIds(kind: 'expense'), [food]);
    expect(await entries.recentCategoryIds(kind: 'income'), [salary]);
  });

  test('an SMS is known once an entry records it', () async {
    expect(await entries.existsForSms('sms-42'), isFalse);
    await entries.saveEntry(EntriesRepository.newExpense(amountMinor: 100, occurredAt: DateTime(2026, 10, 1), source: 'sms', smsId: 'sms-42'));
    expect(await entries.existsForSms('sms-42'), isTrue);
  });
}

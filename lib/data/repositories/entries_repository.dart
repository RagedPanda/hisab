import 'package:drift/drift.dart';

import '../../core/dates.dart';
import '../../core/ids.dart';
import '../../domain/ledger/personal_totals.dart';
import '../db/database.dart';

/// An entry with the rows the UI needs alongside it.
class EntryDetails {
  const EntryDetails({
    required this.entry,
    required this.items,
    this.category,
    this.account,
    this.toAccount,
    this.group,
    this.myShareMinor,
    this.splits = const [],
  });
  final Entry entry;
  final List<EntryItem> items;
  final Category? category;
  final Account? account;
  final Account? toAccount;
  final Group? group;

  /// My split of a group entry; null for personal entries or when I have no share.
  final int? myShareMinor;
  final List<Split> splits;

  bool get isGroupEntry => entry.groupId != null;

  /// What this entry costs me: the full amount, or my share of a group entry.
  int get myAmountMinor => myAmountMinorOf(amountMinor: entry.amountMinor, isGroupEntry: isGroupEntry, myShareMinor: myShareMinor);

  LedgerLine get ledgerLine => LedgerLine(kind: entry.kind, amountMinor: myAmountMinor, occurredAt: entry.occurredAt, categoryId: category?.id);
}

/// A remembered item for a category: what the user bought last time.
class ItemSuggestion {
  const ItemSuggestion({
    required this.name,
    required this.unit,
    required this.lastQuantity,
    required this.lastUnitPriceMinor,
    required this.timesUsed,
  });
  final String name;
  final String? unit;
  final double lastQuantity;
  final int lastUnitPriceMinor;
  final int timesUsed;
}

class EntriesRepository {
  EntriesRepository(this.db);
  final AppDatabase db;

  late final $AccountsTable _toAccounts = db.alias(db.accounts, 'to_accounts');
  late final $SplitsTable _mySplits = db.alias(db.splits, 'my_splits');

  /// Ids of the "me" member in every group, for picking out my split.
  BaseSelectStatement get _myMemberIds => db.selectOnly(db.members)
    ..addColumns([db.members.id])
    ..where(db.members.isMe.equals(true) & db.members.deletedAt.isNull());

  /// Entries joined with everything [EntryDetails] shows. A deleted category
  /// joins as null so the row reads "Uncategorised".
  JoinedSelectStatement<HasResultSet, dynamic> _detailsQuery() => db.select(db.entries).join([
        leftOuterJoin(db.categories, db.categories.id.equalsExp(db.entries.categoryId) & db.categories.deletedAt.isNull()),
        leftOuterJoin(db.accounts, db.accounts.id.equalsExp(db.entries.accountId)),
        leftOuterJoin(_toAccounts, _toAccounts.id.equalsExp(db.entries.toAccountId)),
        leftOuterJoin(db.groups, db.groups.id.equalsExp(db.entries.groupId)),
        leftOuterJoin(_mySplits, _mySplits.entryId.equalsExp(db.entries.id) & _mySplits.deletedAt.isNull() & _mySplits.memberId.isInQuery(_myMemberIds)),
      ]);

  /// [myLedger] keeps personal entries plus the group entries I have a share
  /// in, so month lists and totals reflect what I actually spent.
  Stream<List<EntryDetails>> watchEntries({
    DateRange? range,
    String? groupId,
    bool myLedger = false,
    String? accountId,
    String? categoryId,
    String? projectId,
    String? search,
    int? limit,
  }) =>
      _filteredQuery(range: range, groupId: groupId, myLedger: myLedger, accountId: accountId, categoryId: categoryId, projectId: projectId, search: search, limit: limit)
          .watch()
          .asyncMap(_hydrate);

  /// The joined entry rows matching the filters, newest first.
  JoinedSelectStatement<HasResultSet, dynamic> _filteredQuery({
    DateRange? range,
    String? groupId,
    bool myLedger = false,
    String? accountId,
    String? categoryId,
    String? projectId,
    String? search,
    int? limit,
  }) {
    final query = _detailsQuery();
    final conditions = <Expression<bool>>[db.entries.deletedAt.isNull()];
    if (range != null) {
      conditions.add(db.entries.occurredAt.isBiggerOrEqualValue(range.start));
      conditions.add(db.entries.occurredAt.isSmallerThanValue(range.end));
    }
    if (groupId != null) conditions.add(db.entries.groupId.equals(groupId));
    if (myLedger) conditions.add(db.entries.groupId.isNull() | _mySplits.id.isNotNull());
    if (accountId != null) {
      conditions.add(db.entries.accountId.equals(accountId) | db.entries.toAccountId.equals(accountId));
    }
    if (categoryId != null) conditions.add(db.entries.categoryId.equals(categoryId));
    if (projectId != null) conditions.add(db.entries.projectId.equals(projectId));
    if (search != null && search.trim().isNotEmpty) {
      final like = '%${search.trim().toLowerCase()}%';
      conditions.add(db.entries.note.lower().like(like) |
          db.entries.payee.lower().like(like) |
          db.categories.name.lower().like(like) |
          db.entries.tags.lower().like(like));
    }
    query.where(conditions.reduce((a, b) => a & b));
    query.orderBy([OrderingTerm.desc(db.entries.occurredAt), OrderingTerm.desc(db.entries.createdAt)]);
    if (limit != null) query.limit(limit);
    return query;
  }

  /// My ledger in [range] reduced to the fields the roll-ups need: one query,
  /// no item or split hydration, so dashboards stay cheap at thousands of rows.
  /// The distinct non-empty tags text of live entries, for the tag filter.
  Stream<List<String>> watchTagTexts() {
    final query = db.selectOnly(db.entries, distinct: true)
      ..addColumns([db.entries.tags])
      ..where(db.entries.deletedAt.isNull() & db.entries.tags.equals('').not());
    return query.watch().map((rows) => [for (final row in rows) row.read(db.entries.tags)!]);
  }

  /// Whether any live entry exists at all, for the first-run empty state.
  Stream<bool> watchHasAnyEntries() {
    final query = db.selectOnly(db.entries)
      ..addColumns([db.entries.id])
      ..where(db.entries.deletedAt.isNull())
      ..limit(1);
    return query.watch().map((rows) => rows.isNotEmpty);
  }

  /// Account ids, most recently used first (by the latest live entry that
  /// paid from them), so a picker can default to the account used last.
  Stream<List<String>> watchRecentAccountIds() {
    final lastUsed = db.entries.updatedAt.max();
    final query = db.selectOnly(db.entries)
      ..addColumns([db.entries.accountId, lastUsed])
      ..where(db.entries.deletedAt.isNull() & db.entries.accountId.isNotNull())
      ..groupBy([db.entries.accountId])
      ..orderBy([OrderingTerm.desc(lastUsed)]);
    return query.watch().map((rows) => [for (final row in rows) row.read(db.entries.accountId)!]);
  }

  Stream<List<LedgerLine>> watchLedgerLines(DateRange range) => _filteredQuery(range: range, myLedger: true).watch().map(_toLedgerLines);

  List<LedgerLine> _toLedgerLines(List<TypedResult> rows) => [
        for (final row in rows)
          LedgerLine(
            kind: row.readTable(db.entries).kind,
            amountMinor: myAmountMinorOf(
              amountMinor: row.readTable(db.entries).amountMinor,
              isGroupEntry: row.readTable(db.entries).groupId != null,
              myShareMinor: row.readTableOrNull(_mySplits)?.amountMinor,
            ),
            occurredAt: row.readTable(db.entries).occurredAt,
            categoryId: row.readTableOrNull(db.categories)?.id,
          ),
      ];

  /// Loads items and splits for joined entry rows in two queries, not per row.
  Future<List<EntryDetails>> _hydrate(List<TypedResult> rows) async {
    final entries = rows.map((r) => r.readTable(db.entries)).toList();
    final ids = entries.map((e) => e.id).toList();
    final items = ids.isEmpty
        ? <EntryItem>[]
        : await (db.select(db.entryItems)
              ..where((t) => t.entryId.isIn(ids) & t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    final splits = ids.isEmpty
        ? <Split>[]
        : await (db.select(db.splits)..where((t) => t.entryId.isIn(ids) & t.deletedAt.isNull())).get();
    return [
      for (final row in rows)
        EntryDetails(
          entry: row.readTable(db.entries),
          category: row.readTableOrNull(db.categories),
          account: row.readTableOrNull(db.accounts),
          toAccount: row.readTableOrNull(_toAccounts),
          group: row.readTableOrNull(db.groups),
          myShareMinor: row.readTableOrNull(_mySplits)?.amountMinor,
          items: items.where((i) => i.entryId == row.readTable(db.entries).id).toList(),
          splits: splits.where((s) => s.entryId == row.readTable(db.entries).id).toList(),
        ),
    ];
  }

  JoinedSelectStatement<HasResultSet, dynamic> _byIdQuery(String id) => _detailsQuery()..where(db.entries.id.equals(id));

  Future<EntryDetails?> getEntry(String id) async {
    final list = await _hydrate(await _byIdQuery(id).get());
    return list.isEmpty ? null : list.first;
  }

  Stream<List<EntryDetails>> watchEntriesById(String id) => _byIdQuery(id).watch().asyncMap(_hydrate);

  /// Inserts or replaces an entry with its items and splits atomically.
  /// [fieldValues], when given, replace the project field values the entry
  /// recorded; null leaves them as they are. [payers], when given, replace
  /// the several-payer rows of a group expense (empty for a single payer);
  /// null leaves them as they are. [itemAssignments], when given, replace who
  /// shares each item of a by-item split (item id to member ids; empty clears
  /// them); null leaves them as they are.
  Future<void> saveEntry(
    EntriesCompanion entry, {
    List<EntryItemsCompanion> items = const [],
    List<SplitsCompanion> splits = const [],
    List<EntryFieldValuesCompanion>? fieldValues,
    List<EntryPayersCompanion>? payers,
    Map<String, List<String>>? itemAssignments,
  }) {
    final entryId = entry.id.value;
    final now = DateTime.now();
    return db.transaction(() async {
      await db.into(db.entries).insertOnConflictUpdate(entry.copyWith(updatedAt: Value(now)));
      await (db.update(db.entryItems)..where((t) => t.entryId.equals(entryId)))
          .write(EntryItemsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      for (var i = 0; i < items.length; i++) {
        await db.into(db.entryItems).insertOnConflictUpdate(items[i].copyWith(
              entryId: Value(entryId),
              sortOrder: Value(i),
              deletedAt: const Value(null),
              updatedAt: Value(now),
            ));
      }
      await (db.update(db.splits)..where((t) => t.entryId.equals(entryId)))
          .write(SplitsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      for (final split in splits) {
        await db.into(db.splits).insertOnConflictUpdate(split.copyWith(
              entryId: Value(entryId),
              deletedAt: const Value(null),
              updatedAt: Value(now),
            ));
      }
      if (payers != null) {
        await (db.update(db.entryPayers)..where((t) => t.entryId.equals(entryId)))
            .write(EntryPayersCompanion(deletedAt: Value(now), updatedAt: Value(now)));
        for (final payer in payers) {
          await db.into(db.entryPayers).insertOnConflictUpdate(payer.copyWith(
                entryId: Value(entryId),
                deletedAt: const Value(null),
                updatedAt: Value(now),
              ));
        }
      }
      if (itemAssignments != null) {
        await _tombstoneAssignments(entryId, now);
        for (final assignment in itemAssignments.entries) {
          for (final memberId in assignment.value) {
            await db.into(db.itemAssignments).insertOnConflictUpdate(ItemAssignmentsCompanion.insert(
                  id: '${assignment.key}:$memberId',
                  entryItemId: assignment.key,
                  memberId: memberId,
                  updatedAt: Value(now),
                  deletedAt: const Value(null),
                ));
          }
        }
      }
      if (fieldValues != null) {
        await (db.update(db.entryFieldValues)..where((t) => t.entryId.equals(entryId)))
            .write(EntryFieldValuesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
        for (final value in fieldValues) {
          await db.into(db.entryFieldValues).insertOnConflictUpdate(value.copyWith(
                entryId: Value(entryId),
                deletedAt: const Value(null),
                updatedAt: Value(now),
              ));
        }
      }
    });
  }

  Future<void> deleteEntry(String id) {
    final now = DateTime.now();
    return db.transaction(() async {
      await (db.update(db.entries)..where((t) => t.id.equals(id)))
          .write(EntriesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await (db.update(db.splits)..where((t) => t.entryId.equals(id)))
          .write(SplitsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await (db.update(db.entryPayers)..where((t) => t.entryId.equals(id)))
          .write(EntryPayersCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await _tombstoneAssignments(id, now);
    });
  }

  /// Soft-deletes every item assignment under any item, live or not, of [entryId].
  Future<void> _tombstoneAssignments(String entryId, DateTime now) =>
      (db.update(db.itemAssignments)..where((t) => t.entryItemId.isInQuery(_itemIdsOf(entryId)) & t.deletedAt.isNull()))
          .write(ItemAssignmentsCompanion(deletedAt: Value(now), updatedAt: Value(now)));

  /// Brings back item assignments of [entryId] after [deleteEntry]: the rows
  /// in [ids] when the deletion recorded them, otherwise the rows tombstoned
  /// at [deletedAt], so a restored by-item expense keeps who shared each item.
  Future<void> restoreAssignments(String entryId, {List<String>? ids, required DateTime deletedAt}) {
    final now = DateTime.now();
    return (db.update(db.itemAssignments)
          ..where((t) => t.entryItemId.isInQuery(_itemIdsOf(entryId)) & (ids == null ? t.deletedAt.equals(deletedAt) : t.id.isIn(ids))))
        .write(ItemAssignmentsCompanion(deletedAt: const Value(null), updatedAt: Value(now)));
  }

  /// Ids of every item, live or not, of [entryId], as a subquery.
  JoinedSelectStatement<$EntryItemsTable, EntryItem> _itemIdsOf(String entryId) => db.selectOnly(db.entryItems)
    ..addColumns([db.entryItems.id])
    ..where(db.entryItems.entryId.equals(entryId));

  /// Who shares each live item of [entryId]'s by-item split, in one query:
  /// item id to member ids. Items nobody was assigned to are absent.
  Future<Map<String, List<String>>> getItemAssignments(String entryId) async => assignmentsByItem(await getItemAssignmentRows(entryId));

  /// The live assignment rows under the live items of [entryId].
  Future<List<ItemAssignment>> getItemAssignmentRows(String entryId) async {
    final rows = await (db.select(db.itemAssignments).join([
      innerJoin(db.entryItems, db.entryItems.id.equalsExp(db.itemAssignments.entryItemId)),
    ])
          ..where(db.entryItems.entryId.equals(entryId) & db.entryItems.deletedAt.isNull() & db.itemAssignments.deletedAt.isNull()))
        .get();
    return [for (final row in rows) row.readTable(db.itemAssignments)];
  }

  /// The live several-payer rows of an entry; empty for a single payer.
  Future<List<EntryPayer>> getPayers(String entryId) =>
      (db.select(db.entryPayers)..where((t) => t.entryId.equals(entryId) & t.deletedAt.isNull())).get();

  /// Total minor units per category id for expenses (or income) in [range],
  /// counting my share of group entries. Deleted categories key on ''.
  Stream<Map<String, int>> watchCategoryTotals(DateRange range, {String kind = 'expense'}) =>
      watchLedgerLines(range).map((lines) => totalsByCategory(lines, kind: kind));

  /// (expense, income) totals for what I spent and earned in [range].
  Stream<({int expense, int income})> watchTotals(DateRange range) => watchLedgerLines(range).map(totalsByKind);

  /// Expense total per calendar day in [range].
  Stream<Map<DateTime, int>> watchDailyExpense(DateRange range) => watchLedgerLines(range).map(expenseByDay);

  /// Items previously entered under [categoryId], most used first.
  Future<List<ItemSuggestion>> itemSuggestions(String categoryId, {int limit = 12}) async {
    final query = db.select(db.entryItems).join([
      innerJoin(db.entries, db.entries.id.equalsExp(db.entryItems.entryId)),
    ])
      ..where(db.entries.categoryId.equals(categoryId) & db.entryItems.deletedAt.isNull() & db.entries.deletedAt.isNull())
      ..orderBy([OrderingTerm.desc(db.entries.occurredAt)]);
    final rows = await query.get();
    final byName = <String, List<EntryItem>>{};
    for (final row in rows) {
      final item = row.readTable(db.entryItems);
      byName.putIfAbsent(item.name.trim().toLowerCase(), () => []).add(item);
    }
    final suggestions = byName.values.map((items) {
      final latest = items.first;
      return ItemSuggestion(
        name: latest.name,
        unit: latest.unit,
        lastQuantity: latest.quantity,
        lastUnitPriceMinor: latest.unitPriceMinor,
        timesUsed: items.length,
      );
    }).toList()
      ..sort((a, b) => b.timesUsed.compareTo(a.timesUsed));
    return suggestions.take(limit).toList();
  }

  Future<List<String>> recentPayees({int limit = 20}) async {
    final query = db.selectOnly(db.entries, distinct: true)
      ..addColumns([db.entries.payee])
      ..where(db.entries.payee.isNotNull() & db.entries.deletedAt.isNull())
      ..orderBy([OrderingTerm.desc(db.entries.occurredAt)])
      ..limit(limit);
    final rows = await query.get();
    return rows.map((r) => r.read(db.entries.payee)).whereType<String>().toList();
  }

  /// Most recently used category ids for [kind], newest first.
  Future<List<String>> recentCategoryIds({required String kind, int limit = 6}) async {
    final query = db.selectOnly(db.entries, distinct: true)
      ..addColumns([db.entries.categoryId])
      ..where(db.entries.categoryId.isNotNull() & db.entries.kind.equals(kind) & db.entries.deletedAt.isNull())
      ..orderBy([OrderingTerm.desc(db.entries.occurredAt)])
      ..limit(limit);
    final rows = await query.get();
    return rows.map((r) => r.read(db.entries.categoryId)).whereType<String>().toList();
  }

  Future<bool> existsForSms(String smsId) async {
    final row = await (db.select(db.entries)..where((t) => t.smsId.equals(smsId))..limit(1)).getSingleOrNull();
    return row != null;
  }

  static EntriesCompanion newExpense({
    required int amountMinor,
    required DateTime occurredAt,
    String? categoryId,
    String? accountId,
    String kind = 'expense',
    String note = '',
    String? payee,
    String source = 'manual',
    String? smsId,
    String? groupId,
    String? paidByMemberId,
    String? splitMethod,
    String? projectId,
    String? id,
  }) =>
      EntriesCompanion.insert(
        id: id ?? newId(),
        kind: kind,
        amountMinor: amountMinor,
        occurredAt: occurredAt,
        categoryId: Value(categoryId),
        accountId: Value(accountId),
        note: Value(note),
        payee: Value(payee),
        source: Value(source),
        smsId: Value(smsId),
        groupId: Value(groupId),
        paidByMemberId: Value(paidByMemberId),
        splitMethod: Value(splitMethod),
        projectId: Value(projectId),
      );
}

/// Groups assignment rows by item, keeping each item's members in row order.
Map<String, List<String>> assignmentsByItem(Iterable<ItemAssignment> rows) {
  final byItem = <String, List<String>>{};
  for (final row in rows) {
    byItem.putIfAbsent(row.entryItemId, () => []).add(row.memberId);
  }
  return byItem;
}

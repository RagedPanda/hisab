import 'package:drift/drift.dart';

import '../../core/dates.dart';
import '../../core/ids.dart';
import '../db/database.dart';

/// An entry with the rows the UI needs alongside it.
class EntryDetails {
  const EntryDetails({
    required this.entry,
    required this.items,
    this.category,
    this.account,
    this.splits = const [],
  });
  final Entry entry;
  final List<EntryItem> items;
  final Category? category;
  final Account? account;
  final List<Split> splits;
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

  Stream<List<EntryDetails>> watchEntries({
    DateRange? range,
    String? groupId,
    bool personalOnly = false,
    String? accountId,
    String? categoryId,
    String? search,
    int? limit,
  }) {
    final query = db.select(db.entries).join([
      leftOuterJoin(db.categories, db.categories.id.equalsExp(db.entries.categoryId)),
      leftOuterJoin(db.accounts, db.accounts.id.equalsExp(db.entries.accountId)),
    ]);
    final conditions = <Expression<bool>>[db.entries.deletedAt.isNull()];
    if (range != null) {
      conditions.add(db.entries.occurredAt.isBiggerOrEqualValue(range.start));
      conditions.add(db.entries.occurredAt.isSmallerThanValue(range.end));
    }
    if (groupId != null) conditions.add(db.entries.groupId.equals(groupId));
    if (personalOnly) conditions.add(db.entries.groupId.isNull());
    if (accountId != null) {
      conditions.add(db.entries.accountId.equals(accountId) | db.entries.toAccountId.equals(accountId));
    }
    if (categoryId != null) conditions.add(db.entries.categoryId.equals(categoryId));
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

    return query.watch().asyncMap((rows) async {
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
            items: items.where((i) => i.entryId == row.readTable(db.entries).id).toList(),
            splits: splits.where((s) => s.entryId == row.readTable(db.entries).id).toList(),
          ),
      ];
    });
  }

  Future<EntryDetails?> getEntry(String id) async {
    final list = await watchEntriesById(id).first;
    return list.isEmpty ? null : list.first;
  }

  Stream<List<EntryDetails>> watchEntriesById(String id) {
    final query = db.select(db.entries).join([
      leftOuterJoin(db.categories, db.categories.id.equalsExp(db.entries.categoryId)),
      leftOuterJoin(db.accounts, db.accounts.id.equalsExp(db.entries.accountId)),
    ])
      ..where(db.entries.id.equals(id));
    return query.watch().asyncMap((rows) async {
      if (rows.isEmpty) return const [];
      final row = rows.first;
      final items = await (db.select(db.entryItems)
            ..where((t) => t.entryId.equals(id) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();
      final splits = await (db.select(db.splits)..where((t) => t.entryId.equals(id) & t.deletedAt.isNull())).get();
      return [
        EntryDetails(
          entry: row.readTable(db.entries),
          category: row.readTableOrNull(db.categories),
          account: row.readTableOrNull(db.accounts),
          items: items,
          splits: splits,
        ),
      ];
    });
  }

  /// Inserts or replaces an entry with its items and splits atomically.
  Future<void> saveEntry(
    EntriesCompanion entry, {
    List<EntryItemsCompanion> items = const [],
    List<SplitsCompanion> splits = const [],
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
    });
  }

  Future<void> deleteEntry(String id) {
    final now = DateTime.now();
    return db.transaction(() async {
      await (db.update(db.entries)..where((t) => t.id.equals(id)))
          .write(EntriesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await (db.update(db.splits)..where((t) => t.entryId.equals(id)))
          .write(SplitsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
    });
  }

  /// Total minor units per category id for expenses (or income) in [range].
  Stream<Map<String, int>> watchCategoryTotals(DateRange range, {String kind = 'expense'}) {
    final sum = db.entries.amountMinor.sum();
    final query = db.selectOnly(db.entries)
      ..addColumns([db.entries.categoryId, sum])
      ..where(db.entries.deletedAt.isNull() &
          db.entries.kind.equals(kind) &
          db.entries.groupId.isNull() &
          db.entries.occurredAt.isBiggerOrEqualValue(range.start) &
          db.entries.occurredAt.isSmallerThanValue(range.end))
      ..groupBy([db.entries.categoryId]);
    return query.watch().map((rows) => {
          for (final row in rows) row.read(db.entries.categoryId) ?? '': row.read(sum) ?? 0,
        });
  }

  /// (expense, income) totals for personal entries in [range].
  Stream<({int expense, int income})> watchTotals(DateRange range) {
    final sum = db.entries.amountMinor.sum();
    final query = db.selectOnly(db.entries)
      ..addColumns([db.entries.kind, sum])
      ..where(db.entries.deletedAt.isNull() &
          db.entries.groupId.isNull() &
          db.entries.occurredAt.isBiggerOrEqualValue(range.start) &
          db.entries.occurredAt.isSmallerThanValue(range.end))
      ..groupBy([db.entries.kind]);
    return query.watch().map((rows) {
      var expense = 0;
      var income = 0;
      for (final row in rows) {
        final kind = row.read(db.entries.kind);
        final total = row.read(sum) ?? 0;
        if (kind == 'expense') expense = total;
        if (kind == 'income') income = total;
      }
      return (expense: expense, income: income);
    });
  }

  /// Expense total per calendar day in [range], keyed by yyyy-mm-dd.
  Stream<Map<DateTime, int>> watchDailyExpense(DateRange range) {
    return watchEntries(range: range, personalOnly: true).map((list) {
      final totals = <DateTime, int>{};
      for (final details in list) {
        if (details.entry.kind != 'expense') continue;
        final day = startOfDay(details.entry.occurredAt);
        totals.update(day, (v) => v + details.entry.amountMinor, ifAbsent: () => details.entry.amountMinor);
      }
      return totals;
    });
  }

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
      );
}

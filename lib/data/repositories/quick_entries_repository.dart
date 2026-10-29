import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../domain/accounts/default_account.dart';
import '../db/database.dart';
import 'entries_repository.dart';
import 'payee_category_repository.dart';

/// The user's quick entries: saved spends shown as one-tap chips on Home.
class QuickEntriesRepository {
  QuickEntriesRepository(this.db);
  final AppDatabase db;

  /// Live quick entries in the user's order.
  Stream<List<QuickEntry>> watchAll() => (db.select(db.quickEntries)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.label)]))
      .watch();

  Future<QuickEntry?> find(String id) =>
      (db.select(db.quickEntries)..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();

  /// Adds a quick entry at the end of the list and returns its id.
  Future<String> add({
    required String label,
    String kind = 'expense',
    int? amountMinor,
    String? categoryId,
    String? accountId,
    String? payee,
    String note = '',
    String tags = '',
  }) async {
    final id = newId();
    final last = await (db.selectOnly(db.quickEntries)
          ..addColumns([db.quickEntries.sortOrder.max()])
          ..where(db.quickEntries.deletedAt.isNull()))
        .map((row) => row.read(db.quickEntries.sortOrder.max()))
        .getSingle();
    await db.into(db.quickEntries).insert(_fields(
          label: label, kind: kind, amountMinor: amountMinor, categoryId: categoryId,
          accountId: accountId, payee: payee, note: note, tags: tags,
        ).copyWith(id: Value(id), sortOrder: Value((last ?? -1) + 1)));
    return id;
  }

  /// Replaces what quick entry [id] adds, keeping its place in the list.
  Future<void> update(
    String id, {
    required String label,
    String kind = 'expense',
    int? amountMinor,
    String? categoryId,
    String? accountId,
    String? payee,
    String note = '',
    String tags = '',
  }) =>
      (db.update(db.quickEntries)..where((t) => t.id.equals(id))).write(_fields(
            label: label, kind: kind, amountMinor: amountMinor, categoryId: categoryId,
            accountId: accountId, payee: payee, note: note, tags: tags,
          ).copyWith(updatedAt: Value(DateTime.now())));

  QuickEntriesCompanion _fields({
    required String label,
    required String kind,
    required int? amountMinor,
    required String? categoryId,
    required String? accountId,
    required String? payee,
    required String note,
    required String tags,
  }) =>
      QuickEntriesCompanion(
        label: Value(label.trim()),
        kind: Value(kind),
        amountMinor: Value(amountMinor),
        categoryId: Value(categoryId),
        accountId: Value(accountId),
        payee: Value(payee),
        note: Value(note),
        tags: Value(tags),
      );

  Future<void> rename(String id, String label) => (db.update(db.quickEntries)..where((t) => t.id.equals(id)))
      .write(QuickEntriesCompanion(label: Value(label.trim()), updatedAt: Value(DateTime.now())));

  /// Soft-deletes so a restore from an older backup does not bring it back.
  Future<void> delete(String id) => (db.update(db.quickEntries)..where((t) => t.id.equals(id)))
      .write(QuickEntriesCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())));

  /// Stores [ids] as the new order.
  Future<void> reorder(List<String> ids) => db.transaction(() async {
        final now = DateTime.now();
        for (final (index, id) in ids.indexed) {
          await (db.update(db.quickEntries)..where((t) => t.id.equals(id)))
              .write(QuickEntriesCompanion(sortOrder: Value(index), updatedAt: Value(now)));
        }
      });
}

/// The entry one tap on [quick] adds at [now] with [id], or null when it has
/// no amount (it opens the editor instead) or there is no account to use.
/// The saved account is used while it is still among [accounts], else the
/// default one; a [category] no longer usable for its kind is left out. Pure.
EntriesCompanion? entryFromQuickEntry(
  QuickEntry quick, {
  required List<Account> accounts,
  required Category? category,
  required String configuredAccountId,
  required DateTime now,
  required String id,
}) {
  final amount = quick.amountMinor;
  if (amount == null || amount <= 0) return null;
  final accountId = accounts.any((account) => account.id == quick.accountId)
      ? quick.accountId
      : defaultEntryAccountId(accounts, configuredId: configuredAccountId);
  if (accountId == null) return null;
  return EntriesRepository.newExpense(
    id: id,
    kind: quick.kind,
    amountMinor: amount,
    occurredAt: now,
    categoryId: isUsablePayeeCategory(category, quick.kind) ? category!.id : null,
    accountId: accountId,
    payee: quick.payee,
    note: quick.note,
  ).copyWith(tags: Value(quick.tags));
}

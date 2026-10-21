import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../db/database.dart';

class AccountsRepository {
  AccountsRepository(this.db);
  final AppDatabase db;

  SimpleSelectStatement<$AccountsTable, Account> _activeQuery() => db.select(db.accounts)
    ..where((t) => t.deletedAt.isNull())
    ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.name)]);

  Stream<List<Account>> watchAll() => _activeQuery().watch();

  Future<List<Account>> getAll() => _activeQuery().get();

  Future<Account?> findBySmsKey(String key) =>
      (db.select(db.accounts)..where((t) => t.smsKey.equals(key) & t.deletedAt.isNull())).getSingleOrNull();

  Future<Account> create({
    required String name,
    required String type,
    required int color,
    String? bankName,
    String? last4,
    String? smsKey,
    int balanceMinor = 0,
    bool includeInTotal = true,
  }) async {
    final companion = AccountsCompanion.insert(
      id: newId(),
      name: name,
      type: type,
      color: color,
      bankName: Value(bankName),
      last4: Value(last4),
      smsKey: Value(smsKey),
      balanceMinor: Value(balanceMinor),
      balanceAsOf: Value(balanceMinor == 0 ? null : DateTime.now()),
      includeInTotal: Value(includeInTotal),
    );
    await db.into(db.accounts).insert(companion);
    return (db.select(db.accounts)..where((t) => t.id.equals(companion.id.value))).getSingle();
  }

  Future<void> update(AccountsCompanion account) =>
      (db.update(db.accounts)..where((t) => t.id.equals(account.id.value)))
          .write(account.copyWith(updatedAt: Value(DateTime.now())));

  Future<void> delete(String id) => (db.update(db.accounts)..where((t) => t.id.equals(id)))
      .write(AccountsCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())));

  /// Records the balance a bank SMS reported, if newer than what we have.
  Future<void> applyReportedBalance(String id, int balanceMinor, DateTime asOf) async {
    final current = await (db.select(db.accounts)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (current == null) return;
    if (current.balanceAsOf != null && current.balanceAsOf!.isAfter(asOf)) return;
    await update(AccountsCompanion(id: Value(id), balanceMinor: Value(balanceMinor), balanceAsOf: Value(asOf)));
  }

  /// Moves the running balance for a manual entry; SMS entries carry the
  /// bank's own balance instead so they do not adjust it twice.
  Future<void> adjustBalance(String id, int deltaMinor) async {
    final current = await (db.select(db.accounts)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (current == null) return;
    await update(AccountsCompanion(id: Value(id), balanceMinor: Value(current.balanceMinor + deltaMinor)));
  }

  /// Applies a set of account deltas (see `lib/domain/ledger`) atomically.
  Future<void> applyBalanceDeltas(Map<String, int> deltas) async {
    if (deltas.isEmpty) return;
    await db.transaction(() async {
      for (final delta in deltas.entries) {
        await adjustBalance(delta.key, delta.value);
      }
    });
  }
}

import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../db/database.dart';

class BudgetsRepository {
  BudgetsRepository(this.db);
  final AppDatabase db;

  Stream<List<Budget>> watchAll() => (db.select(db.budgets)..where((t) => t.deletedAt.isNull())).watch();

  Future<void> save({String? id, String? categoryId, required String period, required int amountMinor}) =>
      db.into(db.budgets).insertOnConflictUpdate(BudgetsCompanion.insert(
            id: id ?? newId(),
            categoryId: Value(categoryId),
            period: Value(period),
            amountMinor: amountMinor,
            updatedAt: Value(DateTime.now()),
          ));

  Future<void> delete(String id) => (db.update(db.budgets)..where((t) => t.id.equals(id)))
      .write(BudgetsCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())));

  /// Reverses a soft delete (undo from the snackbar).
  Future<void> restore(String id) => (db.update(db.budgets)..where((t) => t.id.equals(id)))
      .write(BudgetsCompanion(deletedAt: const Value(null), updatedAt: Value(DateTime.now())));
}

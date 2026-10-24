import 'package:drift/drift.dart';

import '../../domain/sms/payee_category_memory.dart';
import '../../domain/sms/payee_normaliser.dart';
import '../db/database.dart';

/// Stores the category the user chose for an SMS payee (see
/// `domain/sms/payee_category_memory.dart` for the keys).
class PayeeCategoryRepository {
  PayeeCategoryRepository(this.db);
  final AppDatabase db;

  SimpleSelectStatement<$PayeeCategoriesTable, PayeeCategory> _live() =>
      db.select(db.payeeCategories)..where((t) => t.deletedAt.isNull());

  /// Every remembered payee, by readable name.
  Stream<List<PayeeCategory>> watchAll() => (_live()..orderBy([(t) => OrderingTerm.asc(t.payee)])).watch();

  /// Live rows as row id -> category id, for [rememberedCategoryId].
  Stream<Map<String, String>> watchMemory() => _live().watch().map(_asMemory);

  /// The rows [raw] could match on the [kind] side, as row id -> category id.
  Future<Map<String, String>> memoryFor({required String kind, required String? raw}) async {
    final ids = payeeMemoryRowIds(kind, raw);
    if (ids.isEmpty) return const {};
    return _asMemory(await (_live()..where((t) => t.id.isIn(ids))).get());
  }

  /// The category remembered for [raw] on the [kind] side, if any.
  Future<String?> categoryIdFor({required String kind, required String? raw}) async =>
      rememberedCategoryId(await memoryFor(kind: kind, raw: raw), kind: kind, raw: raw);

  /// Remembers [categoryId] for [raw] on the [kind] side, replacing an older
  /// choice (or a deleted one). Does nothing when the SMS named no payee.
  Future<void> remember({required String kind, required String? raw, required String categoryId}) async {
    final key = payeeMemoryKey(raw);
    if (key == null) return;
    await db.into(db.payeeCategories).insertOnConflictUpdate(PayeeCategoriesCompanion.insert(
          id: payeeMemoryRowId(kind, key),
          payee: normalisePayee(raw!),
          categoryId: categoryId,
          updatedAt: Value(DateTime.now()),
          deletedAt: const Value(null),
        ));
  }

  /// Forgets one remembered payee; later SMS from it use the keyword rules.
  Future<void> forget(String id) => (db.update(db.payeeCategories)..where((t) => t.id.equals(id)))
      .write(PayeeCategoriesCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())));

  static Map<String, String> _asMemory(List<PayeeCategory> rows) => {for (final row in rows) row.id: row.categoryId};
}

/// Whether a remembered [category] can still be applied to a [kind] entry:
/// it exists, is not archived, and is of the same kind.
bool isUsablePayeeCategory(Category? category, String kind) =>
    category != null && category.deletedAt == null && !category.isArchived && category.kind == kind;

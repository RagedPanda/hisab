import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../db/database.dart';

/// A parent category with its children, as shown in pickers.
class CategoryNode {
  const CategoryNode(this.category, this.children);
  final Category category;
  final List<Category> children;
}

List<CategoryNode> buildCategoryTree(List<Category> flat, {String? kind}) {
  final parents = flat.where((c) => c.parentId == null && (kind == null || c.kind == kind)).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return [
    for (final parent in parents)
      CategoryNode(
        parent,
        flat.where((c) => c.parentId == parent.id).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      ),
  ];
}

class CategoriesRepository {
  CategoriesRepository(this.db);
  final AppDatabase db;

  Stream<List<Category>> watchAll({bool includeArchived = false}) => (db.select(db.categories)
        ..where((t) => includeArchived ? t.deletedAt.isNull() : t.deletedAt.isNull() & t.isArchived.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .watch();

  Future<List<Category>> getAll() => watchAll().first;

  Future<Category?> findBySeedKey(String key) =>
      (db.select(db.categories)..where((t) => t.seedKey.equals(key) & t.deletedAt.isNull())).getSingleOrNull();

  Future<Category?> byId(String id) => (db.select(db.categories)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<String> create({
    required String name,
    required String icon,
    required int color,
    required String kind,
    String? parentId,
    String units = '',
  }) async {
    final maxOrder = await _maxSortOrder();
    final id = newId();
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: id,
          name: name,
          icon: icon,
          color: color,
          kind: kind,
          parentId: Value(parentId),
          sortOrder: Value(maxOrder + 1),
          units: Value(units),
        ));
    return id;
  }

  Future<void> update(CategoriesCompanion category) =>
      (db.update(db.categories)..where((t) => t.id.equals(category.id.value)))
          .write(category.copyWith(updatedAt: Value(DateTime.now())));

  Future<void> setArchived(String id, bool archived) =>
      update(CategoriesCompanion(id: Value(id), isArchived: Value(archived)));

  /// Deletes a category; entries that used it keep working (category shown as "Uncategorised").
  Future<void> delete(String id) => db.transaction(() async {
        final now = DateTime.now();
        await (db.update(db.categories)..where((t) => t.id.equals(id) | t.parentId.equals(id)))
            .write(CategoriesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      });

  Future<void> reorder(List<String> idsInOrder) => db.transaction(() async {
        for (var i = 0; i < idsInOrder.length; i++) {
          await update(CategoriesCompanion(id: Value(idsInOrder[i]), sortOrder: Value(i)));
        }
      });

  Future<int> _maxSortOrder() async {
    final max = db.categories.sortOrder.max();
    final row = await (db.selectOnly(db.categories)..addColumns([max])).getSingle();
    return row.read(max) ?? 0;
  }
}

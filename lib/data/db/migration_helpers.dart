import 'package:drift/drift.dart';

/// Idempotent schema steps. Each one checks what the file already has, so an
/// upgrade works whatever path the database took to get here (branches that
/// shipped the same version number with different steps, renumbered steps).

/// The columns of [wanted] not in [existingNames]. Pure.
List<GeneratedColumn> missingColumns(Set<String> existingNames, List<GeneratedColumn> wanted) =>
    [for (final column in wanted) if (!existingNames.contains(column.name)) column];

/// Whether sqlite_master has an object of [type] ('table' or 'index') named [name].
Future<bool> schemaObjectExists(GeneratedDatabase db, String type, String name) async {
  final rows = await db.customSelect('SELECT 1 FROM sqlite_master WHERE type = ? AND name = ?', variables: [Variable(type), Variable(name)]).get();
  return rows.isNotEmpty;
}

/// Column names of [tableName] as stored in the file.
Future<Set<String>> storedColumnNames(GeneratedDatabase db, String tableName) async {
  final rows = await db.customSelect('PRAGMA table_info("$tableName")').get();
  return {for (final row in rows) row.read<String>('name')};
}

/// Creates [table] unless it exists.
Future<void> ensureTable(Migrator m, GeneratedDatabase db, TableInfo table) async {
  if (!await schemaObjectExists(db, 'table', table.actualTableName)) await m.createTable(table);
}

/// Adds whichever of [columns] [table] lacks.
Future<void> ensureColumns(Migrator m, GeneratedDatabase db, TableInfo table, List<GeneratedColumn> columns) async {
  final existing = await storedColumnNames(db, table.actualTableName);
  for (final column in missingColumns(existing, columns)) {
    await m.addColumn(table, column);
  }
}

/// Creates [index] unless it exists.
Future<void> ensureIndex(Migrator m, GeneratedDatabase db, Index index) async {
  if (!await schemaObjectExists(db, 'index', index.entityName)) await m.createIndex(index);
}

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';

/// Rewinds a freshly created database to the schema shipped at version 1 so
/// the upgrade path runs against a real file, the way an installed app sees it.
Future<void> rewindToVersion1(File file) async {
  final db = AppDatabase(NativeDatabase(file));
  await db.customStatement('DROP INDEX IF EXISTS entries_project_id');
  await db.customStatement('ALTER TABLE entries DROP COLUMN project_id');
  await db.customStatement('ALTER TABLE groups DROP COLUMN project_id');
  await db.customStatement('ALTER TABLE categories DROP COLUMN pack_key');
  await db.customStatement('DROP TABLE projects');
  await db.customStatement('PRAGMA user_version = 1');
  await db.close();
}

void main() {
  late Directory tempDir;
  late File file;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hisab_migration');
    file = File('${tempDir.path}/hisab.db');
  });

  tearDown(() => tempDir.delete(recursive: true));

  test('upgrading from schema 1 adds projects, project links and pack keys', () async {
    await rewindToVersion1(file);

    final db = AppDatabase(NativeDatabase(file));
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data['user_version'], db.schemaVersion);

    final projectId = newId();
    await db.into(db.projects).insert(ProjectsCompanion.insert(id: projectId, name: 'Scotty', color: 0xFF1E88E5));
    final entryId = newId();
    await EntriesRepository(db).saveEntry(EntriesRepository.newExpense(id: entryId, amountMinor: 50000, occurredAt: DateTime(2026, 10, 5), projectId: projectId));
    final entry = await (db.select(db.entries)..where((t) => t.id.equals(entryId))).getSingle();
    expect(entry.projectId, projectId);

    await (db.update(db.categories)..where((t) => t.seedKey.equals('fuel'))).write(const CategoriesCompanion(packKey: Value('vehicle')));
    final packed = await (db.select(db.categories)..where((t) => t.packKey.equals('vehicle'))).get();
    expect(packed, hasLength(1));

    final seeded = await db.select(db.categories).get();
    expect(seeded.where((c) => c.seedKey == 'fuel'), hasLength(1), reason: 'seeded rows survive the upgrade');
    await db.close();
  });
}

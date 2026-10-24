import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/backup/backup_service.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';

/// #91: a newer backup row is written whole, so its nulls clear local values.
void main() {
  late AppDatabase db;
  final localEdit = DateTime(2026, 10, 20);

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<Entry> rowById(String id) => (db.select(db.entries)..where((t) => t.id.equals(id))).getSingle();

  /// A local expense that was deleted and given a payee at [localEdit].
  Future<Entry> seedDeletedLunch() async {
    await db.into(db.entries).insert(
          EntriesRepository.newExpense(id: 'lunch', amountMinor: 30000, occurredAt: DateTime(2026, 10, 19), note: 'Lunch')
              .copyWith(payee: const Value('Cafe'), deletedAt: Value(localEdit), updatedAt: Value(localEdit)),
        );
    return rowById('lunch');
  }

  Future<int> restoreRow(Entry backupRow) => BackupService(db).importSnapshot({
        'app': 'hisab',
        'entries': [backupRow.toJson()],
      });

  test('a newer backup row with deletedAt null undeletes the local row', () async {
    final local = await seedDeletedLunch();
    final written = await restoreRow(local.copyWith(deletedAt: const Value(null), updatedAt: localEdit.add(const Duration(days: 1))));
    expect(written, 1);
    expect((await rowById('lunch')).deletedAt, isNull);
  });

  test('an older backup row leaves the local deletion alone', () async {
    final local = await seedDeletedLunch();
    final written = await restoreRow(local.copyWith(deletedAt: const Value(null), updatedAt: localEdit.subtract(const Duration(days: 1))));
    expect(written, 0);
    expect((await rowById('lunch')).deletedAt, localEdit);
  });

  test('a newer backup row with a null payee clears it, and an empty note replaces the old one', () async {
    final local = await seedDeletedLunch();
    await restoreRow(local.copyWith(payee: const Value(null), note: '', updatedAt: localEdit.add(const Duration(days: 1))));
    final restored = await rowById('lunch');
    expect(restored.payee, isNull);
    expect(restored.note, '');
    expect(restored.amountMinor, 30000, reason: 'columns the backup carries unchanged stay as they were');
  });
}

import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';

/// Undoes the v10 step (group activity log) on a database created at the
/// current schema, so older rewinds start from v8.
Future<void> dropVersion10(AppDatabase db) async {
  await db.customStatement('DROP TABLE group_activities');
}

/// Undoes the v8 step (sms_log.cleared_at) on a database created at the
/// current schema, so older rewinds start from v7.
Future<void> dropVersion8(AppDatabase db) async {
  await db.customStatement('ALTER TABLE sms_log DROP COLUMN cleared_at');
}

/// Undoes the v7 step (recurring rules, entries.recurring_id) on a database
/// created at the current schema, so older rewinds start from v6.
Future<void> dropVersion7(AppDatabase db) async {
  await db.customStatement('DROP TABLE recurring_rules');
  await db.customStatement('DROP INDEX IF EXISTS entries_recurring_id');
  await db.customStatement('ALTER TABLE entries DROP COLUMN recurring_id');
}

/// Rewinds a freshly created database to the schema shipped at version 1 so
/// the upgrade path runs against a real file, the way an installed app sees it.
Future<void> rewindToVersion1(File file) async {
  final db = AppDatabase(NativeDatabase(file));
  await dropVersion10(db);
  await dropVersion8(db);
  await dropVersion7(db);
  await db.customStatement('DROP TABLE entry_payers');
  await db.customStatement('DROP TABLE reminders');
  await db.customStatement('ALTER TABLE members DROP COLUMN upi_id');
  await db.customStatement('DROP TABLE project_fields');
  await db.customStatement('DROP TABLE entry_field_values');
  await db.customStatement('ALTER TABLE settlements DROP COLUMN method');
  await db.customStatement('DROP INDEX IF EXISTS entries_project_id');
  await db.customStatement('ALTER TABLE entries DROP COLUMN project_id');
  await db.customStatement('ALTER TABLE groups DROP COLUMN project_id');
  await db.customStatement('ALTER TABLE categories DROP COLUMN pack_key');
  await db.customStatement('DROP TABLE projects');
  await db.customStatement('PRAGMA user_version = 1');
  await db.close();
}

/// Rewinds a freshly created database to the schema shipped at version 2
/// (projects, but no payment method on settlements).
Future<void> rewindToVersion2(File file) async {
  final db = AppDatabase(NativeDatabase(file));
  await dropVersion10(db);
  await dropVersion8(db);
  await dropVersion7(db);
  await db.customStatement('DROP TABLE entry_payers');
  await db.customStatement('DROP TABLE reminders');
  await db.customStatement('ALTER TABLE members DROP COLUMN upi_id');
  await db.customStatement('DROP TABLE project_fields');
  await db.customStatement('DROP TABLE entry_field_values');
  await db.customStatement('ALTER TABLE settlements DROP COLUMN method');
  await db.customStatement('PRAGMA user_version = 2');
  await db.close();
}

/// Rewinds a freshly created database to the schema shipped at version 3
/// (no project fields yet).
Future<void> rewindToVersion3(File file) async {
  final db = AppDatabase(NativeDatabase(file));
  await dropVersion10(db);
  await dropVersion8(db);
  await dropVersion7(db);
  await db.customStatement('DROP TABLE entry_payers');
  await db.customStatement('DROP TABLE reminders');
  await db.customStatement('ALTER TABLE members DROP COLUMN upi_id');
  await db.customStatement('DROP TABLE project_fields');
  await db.customStatement('DROP TABLE entry_field_values');
  await db.customStatement('PRAGMA user_version = 3');
  await db.close();
}

/// Rewinds a freshly created database to the schema shipped at version 4
/// (no member UPI IDs, no reminders).
Future<void> rewindToVersion4(File file) async {
  final db = AppDatabase(NativeDatabase(file));
  await dropVersion10(db);
  await dropVersion8(db);
  await dropVersion7(db);
  await db.customStatement('DROP TABLE entry_payers');
  await db.customStatement('DROP TABLE reminders');
  await db.customStatement('ALTER TABLE members DROP COLUMN upi_id');
  await db.customStatement('PRAGMA user_version = 4');
  await db.close();
}

/// Rewinds a freshly created database to the schema shipped at version 5
/// (reminders and UPI IDs, but only one payer per expense and no recurring
/// rules).
Future<void> rewindToVersion5(File file) async {
  final db = AppDatabase(NativeDatabase(file));
  await dropVersion10(db);
  await dropVersion8(db);
  await dropVersion7(db);
  await db.customStatement('DROP TABLE entry_payers');
  await db.customStatement('PRAGMA user_version = 5');
  await db.close();
}

/// Rewinds a freshly created database to the schema shipped at version 6
/// (entry payers, but no recurring rules).
Future<void> rewindToVersion6(File file) async {
  final db = AppDatabase(NativeDatabase(file));
  await dropVersion10(db);
  await dropVersion8(db);
  await dropVersion7(db);
  await db.customStatement('PRAGMA user_version = 6');
  await db.close();
}

/// Rewinds a freshly created database to the schema shipped at version 7
/// (recurring rules, but SMS history could not be cleared).
Future<void> rewindToVersion7(File file) async {
  final db = AppDatabase(NativeDatabase(file));
  await dropVersion10(db);
  await dropVersion8(db);
  await db.customStatement('PRAGMA user_version = 7');
  await db.close();
}

/// Rewinds a freshly created database to the schema shipped at version 8
/// (SMS history clearing, but no group activity log).
Future<void> rewindToVersion8(File file) async {
  final db = AppDatabase(NativeDatabase(file));
  await dropVersion10(db);
  await db.customStatement('PRAGMA user_version = 8');
  await db.close();
}

void main() {
  // The schema-equality test opens a second, independent in-memory database.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

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

  test('upgrading from schema 2 adds the payment method with cash as the default', () async {
    final seed = AppDatabase(NativeDatabase(file));
    await seed.into(seed.groups).insert(GroupsCompanion.insert(id: 'g1', name: 'Goa'));
    await seed.into(seed.members).insert(MembersCompanion.insert(id: 'm1', groupId: 'g1', name: 'Me'));
    await seed.into(seed.members).insert(MembersCompanion.insert(id: 'm2', groupId: 'g1', name: 'Rahul'));
    await seed.into(seed.settlements).insert(SettlementsCompanion.insert(id: 's1', groupId: 'g1', fromMemberId: 'm2', toMemberId: 'm1', amountMinor: 500, occurredAt: DateTime(2026, 10, 5)));
    await seed.close();
    await rewindToVersion2(file);

    final db = AppDatabase(NativeDatabase(file));
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data['user_version'], db.schemaVersion);
    final settlement = await db.select(db.settlements).getSingle();
    expect(settlement.method, 'cash');
    expect(settlement.amountMinor, 500);
    await db.close();
  });

  test('upgrading from schema 3 adds project fields and entry field values', () async {
    final seed = AppDatabase(NativeDatabase(file));
    await seed.into(seed.projects).insert(ProjectsCompanion.insert(id: 'p1', name: 'Scotty', color: 0xFF1E88E5));
    await seed.close();
    await rewindToVersion3(file);

    final db = AppDatabase(NativeDatabase(file));
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data['user_version'], db.schemaVersion);
    await db.into(db.projectFields).insert(ProjectFieldsCompanion.insert(id: 'f1', projectId: 'p1', key: 'odometer', type: 'number'));
    await db.into(db.entryFieldValues).insert(EntryFieldValuesCompanion.insert(id: 'v1', entryId: 'e1', fieldKey: 'odometer', numberValue: const Value(1200)));
    final field = await db.select(db.projectFields).getSingle();
    expect(field.scope, 'entry');
    expect(field.choices, '[]');
    expect((await db.select(db.entryFieldValues).getSingle()).numberValue, 1200);
    expect((await db.select(db.projects).getSingle()).name, 'Scotty', reason: 'existing rows survive the upgrade');
    await db.close();
  });

  test('upgrading from schema 8 adds the group activity log and keeps expenses', () async {
    final seed = AppDatabase(NativeDatabase(file));
    await seed.into(seed.entries).insert(EntriesRepository.newExpense(id: 'e1', amountMinor: 90000, occurredAt: DateTime(2026, 10, 20), groupId: 'g1', paidByMemberId: 'm1', splitMethod: 'equal'));
    await seed.close();
    await rewindToVersion8(file);

    final db = AppDatabase(NativeDatabase(file));
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data['user_version'], db.schemaVersion);
    expect((await db.select(db.entries).getSingle()).id, 'e1', reason: 'existing rows survive the upgrade');
    await db.into(db.groupActivities).insert(GroupActivitiesCompanion.insert(id: 'a1', groupId: 'g1', action: 'added', subjectKind: 'expense', subjectId: 'e1', occurredAt: DateTime(2026, 10, 20)));
    final activity = await db.select(db.groupActivities).getSingle();
    expect(activity.beforeJson, isNull);
    expect(activity.deletedAt, isNull);
    await db.close();
  });

  test('upgrading from schema 5 adds the entry payers table and keeps single payers', () async {
    final seed = AppDatabase(NativeDatabase(file));
    await seed.into(seed.entries).insert(EntriesRepository.newExpense(id: 'e1', amountMinor: 90000, occurredAt: DateTime(2026, 10, 20), groupId: 'g1', paidByMemberId: 'm1', splitMethod: 'equal'));
    await seed.close();
    await rewindToVersion5(file);

    final db = AppDatabase(NativeDatabase(file));
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data['user_version'], db.schemaVersion);
    expect((await db.select(db.entries).getSingle()).paidByMemberId, 'm1', reason: 'existing single-payer rows keep their payer');
    await db.into(db.entryPayers).insert(EntryPayersCompanion.insert(id: 'p1', entryId: 'e1', memberId: 'm2', amountMinor: 30000));
    expect((await db.select(db.entryPayers).getSingle()).amountMinor, 30000);
    await db.close();
  });

  test('upgrading from schema 4 adds member UPI IDs and the reminders table', () async {
    final seed = AppDatabase(NativeDatabase(file));
    await seed.into(seed.members).insert(MembersCompanion.insert(id: 'm1', groupId: 'g1', name: 'Rahul', phone: const Value('98100 00000')));
    await seed.close();
    await rewindToVersion4(file);

    final db = AppDatabase(NativeDatabase(file));
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data['user_version'], db.schemaVersion);
    final member = await db.select(db.members).getSingle();
    expect(member.upiId, isNull);
    expect(member.phone, '98100 00000', reason: 'existing rows survive the upgrade');
    await db.into(db.reminders).insert(RemindersCompanion.insert(id: 'r1', kind: 'settle_up', groupId: const Value('g1'), memberId: const Value('m1'), sentAt: Value(DateTime(2026, 10, 20))));
    final reminder = await db.select(db.reminders).getSingle();
    expect(reminder.channel, 'share');
    expect(reminder.message, '');
    expect(reminder.doneAt, isNull);
    await db.close();
  });

  for (final (from, rewind) in [(5, rewindToVersion5), (6, rewindToVersion6)]) {
    test('upgrading from schema $from adds recurring rules and the entry link', () async {
      final seed = AppDatabase(NativeDatabase(file));
      await EntriesRepository(seed).saveEntry(EntriesRepository.newExpense(id: 'e1', amountMinor: 1500000, occurredAt: DateTime(2026, 10, 5)));
      await seed.close();
      await rewind(file);

      final db = AppDatabase(NativeDatabase(file));
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data['user_version'], db.schemaVersion);
      final entry = await db.select(db.entries).getSingle();
      expect(entry.recurringId, isNull);
      expect(entry.amountMinor, 1500000, reason: 'existing rows survive the upgrade');
      expect(await db.select(db.entryPayers).get(), isA<List<EntryPayer>>(), reason: 'the v6 payers table is there after both paths');
      await db.into(db.recurringRules).insert(RecurringRulesCompanion.insert(id: 'r1', kind: 'expense', amountMinor: 1500000, frequency: 'monthly', startDate: DateTime(2026, 10, 5)));
      final rule = await db.select(db.recurringRules).getSingle();
      expect(rule.interval, 1);
      expect(rule.autoPost, isTrue);
      expect(rule.status, 'active');
      expect(rule.postedCount, 0);
      expect(rule.isSubscription, isFalse);
      await (db.update(db.entries)..where((t) => t.id.equals('e1'))).write(const EntriesCompanion(recurringId: Value('r1')));
      expect((await db.select(db.entries).getSingle()).recurringId, 'r1');
      await db.close();
    });
  }

  for (final (from, rewind) in [(5, rewindToVersion5), (6, rewindToVersion6), (7, rewindToVersion7)]) {
    test('upgrading from schema $from adds the SMS history cleared marker', () async {
      final seed = AppDatabase(NativeDatabase(file));
      await seed.into(seed.smsLog).insert(SmsLogCompanion.insert(id: 's1', sender: 'HDFCBK', body: 'Rs.10 debited', receivedAt: DateTime(2026, 10, 20), status: 'added'));
      await seed.close();
      await rewind(file);

      final db = AppDatabase(NativeDatabase(file));
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data['user_version'], db.schemaVersion);
      final row = await db.select(db.smsLog).getSingle();
      expect(row.clearedAt, isNull);
      expect(row.body, 'Rs.10 debited', reason: 'existing rows survive the upgrade');
      await db.close();
    });
  }

  // Opens a real v1 database (schema dumped from the shipped app into
  // `fixtures/schema_v1.sql`) with a few rows, then lets [AppDatabase] run
  // onUpgrade so every step runs on existing data, not on createAll().

  // The schema-equality test opens a second, independent in-memory database.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('from the v1 schema dump', () {
    late AppDatabase db;

    setUp(() async {
      final fixture = File('test/data/fixtures/schema_v1.sql').readAsLinesSync().where((line) => line.trim().isNotEmpty);
      // `setup` runs on the raw sqlite handle before drift reads user_version,
      // so the app opens what looks like a database written by the v1 build.
      final executor = NativeDatabase.memory(
        setup: (raw) {
          for (final statement in fixture) {
            raw.execute(statement);
          }
          raw.execute("INSERT INTO groups (id, name) VALUES ('g1', 'Goa')");
          raw.execute("INSERT INTO members (id, group_id, name, is_me) VALUES ('m1', 'g1', 'Me', 1), ('m2', 'g1', 'Rahul', 0)");
          raw.execute("INSERT INTO settlements (id, group_id, from_member_id, to_member_id, amount_minor, occurred_at) VALUES ('s1', 'g1', 'm2', 'm1', 500, 1760000000)");
          raw.execute('PRAGMA user_version = 1');
        },
      );
      db = AppDatabase(executor);
    });

    tearDown(() => db.close());

    test('v1 rows survive the upgrade and new columns carry their defaults', () async {
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), db.schemaVersion);

      final settlement = await db.select(db.settlements).getSingle();
      expect(settlement.method, 'cash');
      expect(settlement.amountMinor, 500);
      expect((await db.select(db.members).get()).map((member) => member.name), ['Me', 'Rahul']);
    });

    test('a fresh database and an upgraded one end with the same tables and columns', () async {
      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      Future<Map<String, String>> schemaOf(AppDatabase database) async {
        final rows = await database.customSelect("SELECT name, sql FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'").get();
        return {for (final row in rows) row.read<String>('name'): _columnsOf(row.read<String>('sql'))};
      }

      final upgraded = await schemaOf(db);
      final created = await schemaOf(fresh);
      expect(upgraded.keys.toSet(), created.keys.toSet());
      for (final table in created.keys) {
        expect(upgraded[table], created[table], reason: 'columns of $table differ after migration');
      }
    });
  });
}

/// Column names in a CREATE TABLE statement, sorted so column order does not matter.
String _columnsOf(String sql) {
  final body = sql.substring(sql.indexOf('(') + 1);
  final names = RegExp(r'"([a-z_]+)"\s+(TEXT|INTEGER|REAL|BLOB)').allMatches(body).map((match) => match.group(1)!).toList()..sort();
  return names.join(',');
}

import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';

/// Undoes the v13 step (project link, document number, preset key and the
/// project index on reminders) on a database created at the current schema,
/// so older rewinds start from v12.
Future<void> dropVersion13(AppDatabase db) async {
  await db.customStatement('DROP INDEX reminders_project_id');
  for (final column in documentReminderColumns(db.reminders)) {
    await db.customStatement('ALTER TABLE reminders DROP COLUMN ${column.name}');
  }
}

/// Undoes the v12 step (due-reminder columns and their index on reminders)
/// on a database created at the current schema, so older rewinds start from v11.
Future<void> dropVersion12(AppDatabase db) async {
  await db.customStatement('DROP INDEX reminders_status_due');
  for (final column in dueReminderColumns(db.reminders)) {
    await db.customStatement('ALTER TABLE reminders DROP COLUMN ${column.name}');
  }
}

/// Undoes the v11 step (group settings columns) on a database created at
/// the current schema, so older rewinds start from v10.
Future<void> dropVersion11(AppDatabase db) async {
  for (final column in ['type', 'default_split_method', 'notes', 'currency_label', 'archived_at']) {
    await db.customStatement('ALTER TABLE "groups" DROP COLUMN $column');
  }
}

/// Undoes the v10 step (group activity log) on a database created at the
/// current schema, so older rewinds start from v8 (v9 was never shipped).
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
  await dropVersion13(db);
  await dropVersion12(db);
  await dropVersion11(db);
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
  await dropVersion13(db);
  await dropVersion12(db);
  await dropVersion11(db);
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
  await dropVersion13(db);
  await dropVersion12(db);
  await dropVersion11(db);
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
  await dropVersion13(db);
  await dropVersion12(db);
  await dropVersion11(db);
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
  await dropVersion13(db);
  await dropVersion12(db);
  await dropVersion11(db);
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
  await dropVersion13(db);
  await dropVersion12(db);
  await dropVersion11(db);
  await dropVersion10(db);
  await dropVersion8(db);
  await dropVersion7(db);
  await db.customStatement('PRAGMA user_version = 6');
  await db.close();
}

/// Rewinds a freshly created database to the schema of pre-release builds of
/// the reminders feature, which stored the due-reminder columns under
/// schema 6 without main's v6 entry_payers, v7 and v8 steps.
Future<void> rewindToPreReleaseRemindersVersion6(File file) async {
  final db = AppDatabase(NativeDatabase(file));
  await dropVersion13(db);
  await dropVersion11(db);
  await dropVersion10(db);
  await dropVersion8(db);
  await dropVersion7(db);
  await db.customStatement('DROP TABLE entry_payers');
  await db.customStatement('PRAGMA user_version = 6');
  await db.close();
}

/// Rewinds a freshly created database to the schema shipped at version 7
/// (recurring rules, but SMS history could not be cleared).
Future<void> rewindToVersion7(File file) async {
  final db = AppDatabase(NativeDatabase(file));
  await dropVersion13(db);
  await dropVersion12(db);
  await dropVersion11(db);
  await dropVersion10(db);
  await dropVersion8(db);
  await db.customStatement('PRAGMA user_version = 7');
  await db.close();
}

/// Rewinds a freshly created database to the schema shipped at version 8
/// (SMS history clearing, but no group activity log and no due-reminder columns).
Future<void> rewindToVersion8(File file) async {
  final db = AppDatabase(NativeDatabase(file));
  await dropVersion13(db);
  await dropVersion12(db);
  await dropVersion11(db);
  await dropVersion10(db);
  await db.customStatement('PRAGMA user_version = 8');
  await db.close();
}

/// Rewinds a freshly created database to the schema shipped at version 10
/// (group activity log, but no group settings and no due-reminder columns).
Future<void> rewindToVersion10(File file) async {
  final db = AppDatabase(NativeDatabase(file));
  await dropVersion13(db);
  await dropVersion12(db);
  await dropVersion11(db);
  await db.customStatement('PRAGMA user_version = 10');
  await db.close();
}

/// Rewinds a freshly created database to the schema shipped at version 11
/// (group settings, but no due-reminder columns).
Future<void> rewindToVersion11(File file) async {
  final db = AppDatabase(NativeDatabase(file));
  await dropVersion13(db);
  await dropVersion12(db);
  await db.customStatement('PRAGMA user_version = 11');
  await db.close();
}

/// Rewinds a freshly created database to the schema of #28 QA builds, which
/// added the due-reminder columns as schema 9 before v10 existed.
Future<void> rewindToRemindersQaVersion9(File file) async {
  final db = AppDatabase(NativeDatabase(file));
  await dropVersion13(db);
  await dropVersion11(db);
  await dropVersion10(db);
  await db.customStatement('PRAGMA user_version = 9');
  await db.close();
}

/// Rewinds a freshly created database to the schema shipped at version 12
/// (due reminders, but no project link or document number).
Future<void> rewindToVersion12(File file) async {
  final db = AppDatabase(NativeDatabase(file));
  await dropVersion13(db);
  await db.customStatement('PRAGMA user_version = 12');
  await db.close();
}

/// Rewinds a freshly created database to the schema of pre-release builds of
/// document reminders, which stored the project link and document number
/// under schema 7 without main's v7, v8, v10 and v11 steps.
Future<void> rewindToDocumentRemindersPreReleaseVersion7(File file) async {
  final db = AppDatabase(NativeDatabase(file));
  await dropVersion11(db);
  await dropVersion10(db);
  await dropVersion8(db);
  await dropVersion7(db);
  await db.customStatement('PRAGMA user_version = 7');
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

  test('upgrading from schema 10 adds group settings with defaults that keep today\'s behaviour', () async {
    final seed = AppDatabase(NativeDatabase(file));
    await seed.into(seed.groups).insert(GroupsCompanion.insert(id: 'g1', name: 'Goa', simplifyDebts: const Value(false)));
    await seed.close();
    await rewindToVersion10(file);

    final db = AppDatabase(NativeDatabase(file));
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data['user_version'], db.schemaVersion);
    final group = await db.select(db.groups).getSingle();
    expect((group.type, group.defaultSplitMethod, group.notes, group.currencyLabel, group.archivedAt), ('other', 'equal', '', null, null));
    expect((group.name, group.simplifyDebts), ('Goa', false), reason: 'existing rows survive the upgrade');
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

  for (final (from, rewind) in [(5, rewindToVersion5), (6, rewindToVersion6), (7, rewindToVersion7), (8, rewindToVersion8), (10, rewindToVersion10), (11, rewindToVersion11)]) {
    test('upgrading from schema $from adds due-reminder columns and keeps settle-up rows', () async {
      final seed = AppDatabase(NativeDatabase(file));
      await seed.into(seed.reminders).insert(RemindersCompanion.insert(id: 'r1', kind: 'settle_up', groupId: const Value('g1'), memberId: const Value('m1'), sentAt: Value(DateTime(2026, 10, 20)), message: const Value('Pay me back')));
      await seed.close();
      await rewind(file);

      final db = AppDatabase(NativeDatabase(file));
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data['user_version'], db.schemaVersion);
      final settleUp = await db.select(db.reminders).getSingle();
      expect(settleUp.kind, 'settle_up');
      expect(settleUp.groupId, 'g1');
      expect(settleUp.memberId, 'm1');
      expect(settleUp.sentAt, DateTime(2026, 10, 20));
      expect(settleUp.message, 'Pay me back', reason: 'existing reminder rows survive the upgrade');
      expect(settleUp.title, '');
      expect(settleUp.status, 'pending');
      expect(settleUp.repeat, 'once');
      expect(settleUp.remindDaysBefore, '0');
      expect(settleUp.notifyAtMinute, isNull);
      expect(settleUp.amountMinor, isNull);
      final indexes = await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = 'reminders'").get();
      expect(indexes.map((row) => row.data['name']), containsAll(['reminders_group_id', 'reminders_status_due']));
      await db.close();
    });
  }

  for (final (from, rewind) in [(10, rewindToVersion10), (11, rewindToVersion11)]) {
    test('upgrading from schema $from with data adds due-reminder columns and keeps entries, activity and reminders', () async {
      final seed = AppDatabase(NativeDatabase(file));
      await seed.into(seed.entries).insert(EntriesRepository.newExpense(id: 'e1', amountMinor: 90000, occurredAt: DateTime(2026, 10, 20), groupId: 'g1', paidByMemberId: 'm1', splitMethod: 'equal'));
      await seed.into(seed.groupActivities).insert(GroupActivitiesCompanion.insert(id: 'a1', groupId: 'g1', action: 'added', subjectKind: 'expense', subjectId: 'e1', occurredAt: DateTime(2026, 10, 20)));
      await seed.into(seed.reminders).insert(RemindersCompanion.insert(id: 'r1', kind: 'settle_up', groupId: const Value('g1'), memberId: const Value('m1'), sentAt: Value(DateTime(2026, 10, 21)), message: const Value('Pay me back')));
      await seed.close();
      await rewind(file);

      final db = AppDatabase(NativeDatabase(file));
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data['user_version'], db.schemaVersion);
      expect((await db.select(db.entries).getSingle()).amountMinor, 90000);
      expect((await db.select(db.groupActivities).getSingle()).subjectId, 'e1', reason: 'the v10 activity log is kept');
      final settleUp = await db.select(db.reminders).getSingle();
      expect(settleUp.message, 'Pay me back');
      expect(settleUp.status, 'pending');
      expect(settleUp.dueAt, isNull);
      await db.into(db.reminders).insert(RemindersCompanion.insert(id: 'r2', kind: 'bill', title: const Value('Rent'), amountMinor: const Value(1500000), dueAt: Value(DateTime(2026, 11, 1))));
      expect((await (db.select(db.reminders)..where((row) => row.id.equals('r2'))).getSingle()).title, 'Rent');
      await db.close();
    });
  }

  for (final (from, rewind) in [(6, rewindToVersion6), (8, rewindToVersion8), (11, rewindToVersion11), (12, rewindToVersion12)]) {
    test('upgrading from schema $from links reminders to projects and keeps existing ones', () async {
      final seed = AppDatabase(NativeDatabase(file));
      await seed.into(seed.reminders).insert(RemindersCompanion.insert(id: 'r1', kind: 'document', title: const Value('Passport'), dueAt: Value(DateTime(2027, 3, 1))));
      await seed.close();
      await rewind(file);

      final db = AppDatabase(NativeDatabase(file));
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data['user_version'], db.schemaVersion);
      final passport = await db.select(db.reminders).getSingle();
      expect(passport.kind, 'document');
      expect(passport.dueAt, DateTime(2027, 3, 1), reason: 'existing reminder rows survive the upgrade');
      expect(passport.projectId, isNull);
      expect(passport.documentNumber, '');
      expect(passport.presetKey, isNull);
      final indexes = await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = 'reminders'").get();
      expect(indexes.map((row) => row.data['name']), containsAll(['reminders_project_id', 'reminders_status_due']));
      await db.close();
    });
  }

  test('upgrading a pre-release document reminders build (schema 7 with project link) keeps it and adds recurring rules', () async {
    final seed = AppDatabase(NativeDatabase(file));
    await seed.into(seed.reminders).insert(RemindersCompanion.insert(id: 'r1', kind: 'document', title: const Value('PUC certificate'), projectId: const Value('p1'), documentNumber: const Value('MH12-PUC-1'), presetKey: const Value('puc'), dueAt: Value(DateTime(2027, 1, 10))));
    await seed.close();
    await rewindToDocumentRemindersPreReleaseVersion7(file);

    final db = AppDatabase(NativeDatabase(file));
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data['user_version'], db.schemaVersion);
    final puc = await db.select(db.reminders).getSingle();
    expect(puc.projectId, 'p1');
    expect(puc.documentNumber, 'MH12-PUC-1');
    expect(puc.presetKey, 'puc');
    expect(await db.select(db.recurringRules).get(), isEmpty, reason: 'the recurring_rules table it skipped is created');
    final entryColumns = await db.customSelect('PRAGMA table_info(entries)').get();
    expect(entryColumns.map((row) => row.data['name']), contains('recurring_id'));
    expect(await db.select(db.groupActivities).get(), isEmpty);
    await db.close();
  });

  test('upgrading a reminders QA build (schema 9 with due columns) does not re-add them and adds the activity log', () async {
    final seed = AppDatabase(NativeDatabase(file));
    await seed.into(seed.reminders).insert(RemindersCompanion.insert(id: 'r1', kind: 'bill', title: const Value('Card bill'), amountMinor: const Value(500000), dueAt: Value(DateTime(2026, 11, 3))));
    await seed.close();
    await rewindToRemindersQaVersion9(file);

    final db = AppDatabase(NativeDatabase(file));
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data['user_version'], db.schemaVersion);
    expect((await db.select(db.reminders).getSingle()).title, 'Card bill');
    expect(await db.select(db.groupActivities).get(), isEmpty);
    await db.close();
  });

  test('upgrading a pre-release reminders build (schema 6 with due columns) keeps its reminders and adds entry payers', () async {
    final seed = AppDatabase(NativeDatabase(file));
    await seed.into(seed.reminders).insert(RemindersCompanion.insert(id: 'r1', kind: 'bill', title: const Value('Electricity bill'), amountMinor: const Value(210000), dueAt: Value(DateTime(2026, 11, 5)), status: const Value('pending')));
    await seed.close();
    await rewindToPreReleaseRemindersVersion6(file);

    final db = AppDatabase(NativeDatabase(file));
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data['user_version'], db.schemaVersion);
    final bill = await db.select(db.reminders).getSingle();
    expect(bill.title, 'Electricity bill');
    expect(bill.amountMinor, 210000);
    expect(bill.dueAt, DateTime(2026, 11, 5));
    expect(await db.select(db.entryPayers).get(), isEmpty, reason: 'the entry_payers table it never had is created');
    expect(await db.select(db.recurringRules).get(), isEmpty);
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

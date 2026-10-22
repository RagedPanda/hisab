import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/backup/backup_codec.dart';
import '../db/database.dart';

/// Exports and imports every table as JSON wrapped in the encrypted container.
class BackupService {
  BackupService(this.db);
  final AppDatabase db;

  Future<Map<String, dynamic>> snapshot() async {
    Future<List<Map<String, dynamic>>> dump<D extends DataClass>(TableInfo<Table, D> table) async {
      final rows = await db.select(table).get();
      return [for (final row in rows) row.toJson()];
    }

    return {
      'version': 1,
      'app': 'hisab',
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': await dump(db.accounts),
      'categories': await dump(db.categories),
      'entries': await dump(db.entries),
      'entryItems': await dump(db.entryItems),
      'groups': await dump(db.groups),
      'members': await dump(db.members),
      'splits': await dump(db.splits),
      'settlements': await dump(db.settlements),
      'budgets': await dump(db.budgets),
      'smsLog': await dump(db.smsLog),
      'projects': await dump(db.projects),
      'projectFields': await dump(db.projectFields),
      'entryFieldValues': await dump(db.entryFieldValues),
      'reminders': await dump(db.reminders),
      'entryPayers': await dump(db.entryPayers),
    };
  }

  Future<Uint8List> exportEncrypted(String passphrase) async => encryptBackup(payload: await snapshot(), passphrase: passphrase);

  Future<String> exportPlainJson() async => const JsonEncoder.withIndent('  ').convert(await snapshot());

  Future<int> importEncrypted(List<int> bytes, String passphrase) async {
    final payload = await decryptBackup(bytes: bytes, passphrase: passphrase);
    return importSnapshot(payload);
  }

  /// Merges a backup into the current database. A row is written only when it
  /// is new or newer (by updatedAt) than the local copy, so restoring an old
  /// backup never clobbers recent edits. This is the same rule future sync uses.
  Future<int> importSnapshot(Map<String, dynamic> payload) async {
    if (payload['app'] != 'hisab') throw const BackupFormatException('Not a Hisab backup');
    var written = 0;

    Future<void> restore<D extends DataClass>(
      TableInfo<Table, D> table,
      String key,
      D Function(Map<String, dynamic>) fromJson,
      String Function(D) idOf,
      DateTime? Function(D) updatedOf,
    ) async {
      final rows = (payload[key] as List?) ?? const [];
      final existingRows = await db.select(table).get();
      final existingById = {for (final row in existingRows) idOf(row): row};
      for (final raw in rows) {
        final incoming = fromJson(Map<String, dynamic>.from(raw as Map));
        final current = existingById[idOf(incoming)];
        if (current != null) {
          final currentUpdated = updatedOf(current);
          final incomingUpdated = updatedOf(incoming);
          if (currentUpdated != null && incomingUpdated != null && !incomingUpdated.isAfter(currentUpdated)) continue;
        }
        await db.into(table).insertOnConflictUpdate(incoming as Insertable<D>);
        written++;
      }
    }

    await db.transaction(() async {
      await restore(db.accounts, 'accounts', Account.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.categories, 'categories', Category.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.entries, 'entries', Entry.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.entryItems, 'entryItems', EntryItem.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.groups, 'groups', Group.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.members, 'members', Member.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.splits, 'splits', Split.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.settlements, 'settlements', Settlement.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.budgets, 'budgets', Budget.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.smsLog, 'smsLog', SmsLogData.fromJson, (r) => r.id, (_) => null);
      await restore(db.projects, 'projects', Project.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.projectFields, 'projectFields', ProjectField.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.entryFieldValues, 'entryFieldValues', EntryFieldValue.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.reminders, 'reminders', Reminder.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.entryPayers, 'entryPayers', EntryPayer.fromJson, (r) => r.id, (r) => r.updatedAt);
    });
    return written;
  }
}

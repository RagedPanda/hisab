import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/backup/backup_codec.dart';
import '../../domain/backup/backup_settings.dart';
import '../../domain/money/money_format.dart';
import '../db/database.dart';
import '../repositories/reminders_repository.dart';
import 'backup_section.dart';

/// What a restore wrote, plus the backup's currency and number format (null
/// for older backups without them).
class BackupRestoreResult {
  const BackupRestoreResult({required this.written, required this.currencyCode, this.numberFormat});
  final int written;
  final String? currencyCode;
  final NumberFormatChoice? numberFormat;
}

/// Exports and imports every table, plus any settings [sections], as JSON
/// wrapped in the encrypted container.
class BackupService {
  BackupService(this.db, {this.sections = const []});
  final AppDatabase db;
  final List<BackupSection> sections;

  /// [currencyCode] and [numberFormat] are stored so a restore keeps them.
  Future<Map<String, dynamic>> snapshot({String? currencyCode, NumberFormatChoice? numberFormat}) async {
    Future<List<Map<String, dynamic>>> dump<D extends DataClass>(TableInfo<Table, D> table) async {
      final rows = await db.select(table).get();
      return [for (final row in rows) row.toJson()];
    }

    return {
      'version': 1,
      'app': 'hisab',
      'exportedAt': DateTime.now().toIso8601String(),
      if (currencyCode != null) kBackupSettingsKey: backupSettingsSection(currencyCode: currencyCode, numberFormat: numberFormat),
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
      'itemAssignments': await dump(db.itemAssignments),
      'groupActivities': await dump(db.groupActivities),
      'recurringRules': await dump(db.recurringRules),
      'payeeCategories': await dump(db.payeeCategories),
      'people': await dump(db.people),
      for (final section in sections) section.key: ?section.export(),
    };
  }

  Future<Uint8List> exportEncrypted(String passphrase, {String? currencyCode, NumberFormatChoice? numberFormat}) async =>
      encryptBackup(payload: await snapshot(currencyCode: currencyCode, numberFormat: numberFormat), passphrase: passphrase);

  Future<String> exportPlainJson() async => const JsonEncoder.withIndent('  ').convert(await snapshot());

  Future<BackupRestoreResult> importEncrypted(List<int> bytes, String passphrase) async {
    final payload = await decryptBackup(bytes: bytes, passphrase: passphrase);
    final written = await importSnapshot(payload);
    return BackupRestoreResult(written: written, currencyCode: backupCurrencyCode(payload), numberFormat: backupNumberFormat(payload));
  }

  /// Values for group columns added in schema v7, for backups made before it.
  static const groupBackupDefaults = <String, Object?>{'type': 'other', 'defaultSplitMethod': 'equal', 'notes': ''};

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
      DateTime? Function(D) updatedOf, {
      Map<String, Object?> defaults = const {},
    }) async {
      final rows = (payload[key] as List?) ?? const [];
      final existingRows = await db.select(table).get();
      final existingById = {for (final row in existingRows) idOf(row): row};
      for (final raw in rows) {
        // Backups made before a column existed lack its key; [defaults] fills it.
        final incoming = fromJson({...defaults, ...Map<String, dynamic>.from(raw as Map)});
        final current = existingById[idOf(incoming)];
        if (current != null) {
          final currentUpdated = updatedOf(current);
          final incomingUpdated = updatedOf(incoming);
          if (currentUpdated != null && incomingUpdated != null && !incomingUpdated.isAfter(currentUpdated)) continue;
        }
        await db.into(table).insertOnConflictUpdate(wholeRow(incoming as Insertable<D>));
        written++;
      }
    }

    await db.transaction(() async {
      await restore(db.accounts, 'accounts', Account.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.categories, 'categories', Category.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.entries, 'entries', Entry.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.entryItems, 'entryItems', EntryItem.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.groups, 'groups', Group.fromJson, (r) => r.id, (r) => r.updatedAt, defaults: groupBackupDefaults);
      await restore(db.members, 'members', Member.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.splits, 'splits', Split.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.settlements, 'settlements', Settlement.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.budgets, 'budgets', Budget.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.smsLog, 'smsLog', SmsLogData.fromJson, (r) => r.id, (_) => null);
      await restore(db.projects, 'projects', Project.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.projectFields, 'projectFields', ProjectField.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.entryFieldValues, 'entryFieldValues', EntryFieldValue.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.reminders, 'reminders', (json) => Reminder.fromJson(reminderJsonWithDefaults(json)), (r) => r.id, (r) => r.updatedAt);
      await restore(db.entryPayers, 'entryPayers', EntryPayer.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.itemAssignments, 'itemAssignments', ItemAssignment.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.groupActivities, 'groupActivities', GroupActivity.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.recurringRules, 'recurringRules', RecurringRule.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.payeeCategories, 'payeeCategories', PayeeCategory.fromJson, (r) => r.id, (r) => r.updatedAt);
      await restore(db.people, 'people', Person.fromJson, (r) => r.id, (r) => r.updatedAt);
      // A backup from an older build may carry the text of not-bank SMS.
      await db.wipeUnkeptSmsText();
      // A reinstall seeds fresh categories and a Cash account with new ids, so
      // the backup's copies land beside them. Keep the backup's, drop the rest (#63).
      await db.mergeSeededDuplicates(preferIds: {...restoredIds(payload, 'accounts'), ...restoredIds(payload, 'categories')});
    });
    for (final section in sections) {
      if (payload[section.key] case final Map block) written += await section.restore(Map<String, dynamic>.from(block), db: db, payload: payload);
    }
    return written;
  }
}

/// [row] with every column written, nulls included. A data class inserts with
/// null columns left out, so a newer backup row could never clear a local
/// value such as deletedAt or a note (#91).
Insertable<D> wholeRow<D>(Insertable<D> row) => RawValuesInsertable<D>(row.toColumns(false));

/// Ids of the rows a backup payload carries for [key].
Set<String> restoredIds(Map<String, dynamic> payload, String key) => {
      for (final raw in (payload[key] as List?) ?? const [])
        if (raw is Map && raw['id'] is String) raw['id'] as String,
    };

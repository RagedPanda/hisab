import 'package:drift/drift.dart' show Value;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/salary_settings.dart';
import '../backup/backup_section.dart';
import '../db/database.dart';
import '../repositories/recurring_repository.dart';
import 'salary_service.dart';

/// The salary rule's row in a backup [payload], live again (not deleted) and
/// stamped [restoredAt]; null when the backup does not carry it.
RecurringRule? backedUpSalaryRule(Map<String, dynamic> payload, String ruleId, {required DateTime restoredAt}) {
  for (final raw in (payload['recurringRules'] as List?) ?? const []) {
    if (raw is Map && raw['id'] == ruleId) {
      return RecurringRule.fromJson(Map<String, dynamic>.from(raw)).copyWith(deletedAt: const Value(null), updatedAt: restoredAt);
    }
  }
  return null;
}

/// Carries the salary setup (shift, holidays, detection and reminder
/// settings) in backups. Its recurring rule travels with the other rows, but
/// a restore brings the two back together: the setup and the backup's rule
/// (undeleted if it was removed since), so they never disagree.
class SalaryBackupSection implements BackupSection {
  const SalaryBackupSection(this._prefs);

  final SharedPreferences _prefs;

  @override
  String get key => 'salarySettings';

  @override
  Map<String, dynamic>? export() {
    final settings = SalarySettings.fromPrefs(_prefs);
    return settings.isSetUp ? settings.toJson() : null;
  }

  @override
  Future<int> restore(Map<String, dynamic> json, {required AppDatabase db, required Map<String, dynamic> payload}) async {
    final incoming = SalarySettings.fromJson(json);
    if (!shouldRestoreSalarySettings(incoming: incoming)) return 0;
    final local = SalarySettings.fromPrefs(_prefs);
    final now = DateTime.now();
    final restored = await db.transaction(() async {
      final recurring = RecurringRepository(db);
      // A different local salary rule is replaced, so only one is active.
      if (local.isSetUp && local.ruleId != incoming.ruleId) await recurring.delete(local.ruleId);
      final row = backedUpSalaryRule(payload, incoming.ruleId, restoredAt: now);
      if (row != null) {
        // As a companion with nulls kept, so the upsert clears deletedAt.
        await db.into(db.recurringRules).insertOnConflictUpdate(row.toCompanion(false));
        return incoming;
      }
      if (await recurring.getRule(incoming.ruleId) != null) {
        await recurring.restore(incoming.ruleId);
        return incoming;
      }
      // A hand-edited backup without the rule: start a new one for the setup.
      return SalaryService(db).saveSalaryRule(settings: incoming, today: now);
    });
    await restored.writeTo(_prefs);
    return 1;
  }
}

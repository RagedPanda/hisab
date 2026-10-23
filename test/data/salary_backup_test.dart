import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/salary_settings.dart';
import 'package:hisab/data/backup/backup_service.dart';
import 'package:hisab/data/backup/month_start_backup.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/salary/salary_backup.dart';
import 'package:hisab/data/salary/salary_service.dart';
import 'package:hisab/domain/salary/salary_schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late AppDatabase restoredDb;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
    restoredDb = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    await restoredDb.close();
  });

  BackupService backupFor(AppDatabase database) => BackupService(database, sections: [SalaryBackupSection(prefs)]);

  Future<SalarySettings> saveSetup({required DateTime savedAt, int tolerancePercent = 20}) async {
    final draft = SalarySettings(
      amountMinor: 8500000,
      salaryDay: 30,
      shift: SalaryShift.nextWorkingDay,
      holidays: [DateTime(2026, 11, 8)],
      reminderDelayDays: 3,
      matchWindowDays: 6,
      tolerancePercent: tolerancePercent,
      updatedAt: savedAt,
    );
    final saved = await SalaryService(db).saveSalaryRule(settings: draft, today: DateTime(2026, 10, 22));
    await saved.writeTo(prefs);
    return saved;
  }

  test('a backup carries the salary setup and restores it with its rule on a fresh device', () async {
    final saved = await saveSetup(savedAt: DateTime(2026, 10, 22, 9));
    final payload = await backupFor(db).snapshot();
    expect(payload['salarySettings'], saved.toJson());

    await prefs.clear();
    final written = await backupFor(restoredDb).importSnapshot(payload);

    final restored = SalarySettings.fromPrefs(prefs);
    expect(restored.toJson(), saved.toJson());
    expect(await SalaryService(restoredDb).recurring.getRule(restored.ruleId), isNotNull);
    expect(written, greaterThanOrEqualTo(2), reason: 'the rule row and the salary block');
  });

  test('export, remove salary, restore: the setup and its rule come back together', () async {
    final saved = await saveSetup(savedAt: DateTime(2026, 10, 22, 9));
    final payload = await backupFor(db).snapshot();

    // Remove salary as the screen does: the rule is deleted, the setup reset.
    await SalaryService(db).removeSalaryRule(saved.ruleId);
    await const SalarySettings().writeTo(prefs);
    expect((await SalaryService(db).recurring.getRule(saved.ruleId))!.deletedAt, isNotNull);

    await backupFor(db).importSnapshot(payload);
    final restored = SalarySettings.fromPrefs(prefs);
    expect(restored.ruleId, saved.ruleId);
    final rule = (await SalaryService(db).recurring.getRule(saved.ruleId))!;
    expect(rule.deletedAt, isNull, reason: 'the newer local delete does not win over the restore');
    expect(rule.nextDue, isNotNull);
    expect((await SalaryService(db).recurring.watchViews().first).map((view) => view.rule.id), contains(saved.ruleId), reason: 'Recurring lists the salary again');
  });

  test('a backup restores over a newer local setup and replaces its rule, so only one salary rule is live', () async {
    final backedUp = await saveSetup(savedAt: DateTime(2026, 10, 1), tolerancePercent: 10);
    final payload = await backupFor(db).snapshot();
    await SalaryService(db).removeSalaryRule(backedUp.ruleId);
    final newer = await SalaryService(db).saveSalaryRule(
      settings: const SalarySettings(amountMinor: 9000000, salaryDay: 5, tolerancePercent: 30).copyWith(updatedAt: DateTime(2026, 10, 20)),
      today: DateTime(2026, 10, 22),
    );
    await newer.writeTo(prefs);

    await backupFor(db).importSnapshot(payload);
    final restored = SalarySettings.fromPrefs(prefs);
    expect((restored.ruleId, restored.tolerancePercent), (backedUp.ruleId, 10));
    expect((await SalaryService(db).recurring.getRule(backedUp.ruleId))!.deletedAt, isNull);
    expect((await SalaryService(db).recurring.getRule(newer.ruleId))!.deletedAt, isNotNull);
  });

  test('a backup whose rule row is missing still leaves a live rule for the setup', () async {
    final saved = await saveSetup(savedAt: DateTime(2026, 10, 22, 9));
    final payload = await backupFor(db).snapshot()
      ..['recurringRules'] = [];
    await prefs.clear();
    await backupFor(restoredDb).importSnapshot(payload);
    final restored = SalarySettings.fromPrefs(prefs);
    expect(restored.isSetUp, isTrue);
    expect(restored.salaryDay, saved.salaryDay);
    expect((await SalaryService(restoredDb).recurring.getRule(restored.ruleId))!.dayOfMonth, saved.salaryDay);
  });

  test('no salary block when salary is not set up, and older backups without one restore fine', () async {
    final payload = await backupFor(db).snapshot();
    expect(payload.containsKey('salarySettings'), isFalse);

    final written = await backupFor(restoredDb).importSnapshot({'app': 'hisab', 'version': 1, 'accounts': []});
    expect(written, 0);
    expect(SalarySettings.fromPrefs(prefs).isSetUp, isFalse);
  });

  group('month start', () {
    test('a backup carries "Month starts on" and a fresh device takes it', () async {
      await prefs.setInt('monthStartDay', 25);
      final backup = BackupService(db, sections: [MonthStartBackupSection(prefs)]);
      final payload = await backup.snapshot();
      expect(payload['generalSettings'], {'monthStartDay': 25});

      await prefs.clear();
      await BackupService(restoredDb, sections: [MonthStartBackupSection(prefs)]).importSnapshot(payload);
      expect(prefs.getInt('monthStartDay'), 25);

      await prefs.setInt('monthStartDay', 10);
      await BackupService(restoredDb, sections: [MonthStartBackupSection(prefs)]).importSnapshot(payload);
      expect(prefs.getInt('monthStartDay'), 25, reason: 'overrides a day chosen on this device');
    });

    test('the backup day always wins when it has one, and bad values are ignored', () {
      expect(shouldRestoreMonthStartDay(local: 1, incoming: 25), isTrue);
      expect(shouldRestoreMonthStartDay(local: 10, incoming: 25), isTrue, reason: 'a restore brings back the saved state');
      expect(shouldRestoreMonthStartDay(local: 25, incoming: 25), isFalse);
      expect(shouldRestoreMonthStartDay(local: 1, incoming: null), isFalse);
      expect(parseBackedUpMonthStartDay({'monthStartDay': 29}), isNull);
      expect(parseBackedUpMonthStartDay({'monthStartDay': '5'}), isNull);
      expect(parseBackedUpMonthStartDay({'monthStartDay': 28}), 28);
    });

    test('an older backup without the block restores without it', () async {
      await prefs.setInt('monthStartDay', 10);
      final payload = await BackupService(db).snapshot();
      await BackupService(restoredDb, sections: [MonthStartBackupSection(prefs)]).importSnapshot(payload);
      expect(prefs.getInt('monthStartDay'), 10);
    });
  });
}

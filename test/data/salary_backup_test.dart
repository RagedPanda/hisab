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

  test('an older backup does not overwrite a newer local setup', () async {
    await saveSetup(savedAt: DateTime(2026, 10, 1), tolerancePercent: 10);
    final payload = await backupFor(db).snapshot();
    final newer = SalarySettings.fromPrefs(prefs).copyWith(tolerancePercent: 30, updatedAt: DateTime(2026, 10, 20));
    await newer.writeTo(prefs);

    await backupFor(restoredDb).importSnapshot(payload);
    expect(SalarySettings.fromPrefs(prefs).tolerancePercent, 30);
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
    });

    test('a day chosen on this device is kept, and bad values are ignored', () {
      expect(shouldRestoreMonthStartDay(local: 1, incoming: 25), isTrue);
      expect(shouldRestoreMonthStartDay(local: 10, incoming: 25), isFalse);
      expect(shouldRestoreMonthStartDay(local: 1, incoming: null), isFalse);
      expect(parseBackedUpMonthStartDay({'monthStartDay': 29}), isNull);
      expect(parseBackedUpMonthStartDay({'monthStartDay': '5'}), isNull);
      expect(parseBackedUpMonthStartDay({'monthStartDay': 28}), 28);
    });

    test('an older backup without the block restores without it', () async {
      final payload = await BackupService(db).snapshot();
      await BackupService(restoredDb, sections: [MonthStartBackupSection(prefs)]).importSnapshot(payload);
      expect(prefs.getInt('monthStartDay'), isNull);
    });
  });
}

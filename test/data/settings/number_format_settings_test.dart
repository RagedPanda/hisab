import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/settings.dart';
import 'package:hisab/data/backup/backup_service.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/domain/backup/backup_settings.dart';
import 'package:hisab/domain/money/money_format.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  group('settings persistence', () {
    test('a new install follows the currency and region', () async {
      expect(AppSettings.fromPrefs(await prefsWith({})).numberFormat, NumberFormatChoice.automatic);
    });

    test('a chosen format survives a save and reload', () async {
      final prefs = await prefsWith({});
      await const AppSettings().copyWith(numberFormat: NumberFormatChoice.dotGroupCommaDecimal).writeTo(prefs);
      expect(prefs.getString(kNumberFormatKey), 'dotComma');
      expect(AppSettings.fromPrefs(prefs).numberFormat, NumberFormatChoice.dotGroupCommaDecimal);
    });

    test('an unknown stored value falls back to automatic', () async {
      expect(AppSettings.fromPrefs(await prefsWith({kNumberFormatKey: 'later'})).numberFormat, NumberFormatChoice.automatic);
    });

    test('every choice has a distinct storage key', () {
      final keys = NumberFormatChoice.values.map((choice) => choice.storageKey).toSet();
      expect(keys, hasLength(NumberFormatChoice.values.length));
      for (final choice in NumberFormatChoice.values) {
        expect(NumberFormatChoice.fromStorageKey(choice.storageKey), choice);
      }
    });
  });

  group('backup', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('the snapshot carries the number format', () async {
      final payload = await BackupService(db).snapshot(currencyCode: 'EUR', numberFormat: NumberFormatChoice.spaceGroupCommaDecimal);
      expect(backupNumberFormat(payload), NumberFormatChoice.spaceGroupCommaDecimal);
      expect(backupCurrencyCode(payload), 'EUR');
    });

    test('an older backup without one keeps the current format', () {
      expect(backupNumberFormat({kBackupSettingsKey: {'currencyCode': 'INR'}}), isNull);
      expect(backupNumberFormat({}), isNull);
      expect(backupNumberFormat({kBackupSettingsKey: {'currencyCode': 'INR', 'numberFormat': 'someday'}}), isNull);
    });

    test('an encrypted backup round-trips the number format', () async {
      final service = BackupService(db);
      final bytes = await service.exportEncrypted('passphrase1', currencyCode: 'INR', numberFormat: NumberFormatChoice.western);
      final restored = await service.importEncrypted(bytes, 'passphrase1');
      expect(restored.numberFormat, NumberFormatChoice.western);
      expect(restored.currencyCode, 'INR');
    });
  });
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/core/settings.dart';
import 'package:hisab/data/backup/backup_service.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/settings/currency_migration.dart';
import 'package:hisab/domain/backup/backup_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  group('startup migration', () {
    test('fresh install stores nothing, so the first-launch screen shows', () async {
      final prefs = await prefsWith({});
      await migrateCurrencySetting(prefs, db);
      expect(prefs.containsKey(kCurrencyCodeKey), isFalse);
      expect(AppSettings.fromPrefs(prefs).currencyConfirmed, isFalse);
    });
    test('upgrade with the old symbol is migrated and not asked', () async {
      final prefs = await prefsWith({'currencySymbol': '€'});
      await migrateCurrencySetting(prefs, db);
      expect(prefs.getString(kCurrencyCodeKey), 'EUR');
      final settings = AppSettings.fromPrefs(prefs);
      expect(settings.currencyConfirmed, isTrue);
      expect(settings.currencySymbol, '€');
    });
    test('upgrade with data but default settings gets INR', () async {
      final prefs = await prefsWith({});
      await db.into(db.groups).insert(GroupsCompanion.insert(id: newId(), name: 'Trip'));
      await migrateCurrencySetting(prefs, db);
      expect(prefs.getString(kCurrencyCodeKey), 'INR');
    });
    test('an existing code is never overwritten', () async {
      final prefs = await prefsWith({'currencyCode': 'JPY', 'currencySymbol': r'$'});
      await migrateCurrencySetting(prefs, db);
      expect(prefs.getString(kCurrencyCodeKey), 'JPY');
    });
    test('only the seeded Cash account is not user data', () async {
      expect(await hasUserCreatedData(db), isFalse);
    });
  });

  group('settings persistence', () {
    test('confirmed currency writes the code and a symbol for older builds', () async {
      final prefs = await prefsWith({});
      await const AppSettings(currencyCode: 'CHF').writeTo(prefs);
      expect(prefs.getString(kCurrencyCodeKey), 'CHF');
      expect(prefs.getString(kLegacyCurrencySymbolKey), 'CHF');
    });
    test('an unconfirmed fresh install writes no currency', () async {
      final prefs = await prefsWith({});
      await const AppSettings(currencyConfirmed: false).writeTo(prefs);
      expect(prefs.containsKey(kCurrencyCodeKey), isFalse);
    });
  });

  test('backup snapshot carries the currency', () async {
    final payload = await BackupService(db).snapshot(currencyCode: 'AED');
    expect(backupCurrencyCode(payload), 'AED');
  });
}

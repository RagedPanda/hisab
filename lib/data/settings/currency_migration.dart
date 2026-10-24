import 'package:shared_preferences/shared_preferences.dart';

import '../../core/settings.dart';
import '../../domain/currency/currency_setup.dart';
import '../db/database.dart';

/// Stores a currency code for upgrades before the first frame, so only a
/// fresh install sees the first-launch currency screen.
Future<void> migrateCurrencySetting(SharedPreferences prefs, AppDatabase db) async {
  final storedCode = prefs.getString(kCurrencyCodeKey);
  final legacySymbol = prefs.getString(kLegacyCurrencySymbolKey);
  if (storedCode != null && storedCode.isNotEmpty) return;
  final hasUserData = legacySymbol != null || await hasUserCreatedData(db);
  final code = currencyCodeToMigrate(storedCode: storedCode, legacySymbol: legacySymbol, hasUserData: hasUserData);
  if (code != null) await prefs.setString(kCurrencyCodeKey, code);
}

/// True once the person has recorded anything: an entry, a group, or an
/// account beyond the seeded Cash one.
Future<bool> hasUserCreatedData(AppDatabase db) async {
  final anyEntry = await (db.select(db.entries)..limit(1)).get();
  if (anyEntry.isNotEmpty) return true;
  final anyGroup = await (db.select(db.groups)..limit(1)).get();
  if (anyGroup.isNotEmpty) return true;
  final accounts = await (db.select(db.accounts)..limit(2)).get();
  return accounts.length > 1;
}

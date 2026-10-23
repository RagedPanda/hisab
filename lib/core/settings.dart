import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/currency/currency_lookup.dart';

/// Preference key for the ISO 4217 home currency code.
const String kCurrencyCodeKey = 'currencyCode';

/// Preference key of the old free-text symbol; read only to migrate.
const String kLegacyCurrencySymbolKey = 'currencySymbol';

/// User preferences persisted outside the database.
class AppSettings {
  const AppSettings({
    this.currencyCode = kDefaultCurrencyCode,
    this.currencyConfirmed = true,
    this.monthStartDay = 1,
    this.themeMode = ThemeMode.system,
    this.smsEnabled = false,
    this.smsAutoAdd = false,
    this.myName = '',
    this.onboarded = false,
    this.localeCode = '',
  });

  /// ISO 4217 code of the home currency; the symbol is derived from it.
  final String currencyCode;

  /// False only on a fresh install until the first-launch screen stores a
  /// currency. Upgrades are migrated at startup and never see that screen.
  final bool currencyConfirmed;

  String get currencySymbol => symbolForCurrencyCode(currencyCode);
  final int monthStartDay;
  final ThemeMode themeMode;

  /// Whether the user has opted in to reading bank SMS.
  final bool smsEnabled;

  /// Add parsed SMS transactions directly instead of queueing for review.
  final bool smsAutoAdd;
  final String myName;
  final bool onboarded;

  /// BCP-47 language code, or empty to follow the device locale.
  final String localeCode;

  Locale? get locale => localeCode.isEmpty ? null : Locale(localeCode);

  AppSettings copyWith({
    String? currencyCode,
    bool? currencyConfirmed,
    int? monthStartDay,
    ThemeMode? themeMode,
    bool? smsEnabled,
    bool? smsAutoAdd,
    String? myName,
    bool? onboarded,
    String? localeCode,
  }) =>
      AppSettings(
        currencyCode: currencyCode ?? this.currencyCode,
        currencyConfirmed: currencyConfirmed ?? this.currencyConfirmed,
        monthStartDay: monthStartDay ?? this.monthStartDay,
        themeMode: themeMode ?? this.themeMode,
        smsEnabled: smsEnabled ?? this.smsEnabled,
        smsAutoAdd: smsAutoAdd ?? this.smsAutoAdd,
        myName: myName ?? this.myName,
        onboarded: onboarded ?? this.onboarded,
        localeCode: localeCode ?? this.localeCode,
      );

  static AppSettings fromPrefs(SharedPreferences prefs) => AppSettings(
        currencyCode: prefs.getString(kCurrencyCodeKey) ?? currencyCodeForLegacySymbol(prefs.getString(kLegacyCurrencySymbolKey)),
        currencyConfirmed: prefs.containsKey(kCurrencyCodeKey),
        monthStartDay: prefs.getInt('monthStartDay') ?? 1,
        themeMode: ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.system.index],
        smsEnabled: prefs.getBool('smsEnabled') ?? false,
        smsAutoAdd: prefs.getBool('smsAutoAdd') ?? false,
        myName: prefs.getString('myName') ?? '',
        onboarded: prefs.getBool('onboarded') ?? false,
        localeCode: prefs.getString('localeCode') ?? '',
      );

  Future<void> writeTo(SharedPreferences prefs) async {
    if (currencyConfirmed) {
      await prefs.setString(kCurrencyCodeKey, currencyCode);
      // Older builds still read the symbol, so a downgrade keeps the currency.
      await prefs.setString(kLegacyCurrencySymbolKey, currencySymbol);
    }
    await prefs.setInt('monthStartDay', monthStartDay);
    await prefs.setInt('themeMode', themeMode.index);
    await prefs.setBool('smsEnabled', smsEnabled);
    await prefs.setBool('smsAutoAdd', smsAutoAdd);
    await prefs.setString('myName', myName);
    await prefs.setBool('onboarded', onboarded);
    await prefs.setString('localeCode', localeCode);
  }
}

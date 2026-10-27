import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/currency/currency_lookup.dart';
import '../domain/money/money_format.dart';
import '../domain/money/money_format_resolver.dart';
import '../domain/sms/sms_confidence.dart';

/// Preference behind Settings > "Month starts on"; also read by backups.
const String kMonthStartDayPref = 'monthStartDay';

/// Preference key for the ISO 4217 home currency code.
const String kCurrencyCodeKey = 'currencyCode';

/// Preference key of the old free-text symbol; read only to migrate.
const String kLegacyCurrencySymbolKey = 'currencySymbol';

/// Preference behind Settings > Money > Number format; also read by backups.
const String kNumberFormatKey = 'numberFormat';

/// User preferences persisted outside the database.
class AppSettings {
  const AppSettings({
    this.currencyCode = kDefaultCurrencyCode,
    this.currencyConfirmed = true,
    this.monthStartDay = 1,
    this.themeMode = ThemeMode.system,
    this.smsEnabled = false,
    this.smsAutoAdd = true,
    this.smsAutoAddChosen = false,
    this.myName = '',
    this.onboarded = false,
    this.localeCode = '',
    this.numberFormat = NumberFormatChoice.automatic,
    this.defaultAccountId = '',
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

  /// Add confidently parsed SMS transactions directly instead of queueing
  /// them for review. On unless the user turned it off.
  final bool smsAutoAdd;

  /// Whether the user ever flipped [smsAutoAdd] themselves.
  final bool smsAutoAddChosen;
  final String myName;
  final bool onboarded;

  /// BCP-47 language code, or empty to follow the device locale.
  final String localeCode;

  Locale? get locale => localeCode.isEmpty ? null : Locale(localeCode);

  /// Digit grouping and separators: automatic (currency and region) or fixed.
  final NumberFormatChoice numberFormat;

  /// Account a new entry starts on; empty means auto (a cash account).
  final String defaultAccountId;

  AppSettings copyWith({
    String? currencyCode,
    bool? currencyConfirmed,
    int? monthStartDay,
    ThemeMode? themeMode,
    bool? smsEnabled,
    bool? smsAutoAdd,
    bool? smsAutoAddChosen,
    String? myName,
    bool? onboarded,
    String? localeCode,
    NumberFormatChoice? numberFormat,
    String? defaultAccountId,
  }) =>
      AppSettings(
        currencyCode: currencyCode ?? this.currencyCode,
        currencyConfirmed: currencyConfirmed ?? this.currencyConfirmed,
        monthStartDay: monthStartDay ?? this.monthStartDay,
        themeMode: themeMode ?? this.themeMode,
        smsEnabled: smsEnabled ?? this.smsEnabled,
        smsAutoAdd: smsAutoAdd ?? this.smsAutoAdd,
        smsAutoAddChosen: smsAutoAddChosen ?? this.smsAutoAddChosen,
        myName: myName ?? this.myName,
        onboarded: onboarded ?? this.onboarded,
        localeCode: localeCode ?? this.localeCode,
        numberFormat: numberFormat ?? this.numberFormat,
        defaultAccountId: defaultAccountId ?? this.defaultAccountId,
      );

  static AppSettings fromPrefs(SharedPreferences prefs) => AppSettings(
        currencyCode: prefs.getString(kCurrencyCodeKey) ?? currencyCodeForLegacySymbol(prefs.getString(kLegacyCurrencySymbolKey)),
        currencyConfirmed: prefs.containsKey(kCurrencyCodeKey),
        monthStartDay: prefs.getInt(kMonthStartDayPref) ?? 1,
        themeMode: ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.system.index],
        smsEnabled: prefs.getBool('smsEnabled') ?? false,
        smsAutoAdd: resolveSmsAutoAdd(storedValue: prefs.getBool('smsAutoAdd'), userChose: prefs.getBool('smsAutoAddChosen') ?? false),
        smsAutoAddChosen: prefs.getBool('smsAutoAddChosen') ?? false,
        myName: prefs.getString('myName') ?? '',
        onboarded: prefs.getBool('onboarded') ?? false,
        localeCode: prefs.getString('localeCode') ?? '',
        numberFormat: NumberFormatChoice.fromStorageKey(prefs.getString(kNumberFormatKey)),
        defaultAccountId: prefs.getString('defaultAccountId') ?? '',
      );

  Future<void> writeTo(SharedPreferences prefs) async {
    if (currencyConfirmed) {
      await prefs.setString(kCurrencyCodeKey, currencyCode);
      // Older builds still read the symbol, so a downgrade keeps the currency.
      await prefs.setString(kLegacyCurrencySymbolKey, currencySymbol);
    }
    await prefs.setInt(kMonthStartDayPref, monthStartDay);
    await prefs.setInt('themeMode', themeMode.index);
    await prefs.setBool('smsEnabled', smsEnabled);
    await prefs.setBool('smsAutoAdd', smsAutoAdd);
    await prefs.setBool('smsAutoAddChosen', smsAutoAddChosen);
    await prefs.setString('myName', myName);
    await prefs.setBool('onboarded', onboarded);
    await prefs.setString('localeCode', localeCode);
    await prefs.setString(kNumberFormatKey, numberFormat.storageKey);
    await prefs.setString('defaultAccountId', defaultAccountId);
  }
}

/// How home-currency amounts are written for [settings] on a device in
/// [deviceLocale]. Pure, so the background isolate shares it with
/// homeMoneyFormatProvider.
MoneyFormat homeMoneyFormatFor(AppSettings settings, Locale deviceLocale) => resolveMoneyFormat(
      currencyCode: settings.currencyCode.isEmpty ? kDefaultCurrencyCode : settings.currencyCode,
      deviceLanguage: deviceLocale.languageCode,
      deviceCountry: deviceLocale.countryCode,
      choice: settings.numberFormat,
    );

/// How a group with [currencyLabel] writes amounts; see [moneyFormatForLabel].
MoneyFormat groupMoneyFormatFor(String? currencyLabel, AppSettings settings, Locale deviceLocale) => moneyFormatForLabel(
      currencyLabel,
      home: homeMoneyFormatFor(settings, deviceLocale),
      deviceLanguage: deviceLocale.languageCode,
      deviceCountry: deviceLocale.countryCode,
      choice: settings.numberFormat,
    );

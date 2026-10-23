import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/sms/sms_confidence.dart';

/// User preferences persisted outside the database.
class AppSettings {
  const AppSettings({
    this.currencySymbol = '₹',
    this.monthStartDay = 1,
    this.themeMode = ThemeMode.system,
    this.smsEnabled = false,
    this.smsAutoAdd = true,
    this.smsAutoAddChosen = false,
    this.myName = '',
    this.onboarded = false,
    this.localeCode = '',
  });

  final String currencySymbol;
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

  AppSettings copyWith({
    String? currencySymbol,
    int? monthStartDay,
    ThemeMode? themeMode,
    bool? smsEnabled,
    bool? smsAutoAdd,
    bool? smsAutoAddChosen,
    String? myName,
    bool? onboarded,
    String? localeCode,
  }) =>
      AppSettings(
        currencySymbol: currencySymbol ?? this.currencySymbol,
        monthStartDay: monthStartDay ?? this.monthStartDay,
        themeMode: themeMode ?? this.themeMode,
        smsEnabled: smsEnabled ?? this.smsEnabled,
        smsAutoAdd: smsAutoAdd ?? this.smsAutoAdd,
        smsAutoAddChosen: smsAutoAddChosen ?? this.smsAutoAddChosen,
        myName: myName ?? this.myName,
        onboarded: onboarded ?? this.onboarded,
        localeCode: localeCode ?? this.localeCode,
      );

  static AppSettings fromPrefs(SharedPreferences prefs) => AppSettings(
        currencySymbol: prefs.getString('currencySymbol') ?? '₹',
        monthStartDay: prefs.getInt('monthStartDay') ?? 1,
        themeMode: ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.system.index],
        smsEnabled: prefs.getBool('smsEnabled') ?? false,
        smsAutoAdd: resolveSmsAutoAdd(storedValue: prefs.getBool('smsAutoAdd'), userChose: prefs.getBool('smsAutoAddChosen') ?? false),
        smsAutoAddChosen: prefs.getBool('smsAutoAddChosen') ?? false,
        myName: prefs.getString('myName') ?? '',
        onboarded: prefs.getBool('onboarded') ?? false,
        localeCode: prefs.getString('localeCode') ?? '',
      );

  Future<void> writeTo(SharedPreferences prefs) async {
    await prefs.setString('currencySymbol', currencySymbol);
    await prefs.setInt('monthStartDay', monthStartDay);
    await prefs.setInt('themeMode', themeMode.index);
    await prefs.setBool('smsEnabled', smsEnabled);
    await prefs.setBool('smsAutoAdd', smsAutoAdd);
    await prefs.setBool('smsAutoAddChosen', smsAutoAddChosen);
    await prefs.setString('myName', myName);
    await prefs.setBool('onboarded', onboarded);
    await prefs.setString('localeCode', localeCode);
  }
}

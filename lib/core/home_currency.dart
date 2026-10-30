import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/currency/currency_lookup.dart';
import '../domain/money/money_format.dart';
import 'providers.dart';
import 'settings.dart';

export '../domain/currency/currency_lookup.dart' show kDefaultCurrencyCode;
export '../domain/money/money_format.dart';

/// The single place that says which currency is "home". Defaults to INR;
/// follows the currency the user picked (Settings > Currency).
final homeCurrencyCodeProvider = Provider<String>((ref) => homeCurrencyCodeOf(ref.watch(settingsProvider).currencyCode));

/// The home currency for a saved [currencyCode] setting (empty = INR). Also
/// used where there is no provider container (the notification isolate).
String homeCurrencyCodeOf(String currencyCode) => currencyCode.isEmpty ? kDefaultCurrencyCode : currencyCode;

/// The device's locale (language and region), read at the edge so number
/// formats can follow the region. Tests override it.
final deviceLocaleProvider = Provider<Locale>((ref) => PlatformDispatcher.instance.locale);

/// How home-currency amounts are written: the currency's conventions for
/// the device region, or the user's Settings > Number format choice. Pass it
/// to formatMinor / parseAmountToMinor everywhere an amount is shown or read.
final homeMoneyFormatProvider = Provider<MoneyFormat>(
  (ref) => homeMoneyFormatFor(ref.watch(settingsProvider), ref.watch(deviceLocaleProvider)),
);

/// How a group's amounts are written: its own currency label's conventions,
/// or the home format when it has none.
final groupMoneyFormatProvider = Provider.family<MoneyFormat, String?>(
  (ref, currencyLabel) => groupMoneyFormatFor(currencyLabel, ref.watch(settingsProvider), ref.watch(deviceLocaleProvider)),
);

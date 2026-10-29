import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/currency/currency_lookup.dart';
import 'providers.dart';

export '../domain/currency/currency_lookup.dart' show kDefaultCurrencyCode;

/// The single place that says which currency is "home". Defaults to INR;
/// follows the currency the user picked (Settings > Currency).
final homeCurrencyCodeProvider = Provider<String>((ref) => homeCurrencyCodeOf(ref.watch(settingsProvider).currencyCode));

/// The home currency for a saved [currencyCode] setting (empty = INR). Also
/// used where there is no provider container (the notification isolate).
String homeCurrencyCodeOf(String currencyCode) => currencyCode.isEmpty ? kDefaultCurrencyCode : currencyCode;

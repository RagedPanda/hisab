/// Picks the [MoneyFormat] for a currency from CLDR data shipped in
/// package:intl. Pure: the device locale and the user's choice come in as
/// arguments.
library;

import 'package:intl/number_symbols.dart';
import 'package:intl/number_symbols_data.dart';

import '../currency/currency_lookup.dart';
import 'money_format.dart';

/// The locale whose conventions a currency is written in when the device
/// region does not use it. Currencies not listed fall back to the first CLDR
/// locale whose default currency they are, then to plain "en".
const Map<String, String> kCanonicalCurrencyLocales = {
  'INR': 'en_IN',
  'USD': 'en_US',
  'EUR': 'de',
  'GBP': 'en_GB',
  'CHF': 'de_CH',
  'JPY': 'ja',
  'CNY': 'zh_CN',
  'HKD': 'zh_HK',
  'TWD': 'zh_TW',
  'KRW': 'ko',
  'AUD': 'en_AU',
  'CAD': 'en_CA',
  'NZD': 'en_NZ',
  'SGD': 'en_SG',
  'ZAR': 'en_ZA',
  'MYR': 'ms',
  'MXN': 'es_MX',
  'BRL': 'pt_BR',
  'PHP': 'fil',
  'NOK': 'nb',
  'IDR': 'id',
  'ILS': 'he',
  'BDT': 'bn',
  'PKR': 'ur',
  'NPR': 'ne',
  'LKR': 'si',
};

const String _fallbackLocale = 'en';

/// The format for [currencyCode]. The device region's conventions win when
/// that region uses the currency (EUR on de_DE: 1.234,56 €; on en_IE:
/// €1,234.56); otherwise the currency's own locale is used (EUR -> de, CHF
/// -> de_CH). [choice] then fixes grouping and separators if the user picked
/// one. [symbol] replaces the currency's table symbol (a group's own label).
MoneyFormat resolveMoneyFormat({
  required String currencyCode,
  String? deviceLanguage,
  String? deviceCountry,
  NumberFormatChoice choice = NumberFormatChoice.automatic,
  String? symbol,
}) {
  final code = currencyCode.trim().toUpperCase();
  final shownSymbol = symbol?.trim() ?? symbolForCurrencyCode(code);
  final fractionDigits = displayFractionDigits(code);
  final locales = [
    ...deviceLocaleCandidates(currencyCode: code, deviceLanguage: deviceLanguage, deviceCountry: deviceCountry),
    canonicalLocaleFor(code),
    _fallbackLocale,
  ];
  final base = locales
      .map((locale) => moneyFormatForLocale(locale, symbol: shownSymbol, fractionDigits: fractionDigits))
      .nonNulls
      .first;
  return applyNumberFormatChoice(base, choice);
}

/// Locales to try from the device: "lang_COUNTRY", then the bare language
/// when it is the language's home currency (so en_DE does not borrow plain
/// "en", a US-dollar locale, for euros). Empty unless the device region uses
/// [currencyCode].
List<String> deviceLocaleCandidates({required String currencyCode, String? deviceLanguage, String? deviceCountry}) {
  final language = deviceLanguage?.trim().toLowerCase() ?? '';
  final country = deviceCountry?.trim().toUpperCase() ?? '';
  final currency = currencyByCode(currencyCode);
  if (language.isEmpty || country.isEmpty || currency == null || !currency.regions.contains(country)) return const [];
  return [
    '${language}_$country',
    if (numberFormatSymbols[language]?.DEF_CURRENCY_CODE == currency.code) language,
  ];
}

/// The locale [currencyCode] is written in when the device does not decide.
String canonicalLocaleFor(String currencyCode) =>
    kCanonicalCurrencyLocales[currencyCode] ??
    numberFormatSymbols.entries.where((entry) => entry.value.DEF_CURRENCY_CODE == currencyCode).firstOrNull?.key ??
    _fallbackLocale;

/// Decimals to show: 0 for currencies CLDR writes without them (JPY, KRW,
/// VND, IDR, HUF, ISK, CLP...), else 2. Amounts are stored with two decimals,
/// so three-decimal currencies (KWD, BHD) still show two.
int displayFractionDigits(String currencyCode) {
  final digits = currencyFractionDigits[currencyCode] ?? currencyByCode(currencyCode)?.minorDigits ?? 2;
  return digits == 0 ? 0 : 2;
}

/// The format CLDR gives [localeName], or null when the locale is unknown or
/// uses separators this app does not write (e.g. Arabic-Indic ones).
MoneyFormat? moneyFormatForLocale(String localeName, {required String symbol, required int fractionDigits}) {
  final NumberSymbols? symbols = numberFormatSymbols[localeName];
  if (symbols == null) return null;
  final groupSeparator = _normaliseGroupSeparator(symbols.GROUP_SEP);
  final decimalSeparator = symbols.DECIMAL_SEP;
  if (groupSeparator == null || (decimalSeparator != '.' && decimalSeparator != ',')) return null;
  final pattern = symbols.CURRENCY_PATTERN.replaceAll(RegExp('[‎‏؜]'), '').split(';').first;
  const indianGroupingPattern = '#,##,##0';
  final indian = pattern.contains(indianGroupingPattern) || symbols.DECIMAL_PATTERN.contains(indianGroupingPattern);
  return MoneyFormat(
    grouping: indian ? DigitGrouping.indian : DigitGrouping.western,
    groupSeparator: groupSeparator,
    decimalSeparator: decimalSeparator,
    fractionDigits: fractionDigits,
    symbol: symbol,
    symbolAfter: pattern.indexOf('¤') > pattern.indexOf('0'),
  );
}

String? _normaliseGroupSeparator(String separator) => switch (separator) {
      ',' || '.' || '’' => separator,
      "'" => '’',
      _ when separator.trim().isEmpty => kSpaceGroupSeparator,
      _ => null,
    };

/// [format] with grouping and separators fixed by the user's [choice];
/// decimals and symbol placement still follow the currency.
MoneyFormat applyNumberFormatChoice(MoneyFormat format, NumberFormatChoice choice) => switch (choice) {
      NumberFormatChoice.automatic => format,
      NumberFormatChoice.indian => format.copyWith(grouping: DigitGrouping.indian, groupSeparator: ',', decimalSeparator: '.'),
      NumberFormatChoice.western => format.copyWith(grouping: DigitGrouping.western, groupSeparator: ',', decimalSeparator: '.'),
      NumberFormatChoice.dotGroupCommaDecimal => format.copyWith(grouping: DigitGrouping.western, groupSeparator: '.', decimalSeparator: ','),
      NumberFormatChoice.spaceGroupCommaDecimal =>
        format.copyWith(grouping: DigitGrouping.western, groupSeparator: kSpaceGroupSeparator, decimalSeparator: ','),
    };

/// The format for a group's amounts. An empty [label] means the app currency
/// ([home]); a label naming a known currency ("€", "USD") gets that
/// currency's conventions; any other typed label keeps [home]'s conventions
/// with the label as its symbol.
MoneyFormat moneyFormatForLabel(
  String? label, {
  required MoneyFormat home,
  String? deviceLanguage,
  String? deviceCountry,
  NumberFormatChoice choice = NumberFormatChoice.automatic,
}) {
  final trimmed = label?.trim() ?? '';
  if (trimmed.isEmpty || trimmed == home.symbol) return home;
  final currency = currencyForLabel(trimmed);
  if (currency == null) return home.copyWith(symbol: trimmed);
  return resolveMoneyFormat(
    currencyCode: currency.code,
    deviceLanguage: deviceLanguage,
    deviceCountry: deviceCountry,
    choice: choice,
    symbol: trimmed,
  );
}

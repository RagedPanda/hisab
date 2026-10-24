import 'currency.dart';
import 'currency_table.dart';

/// The currency every install falls back to.
const String kDefaultCurrencyCode = 'INR';

final Map<String, Currency> _byCode = {for (final currency in kCurrencies) currency.code: currency};

/// Free-text symbols people typed into the old setting that do not match a
/// table symbol exactly.
const Map<String, String> _legacyAliases = {'rs': 'INR', 'rs.': 'INR', '₨': 'INR', 'rupee': 'INR', 'rupees': 'INR', 'us\$': 'USD', '¥': 'JPY', '円': 'JPY', '元': 'CNY'};

Currency? currencyByCode(String code) => _byCode[code.trim().toUpperCase()];

/// Symbol for [code]; an unknown code shows as the code itself.
String symbolForCurrencyCode(String code) => currencyByCode(code)?.symbol ?? code.trim().toUpperCase();

/// Maps the old free-text currency symbol to a code. ₹ -> INR, $ -> USD,
/// € -> EUR, "CHF" -> CHF; anything unrecognised (or nothing) -> INR.
String currencyCodeForLegacySymbol(String? symbol) {
  final trimmed = symbol?.trim() ?? '';
  if (trimmed.isEmpty) return kDefaultCurrencyCode;
  final byCode = currencyByCode(trimmed);
  if (byCode != null) return byCode.code;
  final alias = _legacyAliases[trimmed.toLowerCase()];
  if (alias != null) return alias;
  for (final currency in kCurrencies) {
    if (currency.symbol == trimmed) return currency.code;
  }
  final lower = trimmed.toLowerCase();
  for (final currency in kCurrencies) {
    if (currency.symbol.toLowerCase() == lower) return currency.code;
  }
  return kDefaultCurrencyCode;
}

/// Countries that use [currency], by English name.
List<String> countryNamesFor(Currency currency) => [for (final region in currency.regions) ?kCountryNames[region]];

/// Currencies matching [query] by code, name or country, best match first:
/// exact code, code prefix, name word start, name anywhere, then country.
/// An empty query returns the whole table in its order.
List<Currency> searchCurrencies(String query, {List<Currency> currencies = kCurrencies}) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return currencies;
  final ranked = <(int, int, Currency)>[];
  for (final (index, currency) in currencies.indexed) {
    final rank = _matchRank(currency, needle);
    if (rank != null) ranked.add((rank, index, currency));
  }
  ranked.sort((first, second) => first.$1 != second.$1 ? first.$1.compareTo(second.$1) : first.$2.compareTo(second.$2));
  return [for (final (_, _, currency) in ranked) currency];
}

int? _matchRank(Currency currency, String needle) {
  final code = currency.code.toLowerCase();
  final name = currency.name.toLowerCase();
  if (code == needle) return 0;
  if (code.startsWith(needle)) return 1;
  if (name.split(RegExp(r'[\s-]+')).any((word) => word.startsWith(needle))) return 2;
  if (name.contains(needle)) return 3;
  if (countryNamesFor(currency).any((country) => country.toLowerCase().contains(needle))) return 4;
  if (currency.symbol.toLowerCase() == needle) return 5;
  return null;
}

/// Short label for a setting value or button: "₹ INR", or just "CHF" when
/// the symbol is the code.
String currencyShortLabel(String code) {
  final symbol = symbolForCurrencyCode(code);
  final upper = code.trim().toUpperCase();
  return symbol == upper ? upper : '$symbol $upper';
}

/// [currencies] with [selectedCode] moved to the front, so the current
/// choice is visible before any search.
List<Currency> selectedFirst(List<Currency> currencies, String selectedCode) {
  final selected = currencies.where((currency) => currency.code == selectedCode);
  return [...selected, ...currencies.where((currency) => currency.code != selectedCode)];
}

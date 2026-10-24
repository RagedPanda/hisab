/// Money helpers. All amounts in the app are stored as integer minor units
/// (paise for INR) to avoid floating-point drift. These functions are pure.
library;

/// Converts a user-typed decimal string such as "1,234.5" to minor units.
/// Returns null when the text is not a valid non-negative amount.
/// Longest whole-currency part accepted from user input. Twelve digits keeps
/// the minor-unit value far inside a 64-bit int, so parsing can never overflow.
const int kMaxAmountWholeDigits = 12;

int? parseAmountToMinor(String text) {
  final cleaned = text.replaceAll(',', '').replaceAll('₹', '').trim();
  if (cleaned.isEmpty) return null;
  final match = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(cleaned);
  if (match == null) return null;
  if (match.group(1)!.length > kMaxAmountWholeDigits) return null;
  final whole = int.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  return whole * 100 + int.parse(fraction);
}

/// Text to seed an amount field with: whole amounts drop the `.00`.
String amountInputText(int minor) => minor % 100 == 0 ? '${minor ~/ 100}' : minorToDouble(minor).toStringAsFixed(2);

/// Converts a double amount (e.g. 70.5) to minor units with round-half-up.
int doubleToMinor(double amount) => (amount * 100).round();

double minorToDouble(int minor) => minor / 100;

/// Formats minor units using Indian digit grouping: 12,34,567.89.
/// [symbol] is prefixed by [withCurrencySymbol]; negative amounts get a leading minus before the symbol.
///
/// [showDecimals] `null` (default) prints paise only when there are any
/// (₹250, ₹99.50); `true` always prints two decimals; `false` rounds to the
/// nearest whole unit (₹9,876.67 -> ₹9,877).
String formatMinor(
  int minor, {
  String symbol = '₹',
  bool? showDecimals,
  bool compact = false,
}) {
  final negative = minor < 0;
  final abs = minor.abs();
  final whole = abs ~/ 100;
  final frac = abs % 100;
  final String body;
  if (compact && whole >= 100000) {
    final lakhs = whole / 100000;
    body = lakhs >= 100
        ? '${(lakhs / 100).toStringAsFixed(2)}Cr'
        : '${lakhs.toStringAsFixed(2)}L';
  } else if (showDecimals == false) {
    body = groupIndian(roundMinorToWhole(abs));
  } else if (showDecimals == true || frac != 0) {
    body = '${groupIndian(whole)}.${frac.toString().padLeft(2, '0')}';
  } else {
    body = groupIndian(whole);
  }
  return withCurrencySymbol(body, symbol: symbol, negative: negative);
}

/// Joins a formatted amount [body] with the currency [symbol]. A symbol of
/// two or more characters ("CHF", "Rs", "AED") is separated by a space so it
/// does not run into the digits; a single glyph ("₹", "$", "€") stays
/// attached. A negative amount puts the minus before the symbol: "-CHF 1,000",
/// "-₹1,000". An empty symbol leaves the bare number.
String withCurrencySymbol(String body, {required String symbol, bool negative = false}) {
  final trimmedSymbol = symbol.trim();
  final separator = trimmedSymbol.runes.length > 1 ? ' ' : '';
  return '${negative ? '-' : ''}$trimmedSymbol$separator$body';
}

/// Rounds minor units to the nearest whole unit (half up).
int roundMinorToWhole(int minor) => (minor.abs() + 50) ~/ 100 * minor.sign;

/// Groups an integer the Indian way: last three digits, then pairs.
String groupIndian(int value) {
  final digits = value.toString();
  if (digits.length <= 3) return digits;
  final lastThree = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$lastThree';
}

/// Splits [total] across [weights] proportionally, returning integer minor
/// units that sum exactly to [total]. Remainder is handed out one unit at a
/// time to the entries with the largest fractional part (largest-remainder
/// method), ties broken by position so the result is deterministic.
List<int> allocateProportionally(int total, List<double> weights) {
  if (weights.isEmpty) return const [];
  final weightSum = weights.fold<double>(0, (sum, w) => sum + w);
  if (weightSum <= 0) {
    return allocateProportionally(total, List.filled(weights.length, 1));
  }
  final raw = weights.map((w) => total * w / weightSum).toList();
  final floors = raw.map((r) => r.floor()).toList();
  var remainder = total - floors.fold<int>(0, (sum, f) => sum + f);
  final order = List<int>.generate(weights.length, (i) => i)
    ..sort((a, b) {
      final cmp = (raw[b] - floors[b]).compareTo(raw[a] - floors[a]);
      return cmp != 0 ? cmp : a.compareTo(b);
    });
  final result = List<int>.from(floors);
  for (final index in order) {
    if (remainder <= 0) break;
    result[index] += 1;
    remainder -= 1;
  }
  return result;
}

/// Card accounts hold what you owe, so an entered amount due is stored as a
/// negative balance; every other account type keeps the sign as entered.
int signedBalanceForType(String accountType, int enteredMinor) => accountType == 'card' ? -enteredMinor.abs() : enteredMinor;

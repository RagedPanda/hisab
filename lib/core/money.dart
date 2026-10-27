/// Money helpers. All amounts in the app are stored as integer minor units
/// (paise for INR) to avoid floating-point drift. These functions are pure.
library;

import '../domain/money/money_format.dart';

export '../domain/money/money_format.dart';

/// Longest whole-currency part accepted from user input. Twelve digits keeps
/// the minor-unit value far inside a 64-bit int, so parsing can never overflow.
const int kMaxAmountWholeDigits = 12;

final RegExp _amountPattern = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$');
final RegExp _ignoredInAmount = RegExp('[\\s  ’\']');

/// Converts a user-typed amount such as "1,234.5" (or "1.234,5" when
/// [format] writes a decimal comma) to minor units. Returns null when the
/// text is not a valid non-negative amount.
///
/// The format's decimal separator is the decimal. With a decimal comma a
/// lone '.' followed by up to two digits is read as the decimal too, since
/// many number keyboards only offer '.'. Pasted group separators are
/// dropped when they cannot be mistaken for the decimal.
int? parseAmountToMinor(String text, {MoneyFormat format = MoneyFormat.inr}) {
  var cleaned = text.replaceAll('₹', '');
  if (format.symbol.isNotEmpty) cleaned = cleaned.replaceAll(format.symbol, '');
  cleaned = cleaned.replaceAll(_ignoredInAmount, '');
  final normalised = format.decimalSeparator == ',' ? _normaliseDecimalComma(cleaned) : cleaned.replaceAll(',', '');
  if (normalised == null || normalised.isEmpty) return null;
  final match = _amountPattern.firstMatch(normalised);
  if (match == null) return null;
  if (match.group(1)!.length > kMaxAmountWholeDigits) return null;
  final whole = int.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  return whole * 100 + int.parse(fraction);
}

/// Rewrites decimal-comma text into "1234.5" form, or null when it is
/// ambiguous or malformed.
String? _normaliseDecimalComma(String text) {
  final commas = ','.allMatches(text).length;
  if (commas > 1) return null;
  if (commas == 1) {
    final parts = text.split(',');
    return '${parts.first.replaceAll('.', '')}.${parts.last}';
  }
  final parts = text.split('.');
  if (parts.length == 1) return text;
  if (parts.length == 2 && parts.last.length <= 2) return text;
  final grouped = parts.first.isNotEmpty && parts.first.length <= 3 && parts.skip(1).every((group) => group.length == 3);
  return grouped ? parts.join() : null;
}

/// Text to seed an amount field with: whole amounts drop the decimals, and
/// the decimal is [format]'s ("1240,50" with a decimal comma).
String amountInputText(int minor, {MoneyFormat format = MoneyFormat.inr}) =>
    minor % 100 == 0 ? '${minor ~/ 100}' : minorToDouble(minor).toStringAsFixed(2).replaceAll('.', format.decimalSeparator);

/// Prefix for an amount field: [format]'s symbol, unless it goes after.
String? amountPrefixText(MoneyFormat format) => format.symbolAfter || format.symbol.isEmpty ? null : '${format.symbol} ';

/// Suffix for an amount field: [format]'s symbol when it goes after ("€").
String? amountSuffixText(MoneyFormat format) => format.symbolAfter && format.symbol.isNotEmpty ? format.symbol : null;

/// Amount field [text] typed in [from], rewritten for [to] (e.g. "12,50" ->
/// "12.50" once a group's own currency is known). Text that doesn't parse,
/// or formats sharing a decimal separator, are returned unchanged.
String reformatAmountInput(String text, {required MoneyFormat from, required MoneyFormat to}) {
  if (from.decimalSeparator == to.decimalSeparator) return text;
  final minor = parseAmountToMinor(text, format: from);
  return minor == null ? text : amountInputText(minor, format: to);
}

/// Converts a double amount (e.g. 70.5) to minor units with round-half-up.
int doubleToMinor(double amount) => (amount * 100).round();

double minorToDouble(int minor) => minor / 100;

/// Formats minor units the way [format] writes them: ₹12,34,567.89 by
/// default, $1,234,567.89, 1.234.567,89 €, CHF 1’234’567.89, ¥1,234,568.
/// [symbol], when given, replaces the format's symbol. A negative amount
/// gets a leading minus.
///
/// [showDecimals] `null` (default) prints decimals only when there are any
/// (₹250, ₹99.50); `true` always prints them; `false` rounds to the nearest
/// whole unit (₹9,876.67 -> ₹9,877). A currency written without decimals
/// (JPY) always rounds. [compact] shortens amounts from 1,00,000 / 100,000
/// up: ₹2.50L, ₹1.20Cr, $250.00K, €1,50M.
String formatMinor(
  int minor, {
  MoneyFormat format = MoneyFormat.inr,
  String? symbol,
  bool? showDecimals,
  bool compact = false,
}) {
  final style = symbol == null ? format : format.copyWith(symbol: symbol);
  final negative = minor < 0;
  final abs = minor.abs();
  final whole = abs ~/ 100;
  final frac = abs % 100;
  final String body;
  if (compact && whole >= kCompactAmountThreshold) {
    final (divisor, suffix) = compactUnit(whole.toDouble(), style.grouping);
    body = '${_withDecimalSeparator((whole / divisor).toStringAsFixed(2), style)}$suffix';
  } else if (style.fractionDigits == 0 || showDecimals == false) {
    body = groupDigits(roundMinorToWhole(abs), style);
  } else if (showDecimals == true || frac != 0) {
    body = '${groupDigits(whole, style)}${style.decimalSeparator}${frac.toString().padLeft(2, '0')}';
  } else {
    body = groupDigits(whole, style);
  }
  return withCurrencySymbol(body, symbol: style.symbol, negative: negative, after: style.symbolAfter);
}

/// Whole amounts from which [formatMinor] compacts: one lakh, or 100K.
const int kCompactAmountThreshold = 100000;

/// The largest short unit at or below [amount]: (1e7, "Cr"), (1e5, "L"),
/// (1e3, "K") for Indian grouping; (1e9, "B"), (1e6, "M"), (1e3, "K")
/// otherwise; (1, "") below a thousand.
(double, String) compactUnit(double amount, DigitGrouping grouping) {
  final units = switch (grouping) {
    DigitGrouping.indian => const [(1e7, 'Cr'), (1e5, 'L'), (1e3, 'K')],
    DigitGrouping.western => const [(1e9, 'B'), (1e6, 'M'), (1e3, 'K')],
  };
  return units.where((unit) => amount >= unit.$1).firstOrNull ?? (1.0, '');
}

String _withDecimalSeparator(String number, MoneyFormat format) =>
    format.decimalSeparator == '.' ? number : number.replaceAll('.', format.decimalSeparator);

/// Joins a formatted amount [body] with the currency [symbol]. Before the
/// number, a symbol of two or more characters ("CHF", "Rs", "AED") is
/// separated by a space so it does not run into the digits, while a single
/// glyph ("₹", "$", "€") stays attached. [after] puts it behind the number
/// with a no-break space: "1.000 €". A negative amount puts the minus first:
/// "-CHF 1,000", "-₹1,000", "-1.000 €". An empty symbol leaves the bare number.
String withCurrencySymbol(String body, {required String symbol, bool negative = false, bool after = false}) {
  final trimmedSymbol = symbol.trim();
  final sign = negative ? '-' : '';
  if (trimmedSymbol.isEmpty) return '$sign$body';
  if (after) return '$sign$body$kSymbolAfterSeparator$trimmedSymbol';
  final separator = trimmedSymbol.runes.length > 1 ? ' ' : '';
  return '$sign$trimmedSymbol$separator$body';
}

/// Rounds minor units to the nearest whole unit (half up).
int roundMinorToWhole(int minor) => (minor.abs() + 50) ~/ 100 * minor.sign;

/// Groups an integer the Indian way: last three digits, then pairs.
String groupIndian(int value) => groupDigits(value, MoneyFormat.inr);

/// Groups an integer with [format]'s grouping and group separator:
/// 12,34,567 / 1,234,567 / 1.234.567 / 1’234’567.
String groupDigits(int value, MoneyFormat format) {
  final digits = value.toString();
  if (digits.length <= 3) return digits;
  final lastThree = digits.substring(digits.length - 3);
  final groupSize = format.grouping == DigitGrouping.indian ? 2 : 3;
  var rest = digits.substring(0, digits.length - 3);
  final parts = <String>[];
  while (rest.length > groupSize) {
    parts.insert(0, rest.substring(rest.length - groupSize));
    rest = rest.substring(0, rest.length - groupSize);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return [...parts, lastThree].join(format.groupSeparator);
}

/// A short sample of [format]'s separators, "1,23,456.78", for settings.
String numberFormatSample(MoneyFormat format) =>
    formatMinor(12345678, format: format.copyWith(fractionDigits: 2), symbol: '', showDecimals: true);

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

/// How amounts in one currency are written: digit grouping, separators,
/// decimals shown, and where the symbol goes. A plain value; see
/// money_format_resolver.dart for how one is chosen.
library;

/// How the whole part of an amount is split into groups.
enum DigitGrouping {
  /// Last three digits, then pairs: 12,34,567. Compacts to L / Cr.
  indian,

  /// Threes: 1,234,567. Compacts to K / M / B.
  western,
}

/// Separator between the amount and a symbol written after it. No-break, so
/// "€" never wraps away from its number.
const String kSymbolAfterSeparator = ' ';

/// Group separator written for the "space" styles (123 456,78). No-break, so
/// a number never wraps in the middle.
const String kSpaceGroupSeparator = ' ';

class MoneyFormat {
  const MoneyFormat({
    required this.grouping,
    required this.groupSeparator,
    required this.decimalSeparator,
    required this.fractionDigits,
    required this.symbol,
    required this.symbolAfter,
  });

  /// Indian rupee style: ₹12,34,567.89. The default everywhere a format is
  /// not passed, so INR output is unchanged.
  static const MoneyFormat inr = MoneyFormat(
    grouping: DigitGrouping.indian,
    groupSeparator: ',',
    decimalSeparator: '.',
    fractionDigits: 2,
    symbol: '₹',
    symbolAfter: false,
  );

  final DigitGrouping grouping;

  /// ',' '.' no-break space or '’'.
  final String groupSeparator;

  /// '.' or ','.
  final String decimalSeparator;

  /// Decimals shown: 2, or 0 for currencies such as JPY. Amounts are always
  /// stored with two, so a 0-decimal currency rounds for display.
  final int fractionDigits;

  /// Currency symbol or label; empty for a bare number.
  final String symbol;

  /// Whether the symbol follows the number ("1.234,56 €").
  final bool symbolAfter;

  MoneyFormat copyWith({
    DigitGrouping? grouping,
    String? groupSeparator,
    String? decimalSeparator,
    int? fractionDigits,
    String? symbol,
    bool? symbolAfter,
  }) =>
      MoneyFormat(
        grouping: grouping ?? this.grouping,
        groupSeparator: groupSeparator ?? this.groupSeparator,
        decimalSeparator: decimalSeparator ?? this.decimalSeparator,
        fractionDigits: fractionDigits ?? this.fractionDigits,
        symbol: symbol ?? this.symbol,
        symbolAfter: symbolAfter ?? this.symbolAfter,
      );

  @override
  bool operator ==(Object other) =>
      other is MoneyFormat &&
      other.grouping == grouping &&
      other.groupSeparator == groupSeparator &&
      other.decimalSeparator == decimalSeparator &&
      other.fractionDigits == fractionDigits &&
      other.symbol == symbol &&
      other.symbolAfter == symbolAfter;

  @override
  int get hashCode => Object.hash(grouping, groupSeparator, decimalSeparator, fractionDigits, symbol, symbolAfter);

  @override
  String toString() => 'MoneyFormat($grouping, "$groupSeparator", "$decimalSeparator", $fractionDigits, "$symbol", after: $symbolAfter)';
}

/// Settings > Money > Number format. [automatic] follows the currency and the
/// device region; the others fix grouping and separators for every currency.
enum NumberFormatChoice {
  automatic('auto'),
  indian('indian'),
  western('western'),
  dotGroupCommaDecimal('dotComma'),
  spaceGroupCommaDecimal('spaceComma');

  const NumberFormatChoice(this.storageKey);

  /// Value kept in preferences and backups.
  final String storageKey;

  /// The choice stored as [key]; unknown or missing keys mean [automatic].
  static NumberFormatChoice fromStorageKey(String? key) => tryFromStorageKey(key) ?? automatic;

  /// The choice stored as [key], or null when it is unknown or missing.
  static NumberFormatChoice? tryFromStorageKey(String? key) => values.where((choice) => choice.storageKey == key).firstOrNull;
}

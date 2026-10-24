/// One ISO 4217 currency as the app shows it.
class Currency {
  const Currency({required this.code, required this.name, required this.symbol, required this.minorDigits, required this.regions});

  /// ISO 4217 alphabetic code, e.g. "INR".
  final String code;

  /// English name, e.g. "Indian Rupee".
  final String name;

  /// What goes before an amount: a glyph ("₹") or letters ("CHF").
  final String symbol;

  /// Digits after the decimal point in ISO 4217 (JPY 0, INR 2, KWD 3).
  final int minorDigits;

  /// ISO 3166 alpha-2 regions that use it, for country-name search.
  final List<String> regions;
}

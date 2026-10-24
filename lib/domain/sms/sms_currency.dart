/// Code a bank SMS uses for the local currency when it says "Rs", "INR" or
/// "₹". Such an SMS, like one with no marker at all, is taken to be in the
/// home currency.
const _localMarkerCode = 'INR';

/// Whether an SMS amount in [smsCurrencyCode] (null when the SMS has no
/// currency marker) is in a currency other than [homeCurrencyCode].
/// Cross-currency is not supported, so such SMS are ignored.
bool isForeignCurrency(String? smsCurrencyCode, String homeCurrencyCode) {
  final code = smsCurrencyCode?.trim().toUpperCase() ?? '';
  if (code.isEmpty || code == _localMarkerCode) return false;
  return code != homeCurrencyCode.trim().toUpperCase();
}

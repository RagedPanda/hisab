/// Turns the raw counterparty of a bank SMS ("ola.cabs@axisbank",
/// "MYNTRA DESIGNS") into a readable payee ("Ola", "Myntra Designs").
/// Pure: the raw value is kept by the caller for search.
library;

/// UPI handles and merchant ids whose readable name is not derivable.
const Map<String, String> kKnownPayeeHandles = {
  'ola.cabs': 'Ola',
  'olacabs': 'Ola',
  'olamoney': 'Ola',
  'hpcl.petrol': 'HPCL Petrol',
  'hpcl': 'HPCL Petrol',
  'iocl': 'Indian Oil',
  'bpcl': 'BPCL',
  'blinkit': 'Blinkit',
  'grofers': 'Blinkit',
  'zomato': 'Zomato',
  'swiggy': 'Swiggy',
  'myntra': 'Myntra',
  'amazon': 'Amazon',
  'amazonpay': 'Amazon',
  'flipkart': 'Flipkart',
  'bigbasket': 'BigBasket',
  'jiomart': 'JioMart',
  'uber': 'Uber',
  'rapido': 'Rapido',
  'irctc': 'IRCTC',
  'bookmyshow': 'BookMyShow',
  'paytm': 'Paytm',
  'phonepe': 'PhonePe',
  'bescom': 'BESCOM',
  'airtel': 'Airtel',
  'jio': 'Jio',
  'netflix': 'Netflix',
  'spotify': 'Spotify',
  'dmart': 'DMart',
  'zepto': 'Zepto',
  'dunzo': 'Dunzo',
  'makemytrip': 'MakeMyTrip',
  'redbus': 'redBus',
  'cred': 'CRED',
  'nykaa': 'Nykaa',
  'ajio': 'AJIO',
  'meesho': 'Meesho',
  'pharmeasy': 'PharmEasy',
  'zerodha': 'Zerodha',
  'groww': 'Groww',
  'upstox': 'Upstox',
  'licindia': 'LIC',
  'lic': 'LIC',
  'tataplay': 'Tata Play',
  'bsnl': 'BSNL',
  'bses': 'BSES',
  'mobikwik': 'MobiKwik',
  'hotstar': 'Hotstar',
  'youtube': 'YouTube',
  'googleplay': 'Google Play',
  'decathlon': 'Decathlon',
  'licious': 'Licious',
  'eatsure': 'EatSure',
  'cultfit': 'cult.fit',
  'fastag': 'FASTag',
};

/// All-caps words up to this length read as acronyms ("SBI ATM"); longer
/// shouting words are title-cased ("GREEN LEAF" -> "Green Leaf").
const int _acronymMaxLength = 3;

/// Salutations banks put before a person's name ("Mr PRADEEP KUMAR").
final _honorific = RegExp(r'^(?:mr|mrs|ms|miss|m/s|shri|smt|dr)\.?\s+', caseSensitive: false);

/// Merchant QR and phone-number handles ("paytmqr2810050501@paytm",
/// "q123456789@ybl", "9876543210@ybl") carry no readable name, so the VPA
/// is shown as is rather than as a string of digits.
final _opaqueHandle = RegExp(r'\d{6,}|^paytmqr|^bharatpe|^gpay-|^upiqr', caseSensitive: false);

bool isVpa(String raw) => raw.contains('@') && !raw.trim().contains(' ');

String normalisePayee(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;
  final vpa = isVpa(trimmed);
  final local = vpa ? trimmed.substring(0, trimmed.indexOf('@')) : trimmed.replaceFirst(_honorific, '');
  final known = _knownName(local);
  if (known != null) return known;
  if (vpa && _opaqueHandle.hasMatch(local)) return trimmed;
  final words = local.replaceAll(RegExp(r'[._\-]+'), ' ').split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
  final readable = words.where((word) => !RegExp(r'^\d+$').hasMatch(word)).map(_titleCase).join(' ');
  return readable.isEmpty ? trimmed : readable;
}

/// Whether [raw] (a VPA or a name) is one of [kKnownPayeeHandles]' merchants.
bool isKnownMerchantPayee(String raw) {
  final trimmed = raw.trim();
  final local = isVpa(trimmed) ? trimmed.substring(0, trimmed.indexOf('@')) : trimmed;
  return _knownName(local) != null;
}

/// Whether [raw] is a VPA with no readable name in it (merchant QR codes,
/// phone-number handles), which [normalisePayee] returns unchanged.
bool isOpaqueVpa(String raw) {
  final trimmed = raw.trim();
  return isVpa(trimmed) && _opaqueHandle.hasMatch(trimmed.substring(0, trimmed.indexOf('@')));
}

String? _knownName(String local) {
  final lower = local.toLowerCase();
  final direct = kKnownPayeeHandles[lower];
  if (direct != null) return direct;
  final stem = lower.replaceAll(RegExp(r'[._\-\s]?\d+$'), '');
  if (stem != lower && kKnownPayeeHandles[stem] != null) return kKnownPayeeHandles[stem];
  final firstToken = lower.split(RegExp(r'[._\-\s]+')).first;
  return kKnownPayeeHandles[firstToken];
}

String _titleCase(String word) {
  final isAllCaps = word == word.toUpperCase();
  final isAllLower = word == word.toLowerCase();
  if (isAllCaps && word.length <= _acronymMaxLength) return word;
  if (!isAllCaps && !isAllLower) return word;
  return word[0].toUpperCase() + word.substring(1).toLowerCase();
}

/// Note stored with an SMS entry: the bank reference plus the raw VPA when the
/// payee was rewritten, so the original handle stays searchable.
String smsEntryNote({required String? reference, required String? rawCounterparty}) {
  final raw = rawCounterparty?.trim();
  return [
    if (reference != null) 'Ref $reference',
    if (raw != null && raw.isNotEmpty && normalisePayee(raw) != raw) raw,
  ].join(' · ');
}

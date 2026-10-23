/// Maps DLT sender ids (e.g. "VM-HDFCBK-S", "AD-SBIINB") to bank names.
///
/// A DLT sender id is `<operator+circle>-<6-char header>[-<type>]`, for
/// example `XX-HDFCBK` or `JD-ICICIT-S`. The type suffix is S (service),
/// T (transactional), G (government) or P (promotional).
library;

const Map<String, String> _bankCodes = {
  'HDFCBK': 'HDFC Bank',
  'HDFCBN': 'HDFC Bank',
  'SBIINB': 'SBI',
  'SBIOTP': 'SBI',
  'SBYONO': 'SBI',
  'SBIUPI': 'SBI',
  'SBIPSG': 'SBI',
  'SBICRD': 'SBI Card',
  'SBIPRM': 'SBI Card',
  'SBIBNK': 'SBI',
  'ATMSBI': 'SBI',
  'CBSSBI': 'SBI',
  'ICICIB': 'ICICI Bank',
  'ICICIT': 'ICICI Bank',
  'ICICIO': 'ICICI Bank',
  'AXISBK': 'Axis Bank',
  'AXISB': 'Axis Bank',
  'AXISCR': 'Axis Bank',
  'KOTAKB': 'Kotak Bank',
  'KOTAKM': 'Kotak Bank',
  'PNBSMS': 'PNB',
  'PUNBNK': 'PNB',
  'BOBTXN': 'Bank of Baroda',
  'BOBSMS': 'Bank of Baroda',
  'BOBCRD': 'BOBCARD',
  'BOBCRT': 'BOBCARD',
  'CANBNK': 'Canara Bank',
  'CNRBNK': 'Canara Bank',
  'UNIONB': 'Union Bank',
  'UNIBNK': 'Union Bank',
  'UBOIND': 'Union Bank',
  'IDFCFB': 'IDFC First Bank',
  'IDFCBK': 'IDFC First Bank',
  'YESBNK': 'Yes Bank',
  'YESBK': 'Yes Bank',
  'INDUSB': 'IndusInd Bank',
  'INDUSL': 'IndusInd Bank',
  'INDBNK': 'Indian Bank',
  'IOBCHN': 'Indian Overseas Bank',
  'CENTBK': 'Central Bank',
  'BOIIND': 'Bank of India',
  'MAHABK': 'Bank of Maharashtra',
  'UCOBNK': 'UCO Bank',
  'FEDBNK': 'Federal Bank',
  'FEDFIB': 'Federal Bank',
  'RBLBNK': 'RBL Bank',
  'RBLCRD': 'RBL Credit Card',
  'AUBANK': 'AU Small Finance Bank',
  'AUSFBK': 'AU Small Finance Bank',
  'BANDHN': 'Bandhan Bank',
  'KVBANK': 'Karur Vysya Bank',
  'SIBANK': 'South Indian Bank',
  'CITIBK': 'Citi Bank',
  'HSBCIN': 'HSBC',
  'SCBANK': 'Standard Chartered',
  'DBSBNK': 'DBS Bank',
  'AMEXIN': 'American Express',
  'AMEX': 'American Express',
  'ONECRD': 'OneCard',
  'PAYTMB': 'Paytm Payments Bank',
  'PYTMBK': 'Paytm Payments Bank',
  'AIRBNK': 'Airtel Payments Bank',
  'FINOBK': 'Fino Payments Bank',
  'JIOPBK': 'Jio Payments Bank',
  'JUPITR': 'Jupiter',
  'FIMNEY': 'Fi Money',
  'NIYOGB': 'Niyo',
  'SLICEI': 'Slice',
  'PHONPE': 'PhonePe',
  'GPAYIN': 'Google Pay',
  'PAYTMM': 'Paytm',
  'AMZPAY': 'Amazon Pay',
  'CREDIN': 'CRED',
  'MOBKWK': 'MobiKwik',
};

/// Returns the bank name for a sender id, or null if it is not a known bank.
String? bankFromSender(String sender) {
  final cleaned = sender.toUpperCase().trim();
  final parts = cleaned.split(RegExp(r'[-_ ]'));
  for (final part in parts) {
    final bank = _bankCodes[part];
    if (bank != null) return bank;
  }
  for (final entry in _bankCodes.entries) {
    if (cleaned.contains(entry.key)) return entry.value;
  }
  return null;
}

final _dltSender = RegExp(r'^[A-Z]{2}-([A-Z0-9]{5,6})(?:-([STPG]))?$');

/// The 6-character header of a DLT sender id ("XX-HDFCBK-S" -> "HDFCBK"),
/// or null when [sender] is not in DLT form (a phone number, "PASTED").
String? dltHeader(String sender) => _dltSender.firstMatch(sender.toUpperCase().trim())?.group(1);

/// True for a DLT id with the promotional suffix ("VM-HDFCBK-P"). Banks
/// send offers on these headers, never transaction alerts.
bool isPromotionalSender(String sender) => _dltSender.firstMatch(sender.toUpperCase().trim())?.group(2) == 'P';

/// Only a known bank or payment app header counts. Any 6-character DLT
/// header (VM-SWIGGY, JM-MYNTRA) is not enough on its own: an unknown sender
/// must carry a transaction signal in the text instead (see the parser).
bool looksLikeBankSender(String sender) => bankFromSender(sender) != null;

/// Bank names as they appear inside message bodies, used when the sender
/// is not a known header (a pasted or shared SMS). Names match
/// [_bankCodes] so the account key is the same either way.
final List<(RegExp, String)> _bodyBankNames = [
  (RegExp(r'\bsbi\s*(?:credit\s*)?card\b', caseSensitive: false), 'SBI Card'),
  (RegExp(r'\bbob\s*card\b|\bbobcard\b', caseSensitive: false), 'BOBCARD'),
  (RegExp(r'\bhdfc\s*bank\b|\bhdfc\b', caseSensitive: false), 'HDFC Bank'),
  (RegExp(r'\bicici\b', caseSensitive: false), 'ICICI Bank'),
  (RegExp(r'\baxis\s*bank\b', caseSensitive: false), 'Axis Bank'),
  (RegExp(r'\bkotak\b', caseSensitive: false), 'Kotak Bank'),
  (RegExp(r'\bidfc\b', caseSensitive: false), 'IDFC First Bank'),
  (RegExp(r'\byes\s*bank\b', caseSensitive: false), 'Yes Bank'),
  (RegExp(r'\bindusind\b', caseSensitive: false), 'IndusInd Bank'),
  (RegExp(r'\bau\s*(?:small\s*finance\s*)?bank\b', caseSensitive: false), 'AU Small Finance Bank'),
  (RegExp(r'\bfederal\s*bank\b', caseSensitive: false), 'Federal Bank'),
  (RegExp(r'\bcanara\s*bank\b', caseSensitive: false), 'Canara Bank'),
  (RegExp(r'\bunion\s*bank\b', caseSensitive: false), 'Union Bank'),
  (RegExp(r'\bbank\s*of\s*baroda\b', caseSensitive: false), 'Bank of Baroda'),
  (RegExp(r'\bpunjab\s*national\s*bank\b|\bpnb\b', caseSensitive: false), 'PNB'),
  (RegExp(r'\bstate\s*bank\s*of\s*india\b|\bsbi\b', caseSensitive: false), 'SBI'),
  (RegExp(r'\bamerican\s*express\b|\bamex\b', caseSensitive: false), 'American Express'),
  (RegExp(r'\brbl\s*bank\b', caseSensitive: false), 'RBL Bank'),
  (RegExp(r'\bonecard\b', caseSensitive: false), 'OneCard'),
  (RegExp(r'\bhsbc\b', caseSensitive: false), 'HSBC'),
  (RegExp(r'\bpaytm\s*(?:wallet|payments\s*bank)\b', caseSensitive: false), 'Paytm'),
  (RegExp(r'\bamazon\s*pay\s*(?:balance|wallet)\b', caseSensitive: false), 'Amazon Pay'),
  (RegExp(r'\bmobikwik\b', caseSensitive: false), 'MobiKwik'),
];

/// The bank named earliest in [body], or null. UPI handles such as
/// `@oksbi` never match because the name must stand as its own word.
String? bankFromBody(String body) {
  String? best;
  var bestIndex = body.length;
  for (final (pattern, name) in _bodyBankNames) {
    final match = pattern.firstMatch(body);
    if (match != null && match.start < bestIndex) {
      best = name;
      bestIndex = match.start;
    }
  }
  return best;
}

/// Banks send from alphanumeric DLT headers ("AD-HDFCBK"); people send from
/// phone numbers. Mirrors `SmsCapturePolicy.isBankLikeSender` on Android so
/// the receiver and the inbox catch-up agree on which messages to look at.
bool isBusinessSender(String sender) => RegExp(r'[A-Za-z]').hasMatch(sender);

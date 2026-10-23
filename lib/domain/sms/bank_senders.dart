/// Maps DLT sender ids (e.g. "VM-HDFCBK-S", "AD-SBIINB") to bank names.
library;

const Map<String, String> _bankCodes = {
  'HDFCBK': 'HDFC Bank',
  'HDFCBN': 'HDFC Bank',
  'SBIINB': 'SBI',
  'SBIUPI': 'SBI',
  'SBIPSG': 'SBI',
  'SBICRD': 'SBI Card',
  'SBIBNK': 'SBI',
  'ATMSBI': 'SBI',
  'CBSSBI': 'SBI',
  'ICICIB': 'ICICI Bank',
  'ICICIT': 'ICICI Bank',
  'AXISBK': 'Axis Bank',
  'AXISB': 'Axis Bank',
  'KOTAKB': 'Kotak Bank',
  'KOTAKM': 'Kotak Bank',
  'PNBSMS': 'PNB',
  'PUNBNK': 'PNB',
  'BOBTXN': 'Bank of Baroda',
  'BOBSMS': 'Bank of Baroda',
  'CANBNK': 'Canara Bank',
  'UNIONB': 'Union Bank',
  'UNIBNK': 'Union Bank',
  'IDFCFB': 'IDFC First Bank',
  'IDFCBK': 'IDFC First Bank',
  'YESBNK': 'Yes Bank',
  'INDUSB': 'IndusInd Bank',
  'INDBNK': 'Indian Bank',
  'IOBCHN': 'Indian Overseas Bank',
  'CENTBK': 'Central Bank',
  'BOIIND': 'Bank of India',
  'MAHABK': 'Bank of Maharashtra',
  'UCOBNK': 'UCO Bank',
  'FEDBNK': 'Federal Bank',
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

/// Only a known bank or payment app header counts. Any 6-character DLT
/// header (VM-SWIGGY, JM-MYNTRA) is not enough on its own: an unknown sender
/// must carry a transaction signal in the text instead (see the parser).
bool looksLikeBankSender(String sender) => bankFromSender(sender) != null;

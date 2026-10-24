/// Parses Indian bank / UPI / card transaction SMS into [ParsedTransaction].
/// Pure, regex based, tolerant of the many formats banks use. Returns null
/// for OTPs, promotions, balance-only alerts, payment requests, mandate
/// set-up and pre-debit notices, failures and anything without a clear
/// amount and direction.
library;

import '../../core/money.dart';
import 'bank_senders.dart';
import 'parsed_transaction.dart';

const _currencyPrefix = r'(?:rs\.?|inr|₹|amt[:.]?|usd|eur|gbp|aed|sgd|aud|cad|jpy|\$|€|£)';
const _number = r'([0-9][0-9,]*(?:\.\d{1,2})?)';

final _amountPattern = RegExp('$_currencyPrefix\\s*:?\\s*$_number', caseSensitive: false);
final _bareAmountPattern = RegExp(
  '(?:debited|credited|withdrawn|spent)\\s+(?:by|with|for|of)?\\s*$_number',
  caseSensitive: false,
);
final _currencyMarker = RegExp(_currencyPrefix, caseSensitive: false);
const _markerCodes = {
  'rs': 'INR', 'inr': 'INR', '₹': 'INR',
  'usd': 'USD', r'$': 'USD', 'eur': 'EUR', '€': 'EUR', 'gbp': 'GBP', '£': 'GBP',
  'aed': 'AED', 'sgd': 'SGD', 'aud': 'AUD', 'cad': 'CAD', 'jpy': 'JPY',
};

final _balancePattern = RegExp(
  '(?:avl(?:bl)?\\.?|avb|available|avail|updated|clear|net|total|closing|new)?\\s*(?:bal(?:ance)?)\\s*(?:is|:|-|of)?\\s*$_currencyPrefix?\\s*:?\\s*$_number',
  caseSensitive: false,
);
final _limitPattern = RegExp(
  '(?:avl|avbl|available|avail)\\.?\\s*(?:credit\\s*)?(?:limit|lmt)\\s*(?:is|:)?\\s*$_currencyPrefix?\\s*:?\\s*$_number',
  caseSensitive: false,
);

final _bankAccountPattern =
    RegExp(r'\b(?:a/c|acct|account|acc|ac)\.?\s*(?:no\.?)?\s*(?:ending|ending with|ending in|xx+|x+|\*+)?\s*[-:]?\s*(?:\d{0,6}[xX*]+)?(\d{3,8})\b', caseSensitive: false);
final _accountPatterns = [
  _bankAccountPattern,
  // "4xxx xxxx xxxx 1234": a card number masked in groups of four.
  RegExp(r'\b[0-9xX*]{4}[ -][xX*]{4}[ -][xX*]{4}[ -](\d{4})\b'),
  RegExp(r'(?:card|credit card|debit card)\s*(?:no\.?|number)?\s*(?:ending|ending with|ending in)?\s*[:\-]?\s*[xX*]*\s?(\d{4,8})\b', caseSensitive: false),
  RegExp(r'\bending\s*(?:with|in)?\s*[:\-]?\s*[xX*]*(\d{4})\b', caseSensitive: false),
  RegExp(r'\b(?:xx|x{2,}|\*{2,})\s?(\d{4,8})\b', caseSensitive: false),
];

/// A loan account named next to the paying account ("EMI for Loan A/c XX9876
/// debited from A/c XX1234") is not the account the money left.
final _loanAccountPrefix = RegExp(r'\bloan\s*(?:account\s*)?$', caseSensitive: false);

final _refPatterns = [
  RegExp(r'(?:ref(?:erence)?|rrn)\s*(?:no\.?|number|id)?\s*[:.\-]?\s*(\d{6,})', caseSensitive: false),
  RegExp(r'\b(?:upi|imps|neft|rtgs)\s*[:/\-]?\s*(\d{9,})', caseSensitive: false),
  RegExp(r'\b(?:ref|rrn)\s*[:.\-]?\s*([A-Z0-9]{8,})', caseSensitive: false),
];

final _numericDate = RegExp(r'\b(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})\b');
final _namedDate = RegExp(
  r'\b(\d{1,2})[-/ ]?(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*[-/ ,]*(\d{2,4})\b',
  caseSensitive: false,
);
final _isoDate = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b');
final _clockTime = RegExp(r'\b([01]?\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?\b(?:\s*([ap])\.?m\b\.?)?', caseSensitive: false);
const _months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];

/// One-time codes and login secrets. Their text is never stored.
const _otpPhrases = ['otp', 'one time password', 'verification code', 'do not share', 'never share', 'password'];

/// Marketing. Its text is never stored.
const _promotionPhrases = [
  'pre-approved', 'pre approved', 'apply now', 'offer', 'cashback upto', 'cashback up to',
  'eligible', 'congratulations', 'voucher', 'reward points',
  '% off', 'use code', 'promo code', 'coupon', 'shop now', 'buy now', 'order now', 'book now',
  'hurry', 'limited period', 'limited time', 't&c apply', 'tnc apply', 'sale is live',
];

/// Wording only a real account or card movement carries: a debit or credit
/// verb, an account reference, or a masked card or account number.
final _transactionSignal = RegExp(
  r'\b(?:debited|credited|withdrawn|spent)\b|\b(?:a/c|acct)\b|(?:[xX*]{2,}\s?\d{3,6}\b)|\bending\s*(?:with|in)?\s*[:\-]?\s*\d{4}\b',
  caseSensitive: false,
);

const _rejectPhrases = [
  ..._otpPhrases,
  ..._promotionPhrases,
  'will be debited', 'will be credited', 'is due', 'due on', 'due by', 'overdue',
  'has requested', 'payment request', 'requested money', 'collect request', 'requesting',
  'declined', 'failed', 'unsuccessful', 'could not be', 'not completed', 'pending',
  'minimum amount due', 'total amount due', 'statement', 'bill generated', 'has been generated',
  'logged in', 'kyc', 'block your card',
  'for processing', 'low balance', 'insufficient', 'reminder',
  'maintain minimum', 'minimum balance',
];

/// Marketing wording, matched as whole words so a merchant such as
/// "ERWIN STORES" is not mistaken for "win".
final _promotion = RegExp(
  r'\b(?:t&c|tnc apply|shop now|hurry|limited period|get flat|get upto|get up to|enjoy|exclusive|upgrade now|'
  r'invest now|avail now|lowest interest|instant loan|limit enhancement|limit increase|win|lucky draw)\b',
  caseSensitive: false,
);

/// "call from your registered mobile" appears in real debit alerts and says
/// nothing about a mandate being set up.
final _registeredContact = RegExp(r'registered (?:mobile|email|e-mail|number|no)', caseSensitive: false);

/// Autopay / NACH / e-mandate wording. The debit itself is a transaction;
/// setting the mandate up, changing it or warning before it runs is not.
final _autopayContext = RegExp(
  r'auto[- ]?pay|auto[- ]?debit|\bnach\b|\bach[- ]?d(?:r|ebit)\b|e-?mandate|\bmandate\b|standing instruction|\bumrn\b',
  caseSensitive: false,
);
final _mandateSetup = RegExp(
  r'registered|registration|created|\bset ?up\b|revoked|cancel+ed|paused|modified|upcoming|scheduled|pre-?debit|\brequest',
  caseSensitive: false,
);

/// "Payment of Rs X received on your Credit Card": the card issuer
/// acknowledging a bill payment. The money already left as a bank-side
/// debit (an expense), so this message is skipped: it must never become
/// income and the payment must not count twice.
final _cardPaymentReceived = RegExp(
  r'\breceived (?:a |your )?payment\b|\bpayment\b(?:[^.;!]|\.(?=\d)){0,90}?\b(?:received|credited|has been posted)\b|\bthank you for (?:the |your )?payment\b',
  caseSensitive: false,
);
final _salaryWords = RegExp(r'\bsalary\b|\bsal\b|\bsal[-/]|payroll|\bsalaries\b', caseSensitive: false);
final _emiWords = RegExp(r'\bemi\b|\bloan\b', caseSensitive: false);
final _walletProvider = RegExp(r'wallet|paytm|mobikwik|amazon pay|phonepe|freecharge|airtel money', caseSensitive: false);
final _walletLoad = RegExp(
  r'add(?:ed)? money|\badded to\b|top[- ]?up|\bload(?:ed)? (?:money|wallet)|wallet load',
  caseSensitive: false,
);

const _debitWords = [
  'debited', 'spent', 'withdrawn', 'paid', 'sent', 'purchase', 'debit of', 'dr.', 'deducted',
  'transferred from', 'txn of', 'payment of', 'charged', 'debit card', 'done at',
  'debit by', 'has a debit', 'txn rs', 'txn inr', 'withdrawal of', 'used for', 'used at',
  // "Transaction of Rs.799.00 made on your SBI Credit Card ending 3456".
  'made on your', 'made using your', 'made at',
];
const _creditWords = [
  'credited', 'received', 'deposited', 'refund', 'cashback', 'cr.', 'credit of', 'reversed',
  'reversal', 'added to', 'credit by', 'has a credit',
];

ParsedTransaction? parseBankSms({
  required String sender,
  required String body,
  required DateTime receivedAt,
}) {
  final text = _normalizedText(body);
  final lower = text.toLowerCase();
  if (text.isEmpty) return null;
  if (_isIgnorable(sender, lower)) return null;

  final balanceMatch = _balancePattern.firstMatch(text);
  final limitMatch = _limitPattern.firstMatch(text);
  final amountMatch = _firstAmountOutside(text, [balanceMatch, limitMatch]);
  final amountText = amountMatch?.group(1) ?? _bareAmountPattern.firstMatch(text)?.group(1);
  if (amountText == null) return null;
  final amountMinor = parseAmountToMinor(amountText);
  if (amountMinor == null || amountMinor == 0) return null;

  final reversal = _isReversal(lower);
  if (!reversal && _isCardPaymentAcknowledgement(text, lower)) return null;
  final direction = reversal && _reversalIsCredit(lower) ? TxnDirection.credit : _direction(lower);
  if (direction == null) return null;

  final currency = (amountMatch == null ? null : _currencyCodeOf(amountMatch)) ?? 'INR';

  final isCreditCard = (lower.contains('credit card') && !_paysCardBillFromAccount(lower)) ||
      lower.contains('credit limit') ||
      limitMatch != null ||
      (RegExp(r'\bcard\b').hasMatch(lower) && !lower.contains('debit card') && !lower.contains('a/c'));
  final instrument = _instrument(lower);
  final kind = _kind(
    lower: lower,
    direction: direction,
    instrument: instrument,
    isCreditCard: isCreditCard,
    reversal: reversal,
  );

  return ParsedTransaction(
    direction: direction,
    amountMinor: amountMinor,
    currency: currency,
    kind: kind,
    instrument: kind == TxnKind.walletTopUp && instrument == Instrument.unknown ? Instrument.wallet : instrument,
    occurredAt: transactionTime(text, receivedAt),
    raw: text,
    bank: bankFromSender(sender) ?? bankFromBody(text),
    accountLast4: _account(text),
    isCreditCard: isCreditCard,
    counterparty: _counterparty(text, direction),
    balanceMinor: balanceMatch == null ? null : parseAmountToMinor(balanceMatch.group(1)!),
    availableLimitMinor: limitMatch == null ? null : parseAmountToMinor(limitMatch.group(1)!),
    reference: _reference(text),
  );
}

String _normalizedText(String body) => normalizeMathGlyphs(body).replaceAll(RegExp(r'\s+'), ' ').trim();

/// True when [body] is an OTP or a promotion by the same wording the parser
/// rejects, whatever the sender. A refund or reversal is never flagged, so
/// the parser and this check always agree on what can become an entry.
bool isOtpOrPromotionSms(String body) {
  final lower = _normalizedText(body).toLowerCase();
  return [..._otpPhrases, ..._promotionPhrases].any(lower.contains) && !_isReversal(lower);
}

/// True when [body] reads like a real transaction, so a message from a
/// sender that is not a known bank still gets parsed. OTPs and promotions
/// never count, even when they mention an amount being credited.
bool hasTransactionSignal(String body) => _transactionSignal.hasMatch(_normalizedText(body)) && !isOtpOrPromotionSms(body);

/// Some banks (SBI Card) send letters from the Unicode Mathematical
/// Alphanumeric block (𝗌𝗉𝖾𝗇𝗍) to dodge filters. Map them back to ASCII.
String normalizeMathGlyphs(String input) {
  if (!input.runes.any((r) => r >= 0x1D400 && r <= 0x1D7FF)) return input;
  final out = StringBuffer();
  for (final rune in input.runes) {
    if (rune >= 0x1D400 && rune <= 0x1D6A3) {
      final offset = (rune - 0x1D400) % 52;
      out.writeCharCode(offset < 26 ? 0x41 + offset : 0x61 + offset - 26);
    } else if (rune >= 0x1D7CE && rune <= 0x1D7FF) {
      out.writeCharCode(0x30 + (rune - 0x1D7CE) % 10);
    } else {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}

final _cardBillPayee = RegExp(r'credit card (?:bill|payment|dues)|card bill|towards [^.;]{0,30}credit card');
final _bankAccountWord = RegExp(r'\ba/c|\bacct\b|\baccount\b|\bac\b');

/// "Rs 15,000 debited from A/c XX7781 towards credit card bill": the card is
/// the payee, the money left a bank account.
bool _paysCardBillFromAccount(String lower) => _cardBillPayee.hasMatch(lower) && _bankAccountWord.hasMatch(lower);

bool _isCardPaymentAcknowledgement(String text, String lower) =>
    _cardPaymentReceived.hasMatch(text) && lower.contains('card') && !_paysCardBillFromAccount(lower);

/// OTPs, promotions, set-up notices and other messages that move no money.
bool _isIgnorable(String sender, String lower) {
  if (isPromotionalSender(sender)) return true;
  if (_autopayContext.hasMatch(lower) && _mandateSetup.hasMatch(lower.replaceAll(_registeredContact, ''))) return true;
  if (_promotion.hasMatch(lower)) return true;
  return _rejectPhrases.any(lower.contains) && !_isReversal(lower);
}

/// A refund or reversal puts money back unless the bank says it debited
/// you ("Rs 100 debited as reversal of an erroneous credit").
bool _reversalIsCredit(String lower) =>
    !lower.contains('debited') || lower.contains('credited') || lower.contains('reversed to') || lower.contains('refunded');

TxnKind _kind({
  required String lower,
  required TxnDirection direction,
  required Instrument instrument,
  required bool isCreditCard,
  required bool reversal,
}) {
  final isDebit = direction == TxnDirection.debit;
  if (reversal && !isDebit) return TxnKind.refund;
  if (!isDebit && _salaryWords.hasMatch(lower)) return TxnKind.salary;
  if (_walletProvider.hasMatch(lower) && _walletLoad.hasMatch(lower)) return TxnKind.walletTopUp;
  if (isDebit && instrument == Instrument.atm) return TxnKind.atmWithdrawal;
  if (isDebit && _emiWords.hasMatch(lower)) return TxnKind.emi;
  if (isDebit && _autopayContext.hasMatch(lower)) return TxnKind.autopay;
  if (isDebit && (isCreditCard || instrument == Instrument.card)) return TxnKind.cardSpend;
  return TxnKind.general;
}

bool _isReversal(String lower) =>
    (lower.contains('reversed') || lower.contains('reversal') || lower.contains('refund')) &&
    !lower.contains('otp') &&
    !lower.contains('will be');

/// ISO code of the currency marker in front of an amount, or null when the
/// marker names no currency (such as "Amt").
String? _currencyCodeOf(RegExpMatch amountMatch) {
  final marker = _currencyMarker.matchAsPrefix(amountMatch.group(0)!)?.group(0);
  if (marker == null) return null;
  return _markerCodes[marker.toLowerCase().replaceAll(RegExp(r'[.:]'), '')];
}

/// ISO code of the currency the SMS amount is in, or null when the amount
/// has no currency marker. Works on SMS the parser cannot read in full.
String? smsCurrencyCode(String body) {
  final text = _normalizedText(body);
  final amountMatch = _firstAmountOutside(text, [_balancePattern.firstMatch(text), _limitPattern.firstMatch(text)]) ??
      _amountPattern.firstMatch(text);
  return amountMatch == null ? null : _currencyCodeOf(amountMatch);
}

RegExpMatch? _firstAmountOutside(String text, List<RegExpMatch?> excluded) {
  for (final match in _amountPattern.allMatches(text)) {
    final inside = excluded.any((e) => e != null && match.start >= e.start && match.end <= e.end);
    if (!inside) return match;
  }
  return null;
}

TxnDirection? _direction(String lower) {
  int firstIndex(List<String> words) {
    var best = -1;
    for (final word in words) {
      final index = lower.indexOf(word);
      if (index >= 0 && (best < 0 || index < best)) best = index;
    }
    return best;
  }

  final debitAt = firstIndex(_debitWords);
  final creditAt = firstIndex(_creditWords);
  if (debitAt < 0 && creditAt < 0) return null;
  if (debitAt < 0) return TxnDirection.credit;
  if (creditAt < 0) return TxnDirection.debit;
  return debitAt <= creditAt ? TxnDirection.debit : TxnDirection.credit;
}

Instrument _instrument(String lower) {
  if (RegExp(r'\batm\b|cash withdrawal|cash wdl|withdrawn|\bawb\b').hasMatch(lower)) return Instrument.atm;
  if (lower.contains('upi') || lower.contains('vpa') || RegExp(r'\w@\w').hasMatch(lower)) return Instrument.upi;
  if (RegExp(r'\bemi\b|\bloan\b').hasMatch(lower)) return Instrument.emi;
  if (lower.contains('neft')) return Instrument.neft;
  if (lower.contains('imps')) return Instrument.imps;
  if (lower.contains('rtgs')) return Instrument.rtgs;
  if (lower.contains('cheque') || lower.contains('chq')) return Instrument.cheque;
  if (lower.contains('wallet') || lower.contains('amazon pay balance')) return Instrument.wallet;
  if (lower.contains('card') || lower.contains('pos ')) return Instrument.card;
  if (lower.contains('netbanking') || lower.contains('net banking') || lower.contains('internet banking')) {
    return Instrument.netbanking;
  }
  return Instrument.unknown;
}

String? _account(String text) {
  for (final pattern in _accountPatterns) {
    for (final match in pattern.allMatches(text)) {
      final isLoanAccount = pattern == _bankAccountPattern && _loanAccountPrefix.hasMatch(text.substring(0, match.start));
      if (isLoanAccount) continue;
      final digits = match.group(1)!;
      return digits.length > 4 ? digits.substring(digits.length - 4) : digits;
    }
  }
  return null;
}

String? _reference(String text) {
  for (final pattern in _refPatterns) {
    final match = pattern.firstMatch(text);
    if (match != null) return match.group(1);
  }
  return null;
}

/// When the transaction happened. The SMS date wins over the time we
/// received the message; the SMS clock time (if any) wins over our clock.
/// A same-day SMS without a clock time takes the received time rather than
/// midnight, so entries keep their order within the day.
DateTime transactionTime(String text, DateTime receivedAt) {
  final found = _dateMatch(text);
  if (found == null) return receivedAt;
  final (date, span) = found;
  // Look for the clock after the date so "2026-08-21:05:20:26" reads 05:20:26.
  final clock = _clockTime.firstMatch(text.substring(span.end)) ?? _clockTime.firstMatch(text.substring(0, span.start));
  if (clock != null) {
    return DateTime(date.year, date.month, date.day, _hour24(clock), int.parse(clock.group(2)!), int.parse(clock.group(3) ?? '0'));
  }
  final sameDay = date.year == receivedAt.year && date.month == receivedAt.month && date.day == receivedAt.day;
  return sameDay ? receivedAt : date;
}

/// "08:15 PM" -> 20, "12:05 AM" -> 0; a 24-hour clock is kept as is.
int _hour24(Match clock) {
  final hour = int.parse(clock.group(1)!);
  final meridiem = clock.group(4)?.toLowerCase();
  if (meridiem == null || hour > 12) return hour;
  if (meridiem == 'p') return hour == 12 ? 12 : hour + 12;
  return hour == 12 ? 0 : hour;
}

(DateTime, Match)? _dateMatch(String text) {
  final numeric = _numericDate.firstMatch(text);
  if (numeric != null) {
    final day = int.parse(numeric.group(1)!);
    final month = int.parse(numeric.group(2)!);
    final year = _year(numeric.group(3)!);
    if (month >= 1 && month <= 12 && day >= 1 && day <= 31) return (DateTime(year, month, day), numeric);
  }
  for (final named in _namedDate.allMatches(text)) {
    final month = _months.indexOf(named.group(2)!.toLowerCase()) + 1;
    final day = int.parse(named.group(1)!);
    if (month > 0 && day >= 1 && day <= 31) return (DateTime(_year(named.group(3)!), month, day), named);
  }
  final iso = _isoDate.firstMatch(text);
  if (iso != null) {
    return (DateTime(int.parse(iso.group(1)!), int.parse(iso.group(2)!), int.parse(iso.group(3)!)), iso);
  }
  return null;
}

int _year(String raw) {
  final value = int.parse(raw);
  return raw.length == 2 ? 2000 + value : value;
}

const _name = r"([A-Za-z][A-Za-z0-9 .&\-'*]{2,40}?)";
const _nameEnd =
    r"(?=\s+(?:on|upi|via|using|vide|thru|through|with|avl|avbl|available|bal|dt|dated|not|if|call|sms|info|at|for|credited|debited|has|is|was)\b|\s+(?:ref|rrn|txn|trxn)\w*|\s+\d|[.,;:(]|$)";

final _sharedCounterparty = <RegExp>[
  RegExp(r'\b(?:to|from|by)?\s*vpa\s*[:\-]?\s*([\w.\-]+@[\w]+)', caseSensitive: false),
  RegExp(r'\b(?:to|from|by)\s+([\w.\-]+@[\w]+)', caseSensitive: false),
  RegExp(';\\s*$_name\\s+credited', caseSensitive: false),
  RegExp('\\bupi[-/]\\d+[-/]$_name(?:(?=/)|$_nameEnd)', caseSensitive: false),
  RegExp('\\bneft\\s*cr[-/]\\w+[-/]$_name(?=[-/.]|\$)', caseSensitive: false),
  RegExp('\\binfo\\s*[:\\-]?\\s*(?:[A-Za-z]{2,5}[*/\\-])?(?:\\w*[*/\\-])?$_name(?=[*/.]|\\s+(?:on|avl|available|bal)\\b|\$)', caseSensitive: false),
];
final _debitCounterparty = <RegExp>[
  RegExp('\\b(?:towards|to|at)\\s+$_name$_nameEnd', caseSensitive: false),
  RegExp('\\bon\\s+((?:M/s\\s+)?[A-Z][A-Za-z0-9 .&\\-\']{2,40}?)$_nameEnd', caseSensitive: false),
  RegExp('\\bfor\\s+$_name$_nameEnd', caseSensitive: false),
  // "21-10-26 10:15:22 AMAZON Avl Lmt": merchant straight after the clock time.
  RegExp('\\d{1,2}:\\d{2}(?::\\d{2})?\\s+(?:ist\\s+)?$_name$_nameEnd', caseSensitive: false),
];
final _creditCounterparty = <RegExp>[
  RegExp('\\b(?:from|by)\\s+$_name$_nameEnd', caseSensitive: false),
];

/// "towards UPI to SHIV DAIRY": the payment rail is not part of the name.
final _railPrefix = RegExp(r'^(?:upi|imps|neft|vpa)\s+(?:(?:to|from|by)\s+)?', caseSensitive: false);

const _counterpartyNoise = ['ist', 'your', 'you', 'a/c', 'ac', 'acct', 'account', 'card', 'bank', 'vpa', 'upi', 'the', 'rs', 'inr', 'dispute', 'processing', 'merchant'];

String? _counterparty(String text, TxnDirection direction) {
  final patterns = [
    ..._sharedCounterparty,
    ...(direction == TxnDirection.debit ? _debitCounterparty : _creditCounterparty),
  ];
  for (final pattern in patterns) {
    for (final match in pattern.allMatches(text)) {
      var value = match.group(1)!.trim();
      value = value
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'[.\-*\s]+$'), '')
          .replaceFirst(_railPrefix, '');
      final lower = value.toLowerCase();
      if (value.length < 3) continue;
      if (_counterpartyNoise.contains(lower)) continue;
      if (lower.startsWith('your ') || lower.startsWith('a/c') || lower.contains(' bank') || lower.startsWith('bank ')) continue;
      if (RegExp(r'^\d+$').hasMatch(value)) continue;
      if (RegExp(r'^(?:rs|inr)\.?\s*\d', caseSensitive: false).hasMatch(value)) continue;
      return value;
    }
  }
  return null;
}

/// Whether a message the parser could not read still looks like money moved:
/// it names an amount and is not an OTP, offer, reminder or failure notice.
/// Such messages go to the review queue instead of being dropped. [sender]
/// lets a promotional DLT header count as an offer.
bool looksLikeUnreadTransaction(String body, {String sender = ''}) {
  final text = _normalizedText(body);
  final lower = text.toLowerCase();
  if (text.isEmpty) return false;
  if (_isIgnorable(sender, lower)) return false;
  return _amountPattern.hasMatch(text) || _bareAmountPattern.hasMatch(text);
}


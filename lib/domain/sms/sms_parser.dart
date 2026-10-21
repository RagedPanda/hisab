/// Parses Indian bank / UPI / card transaction SMS into [ParsedTransaction].
/// Pure, regex based, tolerant of the many formats banks use. Returns null
/// for OTPs, promotions, payment requests, mandates, failures and anything
/// without a clear amount and direction.
library;

import '../../core/money.dart';
import 'bank_senders.dart';
import 'parsed_transaction.dart';

const _currencyPrefix = r'(?:rs\.?|inr|₹|amt[:.]?|usd|eur|gbp|aed|sgd|aud|cad|\$|€|£)';
const _number = r'([0-9][0-9,]*(?:\.\d{1,2})?)';

final _amountPattern = RegExp('$_currencyPrefix\\s*:?\\s*$_number', caseSensitive: false);
final _bareAmountPattern = RegExp(
  '(?:debited|credited|withdrawn|spent)\\s+(?:by|with|for|of)?\\s*$_number',
  caseSensitive: false,
);
final _foreignCurrency = RegExp(r'\b(USD|EUR|GBP|AED|SGD|AUD|CAD|JPY)\s*[0-9]', caseSensitive: false);

final _balancePattern = RegExp(
  '(?:avl(?:bl)?\\.?|avb|available|avail|updated|clear|net|total|closing|new)?\\s*(?:bal(?:ance)?)\\s*(?:is|:|-|of)?\\s*$_currencyPrefix?\\s*:?\\s*$_number',
  caseSensitive: false,
);
final _limitPattern = RegExp(
  '(?:avl|avbl|available|avail)\\.?\\s*(?:credit\\s*)?limit\\s*(?:is|:)?\\s*$_currencyPrefix?\\s*:?\\s*$_number',
  caseSensitive: false,
);

final _accountPatterns = [
  RegExp(r'\b(?:a/c|acct|account|acc|ac)\.?\s*(?:no\.?)?\s*(?:ending|ending with|ending in|xx+|x+|\*+)?\s*[-:]?\s*[xX*]*(\d{3,8})\b', caseSensitive: false),
  RegExp(r'(?:card|credit card|debit card)\s*(?:no\.?|number)?\s*(?:ending|ending with|ending in)?\s*[xX*]*(\d{4,8})\b', caseSensitive: false),
  RegExp(r'\b(?:xx|x{2,}|\*{2,})(\d{4,8})\b', caseSensitive: false),
];

final _refPatterns = [
  RegExp(r'(?:ref(?:erence)?|rrn)\s*(?:no\.?|number|id)?\s*[:.\-]?\s*(\d{6,})', caseSensitive: false),
  RegExp(r'\b(?:upi|imps|neft|rtgs)\s*[:/\-]\s*(\d{9,})', caseSensitive: false),
  RegExp(r'\b(?:ref|rrn)\s*[:.\-]?\s*([A-Z0-9]{8,})', caseSensitive: false),
];

final _numericDate = RegExp(r'\b(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})\b');
final _namedDate = RegExp(r'\b(\d{1,2})[-/ ]?([A-Za-z]{3})[-/ ]?(\d{2,4})\b');
final _isoDate = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b');
const _months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];

const _rejectPhrases = [
  'otp', 'one time password', 'verification code', 'do not share',
  'will be debited', 'will be credited', 'is due', 'due on', 'due by', 'overdue',
  'has requested', 'payment request', 'requested money', 'collect request', 'requesting',
  'declined', 'failed', 'unsuccessful', 'could not be', 'not completed', 'pending',
  'pre-approved', 'pre approved', 'apply now', 'offer', 'cashback upto', 'cashback up to',
  'minimum amount due', 'total amount due', 'statement', 'bill generated', 'has been generated',
  'eligible', 'congratulations', 'voucher', 'logged in', 'password', 'kyc', 'block your card',
  'mandate', 'for processing', 'low balance', 'insufficient', 'reminder', 'reward points',
  'maintain minimum', 'minimum balance',
];

const _debitWords = [
  'debited', 'spent', 'withdrawn', 'paid', 'sent', 'purchase', 'debit of', 'dr.', 'deducted',
  'transferred from', 'txn of', 'payment of', 'charged', 'debit card', 'done at',
];
const _creditWords = [
  'credited', 'received', 'deposited', 'refund', 'cashback', 'cr.', 'credit of', 'reversed',
  'reversal', 'added to',
];

ParsedTransaction? parseBankSms({
  required String sender,
  required String body,
  required DateTime receivedAt,
}) {
  final text = normalizeMathGlyphs(body).replaceAll(RegExp(r'\s+'), ' ').trim();
  final lower = text.toLowerCase();
  if (text.isEmpty) return null;
  if (_rejectPhrases.any(lower.contains) && !_isReversal(lower)) return null;

  final balanceMatch = _balancePattern.firstMatch(text);
  final limitMatch = _limitPattern.firstMatch(text);
  final amountMatch = _firstAmountOutside(text, [balanceMatch, limitMatch]);
  final amountText = amountMatch?.group(1) ?? _bareAmountPattern.firstMatch(text)?.group(1);
  if (amountText == null) return null;
  final amountMinor = parseAmountToMinor(amountText);
  if (amountMinor == null || amountMinor == 0) return null;

  final direction = _direction(lower);
  if (direction == null) return null;

  final currency = amountMatch == null
      ? 'INR'
      : _foreignCurrency.firstMatch(amountMatch.group(0)!)?.group(1)?.toUpperCase() ?? 'INR';

  final isCreditCard = lower.contains('credit card') ||
      lower.contains('credit limit') ||
      limitMatch != null ||
      (RegExp(r'\bcard\b').hasMatch(lower) && !lower.contains('debit card') && !lower.contains('a/c'));

  return ParsedTransaction(
    direction: direction,
    amountMinor: amountMinor,
    currency: currency,
    instrument: _instrument(lower),
    occurredAt: _date(text) ?? receivedAt,
    raw: text,
    bank: bankFromSender(sender),
    accountLast4: _account(text),
    isCreditCard: isCreditCard,
    counterparty: _counterparty(text, direction),
    balanceMinor: balanceMatch == null ? null : parseAmountToMinor(balanceMatch.group(1)!),
    availableLimitMinor: limitMatch == null ? null : parseAmountToMinor(limitMatch.group(1)!),
    reference: _reference(text),
  );
}

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

bool _isReversal(String lower) =>
    (lower.contains('reversed') || lower.contains('reversal') || lower.contains('refund')) &&
    !lower.contains('otp') &&
    !lower.contains('will be');

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
  if (lower.contains('wallet')) return Instrument.wallet;
  if (lower.contains('card') || lower.contains('pos ')) return Instrument.card;
  if (lower.contains('netbanking') || lower.contains('net banking') || lower.contains('internet banking')) {
    return Instrument.netbanking;
  }
  return Instrument.unknown;
}

String? _account(String text) {
  for (final pattern in _accountPatterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
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

DateTime? _date(String text) {
  final numeric = _numericDate.firstMatch(text);
  if (numeric != null) {
    final day = int.parse(numeric.group(1)!);
    final month = int.parse(numeric.group(2)!);
    final year = _year(numeric.group(3)!);
    if (month >= 1 && month <= 12 && day >= 1 && day <= 31) return DateTime(year, month, day);
  }
  final named = _namedDate.firstMatch(text);
  if (named != null) {
    final month = _months.indexOf(named.group(2)!.toLowerCase()) + 1;
    final day = int.parse(named.group(1)!);
    if (month > 0 && day >= 1 && day <= 31) return DateTime(_year(named.group(3)!), month, day);
  }
  final iso = _isoDate.firstMatch(text);
  if (iso != null) {
    return DateTime(int.parse(iso.group(1)!), int.parse(iso.group(2)!), int.parse(iso.group(3)!));
  }
  return null;
}

int _year(String raw) {
  final value = int.parse(raw);
  return raw.length == 2 ? 2000 + value : value;
}

const _name = r"([A-Za-z][A-Za-z0-9 .&\-'*]{2,40}?)";
const _nameEnd =
    r"(?=\s+(?:on|upi|via|using|vide|thru|through|with|avl|avbl|available|bal|dt|dated|not|if|call|sms|info|at|for)\b|\s+(?:ref|rrn|txn|trxn)\w*|\s+\d|[.,;:(]|$)";

final _sharedCounterparty = <RegExp>[
  RegExp(r'\bto\s+vpa\s+([\w.\-]+@[\w]+)', caseSensitive: false),
  RegExp(r'\b(?:to|from|by)\s+([\w.\-]+@[\w]+)', caseSensitive: false),
  RegExp(';\\s*$_name\\s+credited', caseSensitive: false),
  RegExp('\\bupi[-/]\\d+[-/]$_name(?=[.,/]|\\s|\$)', caseSensitive: false),
  RegExp('\\bneft\\s*cr[-/]\\w+[-/]$_name(?=[-/.]|\$)', caseSensitive: false),
  RegExp('\\binfo\\s*[:\\-]?\\s*(?:[A-Za-z]{2,5}[*/\\-])?(?:\\w*[*/\\-])?$_name(?=[*/.]|\\s+(?:on|avl|available|bal)\\b|\$)', caseSensitive: false),
];
final _debitCounterparty = <RegExp>[
  RegExp('\\b(?:towards|to|at)\\s+$_name$_nameEnd', caseSensitive: false),
  RegExp('\\bon\\s+((?:M/s\\s+)?[A-Z][A-Za-z0-9 .&\\-\']{2,40}?)$_nameEnd', caseSensitive: false),
  RegExp('\\bfor\\s+$_name$_nameEnd', caseSensitive: false),
];
final _creditCounterparty = <RegExp>[
  RegExp('\\b(?:from|by)\\s+$_name$_nameEnd', caseSensitive: false),
];

const _counterpartyNoise = ['your', 'you', 'a/c', 'ac', 'acct', 'account', 'card', 'bank', 'vpa', 'upi', 'the', 'rs', 'inr', 'dispute', 'processing', 'merchant'];

String? _counterparty(String text, TxnDirection direction) {
  final patterns = [
    ..._sharedCounterparty,
    ...(direction == TxnDirection.debit ? _debitCounterparty : _creditCounterparty),
  ];
  for (final pattern in patterns) {
    for (final match in pattern.allMatches(text)) {
      var value = match.group(1)!.trim();
      value = value.replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'[.\-*\s]+$'), '');
      final lower = value.toLowerCase();
      if (value.length < 3) continue;
      if (_counterpartyNoise.contains(lower)) continue;
      if (lower.startsWith('your ') || lower.startsWith('a/c') || lower.contains(' bank') || lower.startsWith('bank ')) continue;
      if (RegExp(r'^\d+$').hasMatch(value)) continue;
      return value;
    }
  }
  return null;
}

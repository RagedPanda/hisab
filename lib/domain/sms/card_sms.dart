/// Credit card facts a card issuer's SMS carries besides a spend: the
/// statement (total due, minimum due, due date) and a bill payment received
/// on the card. Pure, regex based; the transaction parser ([parseBankSms])
/// still returns null for both, so neither ever becomes an expense or income.
library;

import '../../core/money.dart';
import 'bank_senders.dart';
import 'parsed_transaction.dart';
import 'sms_parser.dart';

/// "Rs", "INR" or "₹": a card statement in any other currency is not read.
const _rupee = r'(?:rs\.?|inr|₹)';
const _separator = r'\s*(?:is|of|:|-|=)?\s*';

final _totalDue = RegExp(
  '\\btotal\\s*(?:amount|amt\\.?)?\\s*(?:due|outstanding|payable)$_separator$_rupee\\s*:?\\s*$smsNumberPattern',
  caseSensitive: false,
);
final _minimumDue = RegExp(
  '\\bmin(?:imum|\\.)?\\s*(?:amount|amt\\.?)?\\s*(?:due|payable)$_separator$_rupee\\s*:?\\s*$smsNumberPattern',
  caseSensitive: false,
);

/// Wording right before the due date: "Due Date 05-11-26", "due by 5 Nov".
final _dueDateMarker = RegExp(r'\b(?:due\s*(?:date|dt\.?|by|on)|pay(?:ment)?\s*(?:by|before))\b', caseSensitive: false);

/// Wording right before the statement date: "statement dated 12/10/26".
final _statementDateMarker = RegExp(r'\b(?:dated|generated on|statement date|stmt date|statement of|statement for)\b', caseSensitive: false);

final _cardWord = RegExp(r'\bcard\b|\bcc\b', caseSensitive: false);

/// A bill that is already late, or a notice about a missed payment, is not
/// a statement: its figures include charges and its date has passed.
final _notStatement = RegExp(r'overdue|\bmissed\b|\blate (?:fee|payment)|not (?:been )?received|\bdeclined\b|\bfailed\b', caseSensitive: false);

/// What a credit card statement SMS says. Immutable.
class CardStatementSms {
  const CardStatementSms({
    required this.totalDueMinor,
    required this.dueDate,
    required this.receivedAt,
    this.minimumDueMinor,
    this.statementDate,
    this.bank,
    this.cardLast4,
  });

  final int totalDueMinor;
  final int? minimumDueMinor;

  /// Calendar date the bill is due.
  final DateTime dueDate;

  /// The statement date when the message states one.
  final DateTime? statementDate;
  final DateTime receivedAt;
  final String? bank;
  final String? cardLast4;

  /// The card account this statement belongs to (see [smsAccountKey]).
  String get accountKey => smsAccountKey(bank: bank, isCreditCard: true, last4: cardLast4);
}

/// Reads a card statement SMS ("Statement for HDFC Bank Credit Card XX4521:
/// Total Amt Due Rs 23,456.78, Min Amt Due Rs 1,180, Due Date 05-11-26").
/// Null for anything else: it must name a card, a total due in rupees and a
/// due date, and not be an OTP, an offer or an overdue notice.
CardStatementSms? parseCardStatementSms({required String sender, required String body, required DateTime receivedAt}) {
  final text = normalizedSmsText(body);
  if (text.isEmpty || isOtpOrOfferSmsText(sender, text) || _notStatement.hasMatch(text)) return null;
  if (!_cardWord.hasMatch(text)) return null;
  final total = _amountOf(_totalDue, text);
  final dueDate = _dateAfter(_dueDateMarker, text);
  if (total == null || dueDate == null) return null;
  final minimum = _amountOf(_minimumDue, text);
  return CardStatementSms(
    totalDueMinor: total,
    minimumDueMinor: minimum != null && minimum <= total ? minimum : null,
    dueDate: dueDate,
    statementDate: _dateAfter(_statementDateMarker, text, before: dueDate),
    receivedAt: receivedAt,
    bank: bankFromSender(sender) ?? bankFromBody(text),
    cardLast4: smsAccountLast4(text),
  );
}

int? _amountOf(RegExp pattern, String text) {
  final match = pattern.firstMatch(text);
  return match == null ? null : parseAmountToMinor(match.group(1)!);
}

/// The first date written after the first [marker] in [text]; with
/// [before], only a date earlier than it counts.
DateTime? _dateAfter(RegExp marker, String text, {DateTime? before}) {
  final at = marker.firstMatch(text)?.end;
  if (at == null) return null;
  for (final (date, start) in smsDatesIn(text)) {
    if (start < at) continue;
    if (before != null && !date.isBefore(before)) return null;
    return date;
  }
  return null;
}

/// A bill payment the card issuer received. Immutable.
class CardPaymentSms {
  const CardPaymentSms({
    required this.amountMinor,
    required this.occurredAt,
    this.bank,
    this.cardLast4,
    this.availableLimitMinor,
    this.reference,
  });

  final int amountMinor;
  final DateTime occurredAt;
  final String? bank;
  final String? cardLast4;

  /// The limit available after the payment, when the message gives it.
  final int? availableLimitMinor;
  final String? reference;

  String get accountKey => smsAccountKey(bank: bank, isCreditCard: true, last4: cardLast4);
}

/// Reads a card issuer's "payment received" SMS ("Payment of Rs 12,000
/// received on your HDFC Bank Credit Card ending 9902"). Null for anything
/// else, including a refund, a bill paid from a bank account and messages
/// in another currency.
CardPaymentSms? parseCardPaymentSms({required String sender, required String body, required DateTime receivedAt}) {
  final text = normalizedSmsText(body);
  if (text.isEmpty || isIgnorableSmsText(sender, text) || !isCardPaymentAcknowledgementText(text)) return null;
  final currency = smsCurrencyCode(text);
  if (currency != null && currency != 'INR') return null;
  final amount = smsMovedAmountMinor(text);
  if (amount == null || amount == 0) return null;
  return CardPaymentSms(
    amountMinor: amount,
    occurredAt: transactionTime(text, receivedAt),
    bank: bankFromSender(sender) ?? bankFromBody(text),
    cardLast4: smsAccountLast4(text),
    availableLimitMinor: smsAvailableLimitMinor(text),
    reference: smsReference(text),
  );
}

/// The direction a card bill payment is logged under, so its transaction key
/// never collides with a spend or refund of the same amount.
const kCardPaymentDirection = 'card_payment';

/// What the SMS log keeps for a card bill payment: the shape of
/// [ParsedTransaction.toJson] plus `cardPayment`, so the review queue and the
/// editor show it as a transfer into the card.
Map<String, dynamic> cardPaymentPayload(CardPaymentSms payment, {String? cardAccountId}) => {
      'cardPayment': true,
      'direction': kCardPaymentDirection,
      'amountMinor': payment.amountMinor,
      'occurredAt': payment.occurredAt.toIso8601String(),
      'bank': payment.bank,
      'accountLast4': payment.cardLast4,
      'isCreditCard': true,
      'counterparty': null,
      'availableLimitMinor': payment.availableLimitMinor,
      'reference': payment.reference,
      'accountKey': payment.accountKey,
      'accountId': cardAccountId,
    };

/// Whether a stored SMS parse is a card bill payment ([cardPaymentPayload]).
bool isCardPaymentPayload(Map<String, dynamic>? parsed) => parsed?['cardPayment'] == true;

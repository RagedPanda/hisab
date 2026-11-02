/// Pairs the two sides of a credit card bill payment, the bank's debit SMS
/// and the card issuer's "payment received" SMS, so the payment is recorded
/// once, as a transfer from the bank account to the card. Pure.
library;

import '../../data/db/database.dart';
import 'card_sms_facts.dart';

/// How far apart the two messages of one payment may be.
const kCardPaymentMatchWindow = Duration(days: 3);

/// Wording that names a card bill as the payee of a bank debit.
final _cardBillHint = RegExp(
  r'credit\s*card|card\s*(?:bill|dues|payment|a/c|account)|\bcred\b|cred\.?\s?club|\bcc\s*(?:bill|pay(?:ment)?)\b|billdesk\W{0,3}\w*\W{0,3}card\b',
  caseSensitive: false,
);

/// Whether [text] (a payee, note or bank SMS) says the money paid a card bill.
bool hintsCardBillPayment(String text) => _cardBillHint.hasMatch(text);

/// A debit card names a card but pays no card bill.
final _debitCard = RegExp(r'debit\s*card', caseSensitive: false);

/// Whether the bank debit SMS [body] pays a credit card bill, so it moves
/// money to a card (a transfer) and is never spend.
bool isCardBillDebitText(String body) => hintsCardBillPayment(body) && !_debitCard.hasMatch(body);

/// The card digits a bank debit for a card bill names: "towards Credit Card
/// XX4521", "CC ending 4521", "Card No. XXXX4521", "4xxx xxxx xxxx 4521".
/// The bank account's own digits ("A/c XX7781") never count.
final _billedCardDigits = [
  RegExp(r'(?:credit\s*card|\bcc|\bcard)\s*(?:no\.?|number|a/c|account)?\s*(?:ending(?:\s*(?:with|in))?)?\s*[:\-]?\s*[xX*]+\s?(\d{4})\b', caseSensitive: false),
  RegExp(r'(?:credit\s*card|\bcc|\bcard)\s*(?:no\.?|number)?\s*(?:ending(?:\s*(?:with|in))?)\s*[:\-]?\s*(\d{4})\b', caseSensitive: false),
  RegExp(r'\b[0-9xX*]{4}[ -][xX*]{4}[ -][xX*]{4}[ -](\d{4})\b'),
];

/// The last 4 digits of the card a bank debit for a card bill pays, or null
/// when it names none.
String? billedCardLast4(String text) {
  for (final pattern in _billedCardDigits) {
    final match = pattern.firstMatch(text);
    if (match != null) return match.group(1);
  }
  return null;
}

/// The card a bank debit paying a card bill goes to, among [cards] (live
/// accounts): the card with [cardLast4] when the SMS names digits (none if
/// no card has them); otherwise the one card of [bank], else the only card
/// there is. Null when the card cannot be told.
String? cardForBillDebit(List<Account> cards, {required String? cardLast4, required String? bank}) {
  if (cardLast4 != null) return matchingCardId(cards, bank: null, last4: cardLast4);
  final onlyCards = [for (final card in cards) if (card.type == 'card') card];
  return matchingCardId(onlyCards, bank: bank, last4: null) ?? (onlyCards.length == 1 ? onlyCards.single.id : null);
}

/// Whether an SMS card bill payment transfer still waits for the SMS of the
/// other side: its own SMS is of the side that is not [missingCardSide]
/// ([ownIsCardSide]: the card's "payment received", else the bank debit),
/// and no SMS but its own ([ownSmsId]) and re-deliveries points at it.
bool awaitsCardPaymentSide({
  required bool missingCardSide,
  required bool ownIsCardSide,
  required String? ownSmsId,
  required Iterable<({String id, bool isDuplicate})> pointing,
}) =>
    ownSmsId != null && ownIsCardSide != missingCardSide && pointing.every((row) => row.id == ownSmsId || row.isDuplicate);

/// An entry that may be the other side of a card bill payment.
class CardPaymentCandidate {
  const CardPaymentCandidate({required this.entryId, required this.amountMinor, required this.occurredAt, this.hintsCardBill = false});
  final String entryId;
  final int amountMinor;
  final DateTime occurredAt;

  /// Whether its wording names a card bill (see [hintsCardBillPayment]).
  final bool hintsCardBill;
}

/// The entry that records the same card bill payment of [amountMinor] made
/// around [at], or null. Only an exact amount within [window] counts. One
/// whose wording names a card bill wins (the closest in time); without such
/// wording a candidate is taken only when it is the single one, since two
/// equal debits that week cannot be told apart.
CardPaymentCandidate? pickCardPaymentMatch(
  Iterable<CardPaymentCandidate> candidates, {
  required int amountMinor,
  required DateTime at,
  Duration window = kCardPaymentMatchWindow,
}) {
  Duration gap(CardPaymentCandidate candidate) => candidate.occurredAt.difference(at).abs();
  final inWindow = [for (final candidate in candidates) if (candidate.amountMinor == amountMinor && gap(candidate) <= window) candidate];
  final hinted = [for (final candidate in inWindow) if (candidate.hintsCardBill) candidate]..sort((a, b) => gap(a).compareTo(gap(b)));
  if (hinted.isNotEmpty) return hinted.first;
  return inWindow.length == 1 ? inWindow.single : null;
}

/// Seed key of the transfer category for card bill payments.
const kCardPaymentCategoryKey = 'credit_card_payment';

/// Seed keys of the catch-all categories, which say nothing about a payment.
const _catchAllCategoryKeys = {'other_expense', 'other_income'};

/// The category a card bill payment keeps once it is linked as a transfer:
/// the one the entry already had ([entryCategoryId], seeded as
/// [entrySeedKey]) unless that is a catch-all such as "Other"; otherwise
/// [cardPaymentCategoryId], the "Credit Card Payment" category.
String? linkedCardPaymentCategoryId({String? entryCategoryId, String? entrySeedKey, String? cardPaymentCategoryId}) =>
    entryCategoryId != null && !_catchAllCategoryKeys.contains(entrySeedKey) ? entryCategoryId : cardPaymentCategoryId;

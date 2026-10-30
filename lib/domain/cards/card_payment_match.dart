/// Pairs the two sides of a credit card bill payment, the bank's debit SMS
/// and the card issuer's "payment received" SMS, so the payment is recorded
/// once, as a transfer from the bank account to the card. Pure.
library;

/// How far apart the two messages of one payment may be.
const kCardPaymentMatchWindow = Duration(days: 3);

/// Wording that names a card bill as the payee of a bank debit.
final _cardBillHint = RegExp(
  r'credit\s*card|card\s*(?:bill|dues|payment|a/c|account)|\bcred\b|cred\.?\s?club|\bcc\s*(?:bill|pay(?:ment)?)\b',
  caseSensitive: false,
);

/// Whether [text] (a payee, note or bank SMS) says the money paid a card bill.
bool hintsCardBillPayment(String text) => _cardBillHint.hasMatch(text);

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

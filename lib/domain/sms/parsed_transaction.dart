enum TxnDirection { debit, credit }

enum Instrument { upi, card, netbanking, atm, neft, imps, rtgs, emi, wallet, cheque, unknown }

/// What kind of money movement the message describes. [general] is an
/// ordinary payment or receipt; the rest are the types worth telling apart
/// for categories and account mapping.
enum TxnKind { general, salary, refund, atmWithdrawal, emi, autopay, cardSpend, walletTopUp }

/// Stable key so a bank account or card can be matched across messages,
/// stored on the account as `smsKey` ("HDFC Bank:cc:4521").
String smsAccountKey({required String? bank, required bool isCreditCard, required String? last4}) =>
    '${bank ?? 'unknown'}:${isCreditCard ? 'cc' : 'ac'}:${last4 ?? '????'}';

/// What the SMS parser extracted from one bank message. Immutable.
class ParsedTransaction {
  const ParsedTransaction({
    required this.direction,
    required this.amountMinor,
    required this.instrument,
    required this.occurredAt,
    required this.raw,
    this.currency = 'INR',
    this.kind = TxnKind.general,
    this.bank,
    this.accountLast4,
    this.isCreditCard = false,
    this.counterparty,
    this.balanceMinor,
    this.availableLimitMinor,
    this.reference,
  });

  final TxnDirection direction;
  final int amountMinor;

  /// ISO code; anything other than INR means the app must ask for the
  /// converted amount before posting.
  final String currency;
  final Instrument instrument;
  final TxnKind kind;
  final DateTime occurredAt;
  final String raw;

  /// Bank display name resolved from sender id, e.g. "HDFC Bank".
  final String? bank;

  /// Last digits of the account/card the message refers to.
  final String? accountLast4;
  final bool isCreditCard;

  /// Merchant, VPA or person on the other side, best effort.
  final String? counterparty;

  /// "Avl Bal" after the transaction, when the bank includes it.
  final int? balanceMinor;

  /// Remaining credit limit for card alerts.
  final int? availableLimitMinor;
  final String? reference;

  bool get isDebit => direction == TxnDirection.debit;

  /// Stable key so a bank account can be matched across messages.
  String get accountKey => smsAccountKey(bank: bank, isCreditCard: isCreditCard, last4: accountLast4);

  Map<String, dynamic> toJson() => {
        'direction': direction.name,
        'amountMinor': amountMinor,
        'currency': currency,
        'instrument': instrument.name,
        'kind': kind.name,
        'occurredAt': occurredAt.toIso8601String(),
        'bank': bank,
        'accountLast4': accountLast4,
        'isCreditCard': isCreditCard,
        'counterparty': counterparty,
        'balanceMinor': balanceMinor,
        'availableLimitMinor': availableLimitMinor,
        'reference': reference,
      };
}

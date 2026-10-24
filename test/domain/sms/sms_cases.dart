/// Table-driven harness for the bank SMS parser tests. Every message in
/// these tables is written by hand in a publicly documented bank format with
/// made-up names, numbers and references; none is real personal data.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/sms/parsed_transaction.dart';
import 'package:hisab/domain/sms/payee_normaliser.dart';
import 'package:hisab/domain/sms/sms_parser.dart';

final smsReceivedAt = DateTime(2026, 10, 22, 9);

/// One SMS and what the parser must extract. A null expectation is not
/// checked, so each row only states what that format is about.
class SmsCase {
  const SmsCase(
    this.name, {
    required this.sender,
    required this.body,
    required this.direction,
    required this.amountMinor,
    required this.kind,
    this.bank,
    this.accountLast4,
    this.isCreditCard,
    this.instrument,
    this.counterparty,
    this.payee,
    this.balanceMinor,
    this.availableLimitMinor,
    this.reference,
    this.occurredAt,
  });

  final String name;
  final String sender;
  final String body;
  final TxnDirection direction;
  final int amountMinor;
  final TxnKind kind;
  final String? bank;
  final String? accountLast4;
  final bool? isCreditCard;
  final Instrument? instrument;
  final String? counterparty;

  /// Expected [normalisePayee] of the counterparty.
  final String? payee;
  final int? balanceMinor;
  final int? availableLimitMinor;
  final String? reference;
  final DateTime? occurredAt;
}

ParsedTransaction? parseSms(String sender, String body) =>
    parseBankSms(sender: sender, body: body, receivedAt: smsReceivedAt);

void runSmsCases(String family, List<SmsCase> cases) {
  group(family, () {
    for (final row in cases) {
      test(row.name, () {
        final parsed = parseSms(row.sender, row.body);
        expect(parsed, isNotNull, reason: 'not parsed: ${row.body}');
        final txn = parsed!;
        expect(txn.direction, row.direction, reason: 'direction');
        expect(txn.amountMinor, row.amountMinor, reason: 'amount');
        expect(txn.kind, row.kind, reason: 'kind');
        if (row.bank != null) expect(txn.bank, row.bank, reason: 'bank');
        if (row.accountLast4 != null) expect(txn.accountLast4, row.accountLast4, reason: 'account');
        if (row.isCreditCard != null) expect(txn.isCreditCard, row.isCreditCard, reason: 'credit card');
        if (row.instrument != null) expect(txn.instrument, row.instrument, reason: 'instrument');
        if (row.counterparty != null) expect(txn.counterparty, row.counterparty, reason: 'counterparty');
        if (row.payee != null) {
          expect(txn.counterparty, isNotNull, reason: 'payee needs a counterparty');
          expect(normalisePayee(txn.counterparty!), row.payee, reason: 'payee');
        }
        if (row.balanceMinor != null) expect(txn.balanceMinor, row.balanceMinor, reason: 'balance');
        if (row.availableLimitMinor != null) expect(txn.availableLimitMinor, row.availableLimitMinor, reason: 'limit');
        if (row.reference != null) expect(txn.reference, row.reference, reason: 'reference');
        if (row.occurredAt != null) expect(txn.occurredAt, row.occurredAt, reason: 'date');
      });
    }
  });
}

/// A message that must not become a transaction.
class IgnoredSms {
  const IgnoredSms(this.name, {required this.sender, required this.body});
  final String name;
  final String sender;
  final String body;
}

void runIgnoredCases(String family, List<IgnoredSms> cases) {
  group(family, () {
    for (final row in cases) {
      test(row.name, () => expect(parseSms(row.sender, row.body), isNull, reason: row.body));
    }
  });
}

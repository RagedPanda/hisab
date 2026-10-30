import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/sms/card_sms.dart';
import 'package:hisab/domain/sms/sms_parser.dart';

/// Card statement and card bill payment SMS. Every message is written by hand
/// in the bank's public format with made-up card digits and amounts.
void main() {
  final receivedAt = DateTime(2026, 10, 22, 9);

  CardStatementSms? statement(String sender, String body) => parseCardStatementSms(sender: sender, body: body, receivedAt: receivedAt);
  CardPaymentSms? payment(String sender, String body) => parseCardPaymentSms(sender: sender, body: body, receivedAt: receivedAt);

  group('parseCardStatementSms', () {
    final cases = <({String name, String sender, String body, String bank, String last4, int total, int? minimum, DateTime due, DateTime? statementDate})>[
      (
        name: 'HDFC',
        sender: 'VM-HDFCBK-S',
        body: 'Statement for HDFC Bank Credit Card XX4521 dated 12-10-26: Total Amt Due Rs 23,456.78, Min Amt Due Rs 1,180.00, Due Date 01-11-26. Pay via NetBanking/HDFC Bank App.',
        bank: 'HDFC Bank',
        last4: '4521',
        total: 2345678,
        minimum: 118000,
        due: DateTime(2026, 11, 1),
        statementDate: DateTime(2026, 10, 12),
      ),
      (
        name: 'ICICI',
        sender: 'JD-ICICIT-S',
        body: 'Your ICICI Bank Credit Card XX6611 statement has been generated. Total amount due: INR 8,940.50; Minimum amount due: INR 450.00. Payment due date: 05-Nov-26.',
        bank: 'ICICI Bank',
        last4: '6611',
        total: 894050,
        minimum: 45000,
        due: DateTime(2026, 11, 5),
        statementDate: null,
      ),
      (
        name: 'SBI Card',
        sender: 'VM-SBICRD-S',
        body: 'E-statement of SBI Credit Card ending 5512 dated 15/10/26 has been sent to your email. Total Amount Due Rs.12,300.00, Minimum Amount Due Rs.615.00. Pay by 04/11/26.',
        bank: 'SBI Card',
        last4: '5512',
        total: 1230000,
        minimum: 61500,
        due: DateTime(2026, 11, 4),
        statementDate: DateTime(2026, 10, 15),
      ),
      (
        name: 'Axis',
        sender: 'AX-AXISCR-S',
        body: 'Axis Bank Credit Card XX4321 statement: Total due INR 15,672.00, Min due INR 790.00, Due by 07-11-2026. Ignore if paid.',
        bank: 'Axis Bank',
        last4: '4321',
        total: 1567200,
        minimum: 79000,
        due: DateTime(2026, 11, 7),
        statementDate: null,
      ),
      (
        name: 'Kotak',
        sender: 'JD-KOTAKB-S',
        body: 'Kotak Credit Card xx1188 statement for Oct-26: Total Amount Due Rs 6,210.00, Minimum Amount Due Rs 320.00, Due on 03 Nov 2026.',
        bank: 'Kotak Bank',
        last4: '1188',
        total: 621000,
        minimum: 32000,
        due: DateTime(2026, 11, 3),
        statementDate: null,
      ),
      (
        name: 'HDFC existing ignored fixture',
        sender: 'VM-HDFCBK-S',
        body: 'Statement for HDFC Bank Credit Card XX9902: Total amount due Rs 12,000.00, minimum amount due Rs 600.00, due by 05-11-26.',
        bank: 'HDFC Bank',
        last4: '9902',
        total: 1200000,
        minimum: 60000,
        due: DateTime(2026, 11, 5),
        statementDate: null,
      ),
    ];
    for (final row in cases) {
      test(row.name, () {
        final parsed = statement(row.sender, row.body);
        expect(parsed, isNotNull);
        expect(parsed!.bank, row.bank);
        expect(parsed.cardLast4, row.last4);
        expect(parsed.totalDueMinor, row.total);
        expect(parsed.minimumDueMinor, row.minimum);
        expect(parsed.dueDate, row.due);
        expect(parsed.statementDate, row.statementDate);
        expect(parsed.accountKey, '${row.bank}:cc:${row.last4}');
        // Still never a transaction.
        expect(parseBankSms(sender: row.sender, body: row.body, receivedAt: receivedAt), isNull);
      });
    }

    test('a minimum above the total is dropped', () {
      final parsed = statement('VM-HDFCBK-S', 'HDFC Bank Credit Card XX4521: Total Amt Due Rs 500.00, Min Amt Due Rs 900.00, Due Date 01-11-26.');
      expect(parsed!.minimumDueMinor, isNull);
    });

    const notStatements = <(String, String, String)>[
      ('overdue reminder', 'VM-HDFCBK-S', 'Your HDFC Bank Credit Card XX4521 payment is overdue. Total Amt Due Rs 23,456.78, Due Date 01-10-26. Late fee applies.'),
      ('missed payment', 'VM-SBICRD-S', 'You have missed the payment for SBI Card ending 5512. Total amount due Rs.12,300.00 was due by 04/10/26.'),
      ('no due date', 'JD-ICICIT-S', 'Your ICICI Bank Credit Card XX6611 statement is ready. Total amount due: INR 8,940.50.'),
      ('no total', 'AX-AXISCR-S', 'Axis Bank Credit Card XX4321: Min due INR 790.00, Due by 07-11-2026.'),
      ('not a card', 'VM-HDFCBK-S', 'Loan EMI for HDFC Bank A/c XX7781: Total amount due Rs 9,000.00, due date 05-11-26.'),
      ('dollar statement', 'VM-HDFCBK-S', 'HDFC Bank Regalia Card XX4521 statement: Total Amt Due USD 230.00, Due Date 01-11-26.'),
      ('offer', 'VM-HDFCBK-P', 'Convert your HDFC Bank Credit Card total amount due Rs 23,456 into EMI! Pay by 01-11-26.'),
      ('OTP', 'VM-HDFCBK-S', '482910 is the OTP to pay total amount due Rs 23,456.78 on HDFC Bank Card XX4521 due date 01-11-26. Do not share.'),
      ('spend', 'VM-HDFCBK-S', 'Rs 1,250.00 spent on HDFC Bank Card XX4521 at AMAZON on 2026-10-20. Avl Lmt: Rs 76,543.21'),
    ];
    for (final (name, sender, body) in notStatements) {
      test('ignores $name', () => expect(statement(sender, body), isNull));
    }
  });

  group('parseCardPaymentSms', () {
    final cases = <({String name, String sender, String body, String bank, String last4, int amount, int? limit, DateTime at})>[
      (
        name: 'HDFC',
        sender: 'VM-HDFCBK-S',
        body: 'Payment of Rs 12,000.00 received on your HDFC Bank Credit Card ending 9902 on 20-10-2026. Thank you.',
        bank: 'HDFC Bank',
        last4: '9902',
        amount: 1200000,
        limit: null,
        at: DateTime(2026, 10, 20),
      ),
      (
        name: 'ICICI',
        sender: 'JD-ICICIT-S',
        body: 'Dear Customer, Payment of INR 5,000.00 has been received on your ICICI Bank Credit Card Account 4xxx xxxx xxxx 6611 on 20-OCT-26. Thank you.',
        bank: 'ICICI Bank',
        last4: '6611',
        amount: 500000,
        limit: null,
        at: DateTime(2026, 10, 20),
      ),
      (
        name: 'SBI Card',
        sender: 'VM-SBICRD-S',
        body: 'We have received payment of Rs.5,000.00 towards your SBI Credit Card ending with 5512 on 20/10/26. Available limit is Rs.53,501.00.',
        bank: 'SBI Card',
        last4: '5512',
        amount: 500000,
        limit: 5350100,
        at: DateTime(2026, 10, 20),
      ),
      (
        name: 'Axis',
        sender: 'AX-AXISCR-S',
        body: 'Payment of INR 3,000.00 has been received towards your Axis Bank Credit Card XX4321 on 20-10-26. Available limit INR 63,000.00.',
        bank: 'Axis Bank',
        last4: '4321',
        amount: 300000,
        limit: 6300000,
        at: DateTime(2026, 10, 20),
      ),
      (
        name: 'Kotak',
        sender: 'JD-KOTAKB-S',
        body: 'Payment of Rs 2,500.00 has been credited to your Kotak Credit Card XX1188 on 20-10-26. Thank you.',
        bank: 'Kotak Bank',
        last4: '1188',
        amount: 250000,
        limit: null,
        at: DateTime(2026, 10, 20),
      ),
    ];
    for (final row in cases) {
      test(row.name, () {
        final parsed = payment(row.sender, row.body);
        expect(parsed, isNotNull);
        expect(parsed!.bank, row.bank);
        expect(parsed.cardLast4, row.last4);
        expect(parsed.amountMinor, row.amount);
        expect(parsed.availableLimitMinor, row.limit);
        expect(parsed.occurredAt.year, row.at.year);
        expect((parsed.occurredAt.month, parsed.occurredAt.day), (row.at.month, row.at.day));
        expect(parsed.accountKey, '${row.bank}:cc:${row.last4}');
        expect(parseBankSms(sender: row.sender, body: row.body, receivedAt: receivedAt), isNull);
      });
    }

    const notPayments = <(String, String, String)>[
      ('card spend', 'VM-HDFCBK-S', 'Rs 1,250.00 spent on HDFC Bank Card XX4521 at AMAZON on 2026-10-20. Avl Lmt: Rs 76,543.21'),
      ('refund to card', 'VM-HDFCBK-S', 'Refund of Rs 499.00 from MYNTRA credited to your HDFC Bank Credit Card XX9902 on 20-10-26.'),
      ('bank debit paying the bill', 'VM-HDFCBK-S', 'Rs 12,000.00 debited from HDFC Bank A/c XX7781 on 20-10-26 towards HDFC Credit Card bill. Avl Bal Rs 30,000.00'),
      ('statement', 'VM-HDFCBK-S', 'Statement for HDFC Bank Credit Card XX9902: Total amount due Rs 12,000.00, minimum amount due Rs 600.00, due by 05-11-26.'),
      ('dollar payment', 'AM-AMEXIN-S', 'We have received your payment of USD 100.00 on your AMEX card ** 41007 on 20 October 2026. Thank you.'),
      ('OTP', 'VM-HDFCBK-S', '482910 is the OTP for payment of Rs 12,000.00 to your HDFC Bank Credit Card 9902. Do not share.'),
      ('payment failed', 'VM-SBICRD-S', 'Your payment of Rs.5,000.00 towards SBI Credit Card ending 5512 has failed. Please retry.'),
    ];
    for (final (name, sender, body) in notPayments) {
      test('ignores $name', () => expect(payment(sender, body), isNull));
    }
  });

  group('cardPaymentPayload', () {
    test('is a card payment and keeps the card key', () {
      final parsed = payment('VM-SBICRD-S', 'We have received payment of Rs.5,000.00 towards your SBI Credit Card ending with 5512 on 20/10/26. Available limit is Rs.53,501.00.')!;
      final payload = cardPaymentPayload(parsed, cardAccountId: 'card-1');
      expect(isCardPaymentPayload(payload), isTrue);
      expect(payload['direction'], kCardPaymentDirection);
      expect(payload['amountMinor'], 500000);
      expect(payload['accountKey'], 'SBI Card:cc:5512');
      expect(payload['accountId'], 'card-1');
    });

    test('an ordinary parse is not a card payment', () {
      expect(isCardPaymentPayload({'direction': 'debit'}), isFalse);
      expect(isCardPaymentPayload(null), isFalse);
    });
  });
}

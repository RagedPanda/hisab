import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/sms/parsed_transaction.dart';
import 'package:hisab/domain/sms/sms_confidence.dart';
import 'package:hisab/domain/sms/sms_parser.dart';

ParsedTransaction _parsed({int amountMinor = 45900, String? bank = 'HDFC Bank', String? last4 = '1234', String currency = 'INR'}) => ParsedTransaction(
      direction: TxnDirection.debit,
      amountMinor: amountMinor,
      instrument: Instrument.upi,
      occurredAt: DateTime(2026, 10, 21),
      raw: 'raw',
      bank: bank,
      accountLast4: last4,
      currency: currency,
    );

void main() {
  group('isConfidentParse', () {
    test('amount, direction, bank and account read is confident', () {
      expect(isConfidentParse(_parsed()), isTrue);
    });

    test('bank alone or account alone is enough', () {
      expect(isConfidentParse(_parsed(last4: null)), isTrue);
      expect(isConfidentParse(_parsed(bank: null)), isTrue);
    });

    test('neither bank nor account is not confident', () {
      expect(isConfidentParse(_parsed(bank: null, last4: null)), isFalse);
    });

    test('zero amount is not confident', () {
      expect(isConfidentParse(_parsed(amountMinor: 0)), isFalse);
    });

    test('foreign currency is not confident', () {
      expect(isConfidentParse(_parsed(currency: 'USD')), isFalse);
    });

    test('a real bank SMS parses confidently, a pasted one without bank or account does not', () {
      final bankSms = parseBankSms(
        sender: 'VM-HDFCBK',
        body: 'Rs.459.00 debited from A/c XX1234 on 21-10-26 to swiggy@ybl (UPI Ref No 123456789012). Avl bal Rs.15,541.00',
        receivedAt: DateTime(2026, 10, 21),
      );
      expect(isConfidentParse(bankSms!), isTrue);
      final pasted = parseBankSms(sender: 'PASTED', body: 'Paid Rs 250 to Ramesh', receivedAt: DateTime(2026, 10, 21));
      expect(isConfidentParse(pasted!), isFalse);
    });
  });

  group('routeForSms', () {
    test('confident parse is added when auto-add is on', () {
      expect(routeForSms(parsed: _parsed(), autoAddEnabled: true, possibleTransaction: true), SmsRoute.autoAdd);
    });

    test('confident parse waits for review when auto-add is off', () {
      expect(routeForSms(parsed: _parsed(), autoAddEnabled: false, possibleTransaction: true), SmsRoute.review);
    });

    test('low-confidence parse waits for review', () {
      expect(routeForSms(parsed: _parsed(bank: null, last4: null), autoAddEnabled: true, possibleTransaction: true), SmsRoute.review);
    });

    test('unparsed message that still names an amount waits for review', () {
      expect(routeForSms(parsed: null, autoAddEnabled: true, possibleTransaction: true), SmsRoute.review);
    });

    test('unparsed message with no transaction in it is skipped', () {
      expect(routeForSms(parsed: null, autoAddEnabled: true, possibleTransaction: false), SmsRoute.skip);
    });
  });

  group('resolveSmsAutoAdd', () {
    test('defaults to on when the user never chose', () {
      expect(resolveSmsAutoAdd(storedValue: null, userChose: false), isTrue);
      expect(resolveSmsAutoAdd(storedValue: false, userChose: false), isTrue, reason: 'old builds saved false without asking');
    });

    test('keeps an explicit choice', () {
      expect(resolveSmsAutoAdd(storedValue: false, userChose: true), isFalse);
      expect(resolveSmsAutoAdd(storedValue: true, userChose: true), isTrue);
    });
  });

  group('looksLikeUnreadTransaction', () {
    test('an amount with no clear direction is worth a look', () {
      expect(looksLikeUnreadTransaction('A/c XX1234: transaction of INR 1,200.00 on 21-10-26. Ref 998877'), isTrue);
    });

    test('OTPs, reminders and plain text are not', () {
      expect(looksLikeUnreadTransaction('Your OTP for txn of Rs 500 is 123456. Do not share.'), isFalse);
      expect(looksLikeUnreadTransaction('Your card bill of Rs 5,000 is due on 25-10-26'), isFalse);
      expect(looksLikeUnreadTransaction('Dear customer, your new debit card has been dispatched.'), isFalse);
      expect(looksLikeUnreadTransaction(''), isFalse);
    });
  });
}

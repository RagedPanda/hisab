import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/sms/parsed_transaction.dart';
import 'package:hisab/domain/sms/sms_parser.dart';
import 'package:hisab/domain/sms/sms_transaction_key.dart';

const _broadband = 'Rs.799.00 debited from A/c XX1234 on 23-10-26 to ACTFIBERNET. UPI Ref 629400000799';

ParsedTransaction _parse(String body, {String sender = 'HDFCBK', DateTime? receivedAt}) =>
    parseBankSms(sender: sender, body: body, receivedAt: receivedAt ?? DateTime(2026, 10, 23, 9))!;

void main() {
  group('smsTransactionKey', () {
    test('the same SMS pasted later under another sender is the same transaction', () {
      final inbox = smsTransactionKeyForParsed(_broadband, _parse(_broadband));
      final pasted = smsTransactionKeyForParsed(_broadband, _parse(_broadband, sender: 'PASTED', receivedAt: DateTime(2026, 10, 27, 18)));
      expect(pasted, inbox);
    });

    test('a bank reference names the transaction whatever the wording', () {
      String key(String body) => smsTransactionKey(body: body, direction: 'debit', amountMinor: 79900, occurredAt: DateTime(2026, 10, 23), reference: '629400000799');
      expect(key(_broadband), key('ACTFIBERNET paid Rs 799. UPI Ref 629400000799'));
    });

    test('a refund quoting the original reference is a different transaction', () {
      final payment = smsTransactionKey(body: _broadband, direction: 'debit', amountMinor: 79900, occurredAt: DateTime(2026, 10, 23), reference: '629400000799');
      final refund = smsTransactionKey(body: _broadband, direction: 'credit', amountMinor: 79900, occurredAt: DateTime(2026, 10, 23), reference: '629400000799');
      final partial = smsTransactionKey(body: _broadband, direction: 'debit', amountMinor: 40000, occurredAt: DateTime(2026, 10, 23), reference: '629400000799');
      expect(refund, isNot(payment));
      expect(partial, isNot(payment));
    });

    test('without a reference, case and spacing do not matter but the day does', () {
      String key(String body, DateTime day) => smsTransactionKey(body: body, direction: 'debit', amountMinor: 50000, occurredAt: day);
      final day = DateTime(2026, 10, 23, 9);
      expect(key('Rs 500 debited  from A/c XX1234\n', day), key('rs 500 debited from a/c xx1234', day.add(const Duration(hours: 8))));
      expect(key('Rs 500 debited from A/c XX1234', day), isNot(key('Rs 500 debited from A/c XX1234', day.add(const Duration(days: 1)))),
          reason: 'the same wording on another day is a new payment');
    });

    test('the stored parse gives the same key as the fresh parse', () {
      final parsed = _parse(_broadband);
      expect(smsTransactionKeyForStored(_broadband, parsed.toJson()), smsTransactionKeyForParsed(_broadband, parsed));
    });

    test('a row that was never parsed has no key', () {
      expect(smsTransactionKeyForStored(_broadband, null), isNull);
      expect(smsTransactionKeyForStored(_broadband, {'direction': 'debit'}), isNull);
    });
  });
}

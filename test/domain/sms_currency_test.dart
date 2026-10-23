import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/sms/sms_currency.dart';
import 'package:hisab/domain/sms/sms_parser.dart';

void main() {
  group('isForeignCurrency', () {
    test('a code other than the home currency is foreign', () {
      expect(isForeignCurrency('USD', 'INR'), isTrue);
      expect(isForeignCurrency('EUR', 'INR'), isTrue);
      expect(isForeignCurrency('AED', 'INR'), isTrue);
    });

    test('the home currency is not foreign, whatever the case', () {
      expect(isForeignCurrency('INR', 'INR'), isFalse);
      expect(isForeignCurrency('usd', 'USD'), isFalse);
    });

    test('a missing marker counts as the home currency', () {
      expect(isForeignCurrency(null, 'INR'), isFalse);
      expect(isForeignCurrency('', 'INR'), isFalse);
    });

    test('a bare Rs or INR marker counts as the home currency', () {
      expect(isForeignCurrency('INR', 'USD'), isFalse);
    });
  });

  group('smsCurrencyCode', () {
    test('reads foreign codes and symbols', () {
      expect(smsCurrencyCode('USD 25.00 spent on your HDFC Bank Card XX1234 at AMAZON'), 'USD');
      expect(smsCurrencyCode('Txn of EUR 40.00 on ICICI Bank Card XX9876 at ZARA PARIS'), 'EUR');
      expect(smsCurrencyCode('AED 120.50 spent on Card XX1234 at DUBAI MALL'), 'AED');
      expect(smsCurrencyCode(r'$25 spent on Card XX1234 at APPLE.COM'), 'USD');
      expect(smsCurrencyCode('€40 spent on Card XX1234'), 'EUR');
    });

    test('reads local markers as INR', () {
      expect(smsCurrencyCode('Rs.459.00 debited from A/c XX1234'), 'INR');
      expect(smsCurrencyCode('INR 459.00 debited from A/c XX1234'), 'INR');
      expect(smsCurrencyCode('₹459 debited from A/c XX1234'), 'INR');
    });

    test('takes the transaction amount, not the balance', () {
      expect(smsCurrencyCode('USD 25.00 spent on Card XX1234. Avl bal Rs.15,541.00'), 'USD');
    });

    test('is null without a marker', () {
      expect(smsCurrencyCode('A/c XX1234 debited by 459.00 on 21-10-26'), isNull);
      expect(smsCurrencyCode('Amt 459.00 debited from A/c XX1234'), isNull);
      expect(smsCurrencyCode('Your OTP is 123456'), isNull);
    });
  });
}

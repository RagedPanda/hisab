import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/sms/payee_normaliser.dart';

void main() {
  group('normalisePayee (P2-18)', () {
    test('known UPI handles map to merchant names', () {
      expect(normalisePayee('ola.cabs@axisbank'), 'Ola');
      expect(normalisePayee('hpcl.petrol@paytm'), 'HPCL Petrol');
      expect(normalisePayee('blinkit@ybl'), 'Blinkit');
      expect(normalisePayee('zomato.1234@hdfcbank'), 'Zomato');
      expect(normalisePayee('swiggy-order@icici'), 'Swiggy');
    });
    test('unknown VPAs drop the handle and read as words', () {
      expect(normalisePayee('rahul.sharma@okaxis'), 'Rahul Sharma');
      expect(normalisePayee('sharma_stores_12@ybl'), 'Sharma Stores');
      expect(normalisePayee('9876543210@paytm'), '9876543210@paytm');
    });
    test('shouting merchant names are title-cased, acronyms kept', () {
      expect(normalisePayee('MYNTRA DESIGNS'), 'Myntra');
      expect(normalisePayee('RELIANCE RETAIL LTD'), 'Reliance Retail LTD');
      expect(normalisePayee('SBI ATM'), 'SBI ATM');
      expect(normalisePayee('PhonePe Merchant'), 'PhonePe');
      expect(normalisePayee('Cafe Coffee Day'), 'Cafe Coffee Day');
    });
    const parserCoverageCases = {
      'Mr PRADEEP KUMAR': 'Pradeep Kumar',
      'M/s SHARMA TRADERS': 'Sharma Traders',
      'GREEN LEAF CAFE': 'Green Leaf Cafe',
      'paytmqr281005050101@paytm': 'paytmqr281005050101@paytm',
      'q123456789@ybl': 'q123456789@ybl',
      'cred.club@axisb': 'CRED',
      'licindia.premium@hdfcbank': 'LIC',
      'tea.stall@okfederal': 'Tea Stall',
    };
    for (final MapEntry(key: raw, value: payee) in parserCoverageCases.entries) {
      test('parser coverage: $raw', () => expect(normalisePayee(raw), payee));
    }
    test('isVpa', () {
      expect(isVpa('ola.cabs@axisbank'), isTrue);
      expect(isVpa('Pay at store@home'), isFalse);
      expect(isVpa('MYNTRA'), isFalse);
    });
  });
}

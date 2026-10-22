import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/split/debt_simplifier.dart';
import 'package:hisab/domain/split/settle_up_links.dart';

void main() {
  group('settleRoleFor', () {
    const transfer = Transfer('rahul', 'me', 500);
    test('someone paying me means I remind', () => expect(settleRoleFor(transfer, 'me'), SettleRole.remind));
    test('me paying someone means I pay', () => expect(settleRoleFor(const Transfer('me', 'rahul', 500), 'me'), SettleRole.pay));
    test('two other people, or no me, means record only', () {
      expect(settleRoleFor(const Transfer('priya', 'rahul', 500), 'me'), SettleRole.others);
      expect(settleRoleFor(transfer, null), SettleRole.others);
    });
  });

  group('normaliseUpiId', () {
    test('trims and lower-cases a valid VPA', () => expect(normaliseUpiId('  Rahul.K-9@OKAxis '), 'rahul.k-9@okaxis'));
    test('rejects text without a handle, empty input and spaces', () {
      expect(normaliseUpiId('rahul'), isNull);
      expect(normaliseUpiId(''), isNull);
      expect(normaliseUpiId('ra hul@ybl'), isNull);
      expect(normaliseUpiId('rahul@'), isNull);
    });
  });

  test('upiAmount keeps two decimals', () {
    expect(upiAmount(123450), '1234.50');
    expect(upiAmount(5), '0.05');
    expect(upiAmount(100000), '1000.00');
  });

  test('upiPayUri carries payee, amount, currency and note, escaped', () {
    final uri = upiPayUri(upiId: 'rahul@ybl', payeeName: 'Rahul K', amountMinor: 30000, note: 'Goa trip');
    expect(uri.scheme, 'upi');
    expect(uri.host, 'pay');
    expect(uri.queryParameters, {'pa': 'rahul@ybl', 'pn': 'Rahul K', 'am': '300.00', 'cu': 'INR', 'tn': 'Goa trip'});
    expect(uri.toString(), startsWith('upi://pay?pa=rahul%40ybl'));
  });

  group('internationalDigits', () {
    test('bare Indian mobile numbers get 91', () => expect(internationalDigits('98100 12345'), '919810012345'));
    test('a leading trunk zero is swapped for 91', () => expect(internationalDigits('09810012345'), '919810012345'));
    test('numbers with + or 00 keep their own country code', () {
      expect(internationalDigits('+1 (415) 555-0100'), '14155550100');
      expect(internationalDigits('0044 20 7946 0000'), '442079460000');
    });
    test('too short to dial is null', () => expect(internationalDigits('12 34'), isNull));
  });

  test('whatsAppUri and smsUri prefill the message', () {
    expect(whatsAppUri('98100 12345', 'You owe me ₹300')!.toString(), 'https://wa.me/919810012345?text=You%20owe%20me%20%E2%82%B9300');
    final sms = smsUri('98100 12345', 'Hi there')!;
    expect(sms.toString(), 'sms:+919810012345?body=Hi%20there');
    expect(sms.scheme, 'sms');
    expect(sms.path, '+919810012345');
    expect(sms.queryParameters['body'], 'Hi there');
    expect(whatsAppUri('123', 'x'), isNull);
  });

  test('daysBetween counts calendar days, not 24-hour blocks', () {
    expect(daysBetween(DateTime(2026, 10, 21, 23, 50), DateTime(2026, 10, 22, 0, 10)), 1);
    expect(daysBetween(DateTime(2026, 10, 22, 8), DateTime(2026, 10, 22, 20)), 0);
    expect(daysBetween(DateTime(2026, 10, 19), DateTime(2026, 10, 22)), 3);
  });
}

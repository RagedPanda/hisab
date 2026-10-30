import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/udhaar/udhaar_reminder.dart';

void main() {
  group('upiAmountText', () {
    test('drops zero paise and keeps real ones', () {
      expect(upiAmountText(250000), '2500');
      expect(upiAmountText(250050), '2500.50');
      expect(upiAmountText(5), '0.05');
    });
  });

  group('upiQueryValue', () {
    test('encodes spaces as %20 and keeps @ readable', () {
      expect(upiQueryValue('Ankur Dubey'), 'Ankur%20Dubey');
      expect(upiQueryValue('ankur@okaxis'), 'ankur@okaxis');
    });

    test('encodes reserved characters and non-ASCII names', () {
      expect(upiQueryValue('A&B=C'), 'A%26B%3DC');
      expect(upiQueryValue('अंकुर'), Uri.encodeComponent('अंकुर'));
      expect(Uri.decodeComponent(upiQueryValue('अंकुर')), 'अंकुर');
    });
  });

  group('upiPayLink', () {
    test('builds the full pay link', () {
      expect(
        upiPayLink(upiId: 'ankur@okaxis', payeeName: 'Ankur Dubey', amountMinor: 250000),
        'upi://pay?pa=ankur@okaxis&pn=Ankur%20Dubey&am=2500&cu=INR&tn=Hisab',
      );
    });

    test('leaves out a blank payee name and keeps paise', () {
      expect(upiPayLink(upiId: 'me@ybl', payeeName: '  ', amountMinor: 80050), 'upi://pay?pa=me@ybl&am=800.50&cu=INR&tn=Hisab');
    });

    test('parses back to the same values', () {
      final uri = Uri.parse(upiPayLink(upiId: 'me@ybl', payeeName: 'राहुल & co', amountMinor: 100));
      expect(uri.scheme, 'upi');
      expect(uri.queryParameters, {'pa': 'me@ybl', 'pn': 'राहुल & co', 'am': '1', 'cu': 'INR', 'tn': 'Hisab'});
    });
  });

  group('udhaarReminderText', () {
    test('joins the greeting and the pay line', () {
      expect(udhaarReminderText(greeting: 'Hi Rahul, a reminder.', payLine: 'Pay via UPI: upi://x'), 'Hi Rahul, a reminder. Pay via UPI: upi://x');
    });

    test('is just the greeting without a pay line', () {
      expect(udhaarReminderText(greeting: 'Hi Rahul. '), 'Hi Rahul.');
      expect(udhaarReminderText(greeting: 'Hi Rahul.', payLine: ' '), 'Hi Rahul.');
    });
  });
}

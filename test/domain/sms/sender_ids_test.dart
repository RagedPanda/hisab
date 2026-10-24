import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/sms/bank_senders.dart';

void main() {
  group('bank sender ids', () {
    const senders = {
      'XX-HDFCBK': 'HDFC Bank',
      'VM-HDFCBK-S': 'HDFC Bank',
      'AD-SBIINB-T': 'SBI',
      'JM-SBIUPI-S': 'SBI',
      'VM-SBICRD-S': 'SBI Card',
      'JD-ICICIT-S': 'ICICI Bank',
      'AX-AXISBK-S': 'Axis Bank',
      'JD-KOTAKB-S': 'Kotak Bank',
      'VM-PNBSMS-S': 'PNB',
      'VM-BOBTXN-S': 'Bank of Baroda',
      'VM-BOBCRD-S': 'BOBCARD',
      'VM-IDFCFB-S': 'IDFC First Bank',
      'VM-YESBNK-S': 'Yes Bank',
      'VM-INDUSB-S': 'IndusInd Bank',
      'VM-AUBANK-S': 'AU Small Finance Bank',
      'VM-FEDBNK-S': 'Federal Bank',
      'VM-CANBNK-S': 'Canara Bank',
      'VM-UNIONB-S': 'Union Bank',
      'VM-AMEXIN-S': 'American Express',
      'VM-RBLCRD-S': 'RBL Credit Card',
      'VM-ONECRD-S': 'OneCard',
    };
    for (final MapEntry(key: sender, value: bank) in senders.entries) {
      test('$sender is $bank', () {
        expect(bankFromSender(sender), bank);
        expect(looksLikeBankSender(sender), isTrue);
      });
    }
    test('phone numbers and pasted text are not bank senders', () {
      expect(bankFromSender('+919876500000'), isNull);
      expect(looksLikeBankSender('+919876500000'), isFalse);
      expect(looksLikeBankSender('PASTED'), isFalse);
    });
    test('dltHeader reads the six-character header', () {
      expect(dltHeader('XX-HDFCBK'), 'HDFCBK');
      expect(dltHeader('jd-icicit-s'), 'ICICIT');
      expect(dltHeader('PASTED'), isNull);
    });
    test('promotional suffix', () {
      expect(isPromotionalSender('VM-HDFCBK-P'), isTrue);
      expect(isPromotionalSender('VM-HDFCBK-S'), isFalse);
      expect(isPromotionalSender('XX-HDFCBK'), isFalse);
    });
  });

  group('bank named in the message body', () {
    const bodies = {
      'Sent Rs.80 From HDFC Bank A/C *7781': 'HDFC Bank',
      'Rs.259 spent on your SBI Credit Card ending 5512': 'SBI Card',
      'by SBI Debit Card 7310 done at shop': 'SBI',
      'credited to your ICICI Bank account from rohit@oksbi': 'ICICI Bank',
      'Your A/c XX9031 debited. Team IDFC FIRST Bank': 'IDFC First Bank',
      'payment towards your BOBCARD ending 7781': 'BOBCARD',
      'Received Rs.10 from anita@oksbi': null,
    };
    for (final MapEntry(key: body, value: bank) in bodies.entries) {
      test(body, () => expect(bankFromBody(body), bank));
    }
  });
}

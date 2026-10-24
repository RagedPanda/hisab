import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/sms/bank_senders.dart';
import 'package:hisab/domain/sms/parsed_transaction.dart';
import 'package:hisab/domain/sms/sms_account_name.dart';
import 'package:hisab/domain/sms/sms_categorizer.dart';
import 'package:hisab/domain/sms/sms_parser.dart';

final _now = DateTime(2026, 10, 21, 10);

ParsedTransaction? parse(String sender, String body) => parseBankSms(sender: sender, body: body, receivedAt: _now);

void main() {
  group('bank senders', () {
    test('resolves DLT ids', () {
      expect(bankFromSender('VM-HDFCBK-S'), 'HDFC Bank');
      expect(bankFromSender('AD-SBIINB'), 'SBI');
      expect(bankFromSender('JD-ICICIT-S'), 'ICICI Bank');
      expect(bankFromSender('AX-AXISBK-S'), 'Axis Bank');
      expect(bankFromSender('+919876543210'), isNull);
    });

    test('only alphanumeric headers count as business senders', () {
      expect(isBusinessSender('AD-HDFCBK'), isTrue);
      expect(isBusinessSender('KOTAKB'), isTrue);
      expect(isBusinessSender('+19876500011'), isFalse);
      expect(isBusinessSender('9876500011'), isFalse);
      expect(isBusinessSender(''), isFalse);
    });
  });

  group('rejects non-transactions', () {
    for (final body in [
      'Your IDFC First Bank OTP is 123456. Do not share this code with anyone.',
      'Your OTP for UPI transaction is 123456. Do not share. Amount: Rs.500',
      'AutoPay: Rs 299.00 will be debited on 15-Oct-25 for Spotify subscription',
      'Your account balance is Rs.500. Maintain minimum balance.',
      'Auto Pay HDFC Bank NACH Mandate : Rs. 100000.00 UMRN:HDFC7031703262015557 To:NationalSecuritiesClearin Freq ADHO received today for processing.',
      'Ravi Kumar has requested Rs.500 from you on PhonePe. Pay now.',
      'Pre-approved personal loan of Rs 5,00,000 for you! Apply now.',
      'Your credit card statement is generated. Total amount due Rs 12,000.',
    ]) {
      test(body.substring(0, 30), () => expect(parse('VM-HDFCBK-S', body), isNull));
    }
  });

  group('parses real formats', () {
    test('HDFC UPI sent', () {
      final t = parse('VM-HDFCBK-S', 'Sent Rs.15000.00 From HDFC Bank A/C *1234 To TEST MERCHANT PVT LTD On 01/01/26 Ref 567890567890 Not You? Call 18005556789/SMS BLOCK UPI to 7305556789')!;
      expect(t.direction, TxnDirection.debit);
      expect(t.amountMinor, 1500000);
      expect(t.accountLast4, '1234');
      expect(t.counterparty, 'TEST MERCHANT PVT LTD');
      expect(t.reference, '567890567890');
      expect(t.occurredAt, DateTime(2026, 1, 1));
      expect(t.bank, 'HDFC Bank');
      expect(t.isCreditCard, isFalse);
    });
    test('HDFC UPI to vpa', () {
      final t = parse('VM-HDFCBK-S', 'Rs.500.00 debited from A/c XX1234 on 20-Oct-25 to merchant@upi (UPI Ref No 123456789012)')!;
      expect(t.amountMinor, 50000);
      expect(t.counterparty, 'merchant@upi');
      expect(t.reference, '123456789012');
      expect(t.instrument, Instrument.upi);
      expect(t.occurredAt, DateTime(2025, 10, 20));
    });
    test('HDFC NEFT credit with balance', () {
      final t = parse('VM-HDFCBK-S', 'Update! INR 1.00 deposited in HDFC Bank A/c XX9999 on 30-MAR-26 for NEFT Cr-CITI0100000-ACME TECHNOLOGIES-PERSON NAME-CITIN99999999999.Avl bal INR 8.00.')!;
      expect(t.direction, TxnDirection.credit);
      expect(t.amountMinor, 100);
      expect(t.balanceMinor, 800);
      expect(t.counterparty, 'ACME TECHNOLOGIES');
      expect(t.instrument, Instrument.neft);
    });
    test('HDFC credit card reversal', () {
      final t = parse('VM-HDFCBK-S', 'Transaction Reversed!On HDFC Bank CREDIT Card xx5555 Amt: Rs.862.16 By AMAZON On 2026-08-21:05:20:26')!;
      expect(t.direction, TxnDirection.credit);
      expect(t.amountMinor, 86216);
      expect(t.isCreditCard, isTrue);
      expect(t.accountLast4, '5555');
      expect(t.counterparty, 'AMAZON');
      expect(t.occurredAt, DateTime(2026, 8, 21, 5, 20, 26));
      expect(suggestCategoryKey(t), 'credit_card_payment');
    });
    test('SBI bare amount', () {
      final t = parse('AD-SBIINB-S', 'A/C X6299 debited by 356.00 on date 26Apr26 trf to Swiggy Refno 26029846...')!;
      expect(t.amountMinor, 35600);
      expect(t.accountLast4, '6299');
      expect(t.counterparty, 'Swiggy');
      expect(t.reference, '26029846');
      expect(t.occurredAt, DateTime(2026, 4, 26));
      expect(suggestCategoryKey(t), 'food_delivery');
    });
    test('SBI with balance', () {
      final t = parse('AD-SBIINB-S', 'Rs.500 debited from A/c X1234 on 13Sep25. Avl Bal Rs.999999999')!;
      expect(t.amountMinor, 50000);
      expect(t.balanceMinor, 99999999900);
      expect(t.counterparty, isNull);
    });
    test('SBI debit card at merchant', () {
      final t = parse(
        'AD-SBIINB-S',
        'Dear Customer, transaction number 1234 for Rs.383.00 by SBI Debit Card 0000 done at merchant on 13Sep25 at 21:38:26. Your updated available balance is Rs.999999999.',
      )!;
      expect(t.direction, TxnDirection.debit);
      expect(t.amountMinor, 38300);
      expect(t.balanceMinor, 99999999900);
      expect(t.isCreditCard, isFalse);
      expect(t.accountLast4, '0000');
    });
    test('SBI Card with limit and unicode glyphs', () {
      final t = parse('SBICRD', 'Rs.259.00 𝗌𝗉𝖾𝗇𝗍 𝗈𝗇 𝗒𝗈𝗎𝗋 SBI Credit Card ending with 1234 on 15Jan26. Your available limit is Rs.1,235.00.')!;
      expect(t.direction, TxnDirection.debit);
      expect(t.amountMinor, 25900);
      expect(t.isCreditCard, isTrue);
      expect(t.accountLast4, '1234');
      expect(t.availableLimitMinor, 123500);
      expect(t.balanceMinor, isNull);
    });
    test('ICICI UPI with merchant credited', () {
      final t = parse(
        'JD-ICICIT-S',
        'ICICI Bank Acct XX051 debited for Rs 180.00 on 10-Nov-25; DINDUGAL ORIGIN credited. UPI:568069174081. Call 18002662 for dispute. SMS BLOCK 051 to 9215676766. 06:33 PM',
      )!;
      expect(t.direction, TxnDirection.debit);
      expect(t.amountMinor, 18000);
      expect(t.accountLast4, '051');
      expect(t.counterparty, 'DINDUGAL ORIGIN');
      expect(t.reference, '568069174081');
    });
    test('ICICI ATM', () {
      final t = parse('JD-ICICIT-S', 'ICICI Bank Acc XX771 debited Rs. 10,000.00 on 20-Jan-26 NFS*CASH WDL*. Avb Bal Rs. 3,943.84.')!;
      expect(t.amountMinor, 1000000);
      expect(t.instrument, Instrument.atm);
      expect(t.balanceMinor, 394384);
      expect(t.accountLast4, '771');
      expect(suggestCategoryKey(t), 'cash_withdrawal');
    });
    test('ICICI EMI', () {
      final t = parse('JD-ICICIT-S', 'ICICI Bank Acc XX342 debited Rs. 8,927.00 on 07-Jun-26 InfoBIL*Auto Loan.Avl Bal Rs. 1,248.78.')!;
      expect(t.amountMinor, 892700);
      expect(t.counterparty, 'Auto Loan');
      expect(suggestCategoryKey(t), 'loan_emi');
    });
    test('ICICI salary', () {
      final t = parse('JD-ICICIT-S', 'ICICI Bank Account XX566 credited:Rs. 18,832.00 on 28-Feb-25. Info INF*000169831922*IQBO SAL FE. Available Balance is Rs. 28,076.14.')!;
      expect(t.direction, TxnDirection.credit);
      expect(t.amountMinor, 1883200);
      expect(t.balanceMinor, 2807614);
      expect(t.counterparty, 'IQBO SAL FE');
      expect(suggestCategoryKey(t), 'salary');
    });
    test('ICICI foreign currency card', () {
      final t = parse('JD-ICICIT-S', 'EUR 50.00 spent using ICICI Bank Card XX1234 on 05-Sep-25 on Amazon DE. Avl Limit: INR 2,00,000.00.')!;
      expect(t.currency, 'EUR');
      expect(t.amountMinor, 5000);
      expect(t.availableLimitMinor, 20000000);
      expect(t.counterparty, 'Amazon DE');
    });
    test('Axis', () {
      final t = parse(
        'AX-AXISBK-S',
        'INR 500.00 debited from A/c no. XX312225 on MERCHANT ABC 02-12-2025 20:38:23 IST. Avl bal: INR 10000.00. Not you? SMS BLOCKCARD XX0023 to +919951860002 - Axis Bank',
      )!;
      expect(t.amountMinor, 50000);
      expect(t.accountLast4, '2225');
      expect(t.balanceMinor, 1000000);
      expect(t.counterparty, 'MERCHANT ABC');
      expect(t.occurredAt, DateTime(2025, 12, 2, 20, 38, 23));
    });
    test('AND-11: Axis card with Avl Lmt and merchant after the clock time', () {
      final t = parse('AX-AXISBK-S', 'Spent Card no. XX4321 INR 3,499.00 21-10-26 10:15:22 AMAZON Avl Lmt INR 96,501.00 SMS BLOCK 4321 to 919951860002, if not done by you - Axis Bank')!;
      expect(t.amountMinor, 349900);
      expect(t.isCreditCard, isTrue);
      expect(t.accountLast4, '4321');
      expect(t.counterparty, 'AMAZON');
      expect(t.availableLimitMinor, 9650100);
      expect(t.occurredAt, DateTime(2026, 10, 21, 10, 15, 22));
    });
    test('Kotak UPI sent and received', () {
      final sent = parse('JD-KOTAKB-S', 'Sent Rs.100.00 from Kotak Bank AC X5678 to phonepeqr123456789xyz@ybl on 15-10-25.UPI Ref 9876543210. Not you, https://kotak.com/KBANKT/Fraud')!;
      expect(sent.direction, TxnDirection.debit);
      expect(sent.accountLast4, '5678');
      expect(sent.counterparty, 'phonepeqr123456789xyz@ybl');
      expect(sent.reference, '9876543210');
      final received = parse('JD-KOTAKB-S', 'Received Rs.250.00 in your Kotak Bank AC X3333 from john.doe@oksbi on 14-10-25.UPI Ref 2222222222.')!;
      expect(received.direction, TxnDirection.credit);
      expect(received.amountMinor, 25000);
      expect(received.counterparty, 'john.doe@oksbi');
      expect(suggestCategoryKey(received), 'other_income');
    });
    test('Kotak ATM withdrawal', () {
      final t = parse('JD-KOTAKB-S', 'Rs.1900.00 withdrawn via Kotak Debit Card XX01111 on 15/10/2026 at S1BN000000001. Avl Bal Rs.5000.27')!;
      expect(t.instrument, Instrument.atm);
      expect(t.accountLast4, '1111');
      expect(t.balanceMinor, 500027);
    });
    test('Kotak credit card via UPI', () {
      final t = parse('JD-KOTAKB-S', 'INR 20 spent on Kotak Credit Card x5236 on 23-JAN-2026 at UPI-638903921672-CORN. Avl limit INR 73733.02')!;
      expect(t.amountMinor, 2000);
      expect(t.isCreditCard, isTrue);
      expect(t.accountLast4, '5236');
      expect(t.counterparty, 'CORN');
      expect(t.availableLimitMinor, 7373302);
    });
    test('PNB UPI and ATM', () {
      final upi = parse('VM-PNBSMS-S', 'A/c X0000 debited INR 125.00 Dt 01-01-26 12:00:00 to Swiggy thru UPI:000000000001..Bal INR 9000.00-PNB')!;
      expect(upi.amountMinor, 12500);
      expect(upi.counterparty, 'Swiggy');
      expect(upi.balanceMinor, 900000);
      expect(upi.reference, '000000000001');
      final atm = parse('VM-PNBSMS-S', 'A/c XX1234 debited with Rs.5000.00,21-11-2025 13:23:22 thru card XX9239 . Out of 5 free txn on PNB ATM... Bal 27000.00 CR.')!;
      expect(atm.amountMinor, 500000);
      expect(atm.accountLast4, '1234');
      expect(atm.instrument, Instrument.atm);
      expect(atm.balanceMinor, 2700000);
    });
    test('Bank of Baroda debit, IMPS credit and card', () {
      final dr = parse('VM-BOBTXN-S', 'Rs.80.00 Dr. from A/c XX123456 on 12-11-2024. AvlBal:Rs1234.56. Ref:52211012345 -Bank of Baroda')!;
      expect(dr.direction, TxnDirection.debit);
      expect(dr.amountMinor, 8000);
      expect(dr.accountLast4, '3456');
      expect(dr.balanceMinor, 123456);
      expect(dr.reference, '52211012345');
      final cr = parse('VM-BOBTXN-S', 'Rs.2500.00 credited to A/c XX456789 via IMPS/518233445566 by JOHN DOE. AvlBal:Rs25000.00')!;
      expect(cr.direction, TxnDirection.credit);
      expect(cr.counterparty, 'JOHN DOE');
      expect(cr.instrument, Instrument.imps);
      expect(cr.reference, '518233445566');
      final card = parse('VM-BOBCRD-S', 'ALERT: INR 1,500.00 is spent on your BOBCARD ending 1234 at AMAZON on 25-11-2024 10:30:00. Available credit limit is Rs 42,981.46')!;
      expect(card.amountMinor, 150000);
      expect(card.isCreditCard, isTrue);
      expect(card.accountLast4, '1234');
      expect(card.counterparty, 'AMAZON');
      expect(card.availableLimitMinor, 4298146);
      expect(suggestCategoryKey(card), 'online_shopping');
    });
    test('IDFC', () {
      final t = parse('VM-IDFCFB-S', 'Your A/c XX4614 debited by Rs. 1,172.06 on 15/01/26; REDBUS credited. RRN 060649915527. Available balance Rs. 9,134.15. Team IDFC FIRST Bank')!;
      expect(t.amountMinor, 117206);
      expect(t.counterparty, 'REDBUS');
      expect(t.reference, '060649915527');
      expect(t.balanceMinor, 913415);
      expect(suggestCategoryKey(t), 'trains_buses');
    });
    test('UPI app and wallet', () {
      final upi = parse('PHONPE', '₹58 paid to Mr PRADEEP KUMAR via UPI on 06-Jun-26. UPI Ref No 1234567890')!;
      expect(upi.amountMinor, 5800);
      expect(upi.counterparty, 'Mr PRADEEP KUMAR');
      expect(upi.reference, '1234567890');
      final wallet = parse('PAYTMM', 'Rs.250 debited from Paytm wallet. Available bal Rs.750')!;
      expect(wallet.instrument, Instrument.wallet);
      expect(wallet.balanceMinor, 75000);
    });
  });

  group('transaction time', () {
    test('same-day SMS without a clock time keeps the received time', () {
      expect(transactionTime('Rs.500 debited on 21-10-26 to x', _now), _now);
      expect(transactionTime('Rs.500 debited on 21-Oct-26 to x', _now), _now);
    });
    test('earlier-day SMS without a clock time is dated at midnight', () {
      expect(transactionTime('Rs.500 debited on 19-10-26 to x', _now), DateTime(2026, 10, 19));
    });
    test('clock time in the SMS wins', () {
      expect(transactionTime('Rs.500 debited on 21-10-26 09:05 to x', _now), DateTime(2026, 10, 21, 9, 5));
    });
    test('no date at all falls back to received time', () {
      expect(transactionTime('Rs.500 debited to x', _now), _now);
    });
  });

  group('sms account naming', () {
    test('Low #12: does not double the word Card', () {
      expect(smsAccountName(bank: 'SBI Card', isCreditCard: true, last4: '7788'), 'SBI Card ••7788');
      expect(smsAccountName(bank: 'HDFC Bank', isCreditCard: true, last4: '1234'), 'HDFC Bank Card ••1234');
      expect(smsAccountName(bank: 'HDFC Bank', isCreditCard: false, last4: '1234'), 'HDFC Bank ••1234');
      expect(smsAccountName(bank: null, isCreditCard: false, last4: null), 'Bank');
    });
  });

  group('categorizer', () {
    ParsedTransaction txn(String raw, {TxnDirection direction = TxnDirection.debit, String? counterparty}) =>
        ParsedTransaction(direction: direction, amountMinor: 100, instrument: Instrument.upi, occurredAt: _now, raw: raw, counterparty: counterparty);
    test('keywords', () {
      expect(suggestCategoryKey(txn('paid to ZOMATO LTD')), 'food_delivery');
      expect(suggestCategoryKey(txn('paid', counterparty: 'Uber India')), 'cab_auto');
      expect(suggestCategoryKey(txn('to BESCOM')), 'electricity');
      expect(suggestCategoryKey(txn('to Zerodha Broking')), 'investments');
      expect(suggestCategoryKey(txn('NEFT SALARY MAY', direction: TxnDirection.credit)), 'salary');
      expect(suggestCategoryKey(txn('refund from Flipkart', direction: TxnDirection.credit)), 'refunds_cashback');
      expect(suggestCategoryKey(txn('to Unknown Shop')), 'other_expense');
    });
    test('P3-3: glued UPI handles fall back to substring matching', () {
      expect(suggestCategoryKey(txn('paid to apollopharmacy@ybl', counterparty: 'apollopharmacy@ybl')), 'medicines');
      expect(suggestCategoryKey(txn('paid to swiggyinstamart@axl', counterparty: 'swiggyinstamart@axl')), isNot('other_expense'));
      // Short keywords never match inside other words.
      expect(suggestCategoryKey(txn('paid to coincidence shop')), 'other_expense');
    });
  });
}

import 'package:hisab/domain/sms/parsed_transaction.dart';

import 'sms_cases.dart';

void main() {
  runSmsCases('Axis Bank', const [
    SmsCase(
      'UPI debit with merchant before the date',
      sender: 'AX-AXISBK-S',
      body: 'INR 310.00 debited from A/c no. XX802211 on UPI/629433330001/BLUE TOKAI 21-10-2026 09:12:40 IST. Avl bal: INR 9,690.00. Not you? SMS BLOCKCARD XX0023 to +919951860002 - Axis Bank',
      direction: TxnDirection.debit,
      amountMinor: 31000,
      kind: TxnKind.general,
      bank: 'Axis Bank',
      accountLast4: '2211',
      counterparty: 'BLUE TOKAI',
      balanceMinor: 969000,
    ),
    SmsCase(
      'salary with Info',
      sender: 'AX-AXISBK-S',
      body: 'INR 50,000.00 credited to A/c no. XX802211 on 31-10-26 at 10:00:00 IST. Info- NEFT/AXOIC26000001/ACME SALARY. Avl Bal-INR 60,000.00 - Axis Bank',
      direction: TxnDirection.credit,
      amountMinor: 5000000,
      kind: TxnKind.salary,
      accountLast4: '2211',
      balanceMinor: 6000000,
    ),
    SmsCase(
      'EMI debit',
      sender: 'AX-AXISBK-S',
      body: 'Dear Customer, EMI of INR 8,250.00 for Loan A/c XX550012 has been debited from your A/c no. XX802211 on 05-10-26. - Axis Bank',
      direction: TxnDirection.debit,
      amountMinor: 825000,
      kind: TxnKind.emi,
      accountLast4: '2211',
    ),
    SmsCase(
      'UPI P2M debit names the merchant after the reference (#121)',
      sender: 'AX-AXISBK',
      body: 'INR 60.00 debited A/c no. XX5555 22-10-26, 09:14:22 UPI/P2M/629555556666/CHAAYOS Not you? SMS BLOCKUPI Cust ID to 919951860002 Axis Bank',
      direction: TxnDirection.debit,
      amountMinor: 6000,
      kind: TxnKind.general,
      accountLast4: '5555',
      instrument: Instrument.upi,
      counterparty: 'CHAAYOS',
    ),
  ]);

  runSmsCases('Kotak Mahindra Bank', const [
    SmsCase(
      'UPI received from a VPA',
      sender: 'JD-KOTAKB-S',
      body: 'Received Rs.900.00 in your Kotak Bank AC X3390 from meera.j@okaxis on 20-10-26.UPI Ref 629444440001.',
      direction: TxnDirection.credit,
      amountMinor: 90000,
      kind: TxnKind.general,
      bank: 'Kotak Bank',
      accountLast4: '3390',
      counterparty: 'meera.j@okaxis',
      payee: 'Meera J',
    ),
    SmsCase(
      'UPI sent to a merchant QR keeps the raw handle as payee',
      sender: 'JD-KOTAKB-S',
      body: 'Sent Rs.60.00 from Kotak Bank AC X3390 to paytmqr281005050101@paytm on 21-10-26.UPI Ref 629444440002. Not you, https://kotak.com/KBANKT/Fraud',
      direction: TxnDirection.debit,
      amountMinor: 6000,
      kind: TxnKind.general,
      counterparty: 'paytmqr281005050101@paytm',
      payee: 'paytmqr281005050101@paytm',
    ),
    SmsCase(
      'NACH debit',
      sender: 'JD-KOTAKB-S',
      body: 'Your Kotak Bank A/c X3390 is debited with INR 1,000.00 on 05-10-26 towards ACH-DR-HDFC LIFE INSURANCE. Avl Bal INR 9,000.00',
      direction: TxnDirection.debit,
      amountMinor: 100000,
      kind: TxnKind.autopay,
      accountLast4: '3390',
      balanceMinor: 900000,
    ),
    SmsCase(
      'credit card spend',
      sender: 'JD-KOTAKB-S',
      body: 'INR 1,180.00 spent on Kotak Credit Card x7744 on 21-OCT-2026 at BIGBASKET. Avl limit INR 58,820.00',
      direction: TxnDirection.debit,
      amountMinor: 118000,
      kind: TxnKind.cardSpend,
      isCreditCard: true,
      accountLast4: '7744',
      counterparty: 'BIGBASKET',
      payee: 'BigBasket',
    ),
  ]);
}

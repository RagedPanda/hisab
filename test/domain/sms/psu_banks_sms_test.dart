import 'package:hisab/domain/sms/parsed_transaction.dart';

import 'sms_cases.dart';

void main() {
  runSmsCases('Punjab National Bank', const [
    SmsCase(
      'UPI debit',
      sender: 'VM-PNBSMS-S',
      body: 'A/c X5531 debited INR 145.00 Dt 21-10-26 08:10:05 to KAVERI MEDICALS thru UPI:629455550001..Bal INR 7,855.00-PNB',
      direction: TxnDirection.debit,
      amountMinor: 14500,
      kind: TxnKind.general,
      bank: 'PNB',
      accountLast4: '5531',
      counterparty: 'KAVERI MEDICALS',
      payee: 'Kaveri Medicals',
      reference: '629455550001',
    ),
    SmsCase(
      'UPI credit',
      sender: 'VM-PNBSMS-S',
      body: 'A/c X5531 credited INR 2,000.00 Dt 20-10-26 19:00:00 from suresh.p@okpnb thru UPI:629455550002. Bal INR 9,855.00-PNB',
      direction: TxnDirection.credit,
      amountMinor: 200000,
      kind: TxnKind.general,
      counterparty: 'suresh.p@okpnb',
    ),
  ]);

  runSmsCases('Bank of Baroda', const [
    SmsCase(
      'UPI debit with Dr.',
      sender: 'VM-BOBTXN-S',
      body: 'Rs.220.00 Dr. from A/C XXXXXX6620 and Cr. to ravi.t@okbob. Ref:629466660001. AvlBal:Rs4,780.00(2026:10:21 11:20:15). Not you? Call 18005700-BOB',
      direction: TxnDirection.debit,
      amountMinor: 22000,
      kind: TxnKind.general,
      bank: 'Bank of Baroda',
      accountLast4: '6620',
      counterparty: 'ravi.t@okbob',
      balanceMinor: 478000,
    ),
    SmsCase(
      'BOBCARD payment received',
      sender: 'VM-BOBCRD-S',
      body: 'Thank you for the payment of Rs 4,000.00 towards your BOBCARD ending 7781 received on 20-10-2026.',
      direction: TxnDirection.credit,
      amountMinor: 400000,
      kind: TxnKind.cardPayment,
      bank: 'BOBCARD',
      isCreditCard: true,
      accountLast4: '7781',
    ),
  ]);

  runSmsCases('Canara Bank', const [
    SmsCase(
      'UPI debit',
      sender: 'VM-CANBNK-S',
      body: 'An amount of INR 350.00 has been DEBITED to your account XXX4417 on 21/10/2026 towards UPI to SHIV DAIRY. Total Avail.bal INR 6,650.00. - Canara Bank',
      direction: TxnDirection.debit,
      amountMinor: 35000,
      kind: TxnKind.general,
      bank: 'Canara Bank',
      accountLast4: '4417',
      counterparty: 'SHIV DAIRY',
      balanceMinor: 665000,
    ),
    SmsCase(
      'failed UPI reversed to the account',
      sender: 'VM-CANBNK-S',
      body: 'Your failed UPI txn of INR 250.00 has been reversed to your account XXX4417 on 21/10/2026. Ref 629477770001 - Canara Bank',
      direction: TxnDirection.credit,
      amountMinor: 25000,
      kind: TxnKind.refund,
      accountLast4: '4417',
    ),
  ]);

  runSmsCases('Union Bank of India', const [
    SmsCase(
      'UPI debit',
      sender: 'VM-UNIONB-S',
      body: 'A/c *2208 Debited for Rs:500.00 on 21-10-2026 08:45:12 by Mob Bk ref no 629488880001 Avl Bal Rs:12,500.00.If not you, Call 1800222243 -Union Bank of India',
      direction: TxnDirection.debit,
      amountMinor: 50000,
      kind: TxnKind.general,
      bank: 'Union Bank',
      accountLast4: '2208',
      balanceMinor: 1250000,
      reference: '629488880001',
    ),
    SmsCase(
      'credit by UPI',
      sender: 'VM-UBOIND-S',
      body: 'A/c *2208 Credited for Rs:1,500.00 on 20-10-2026 18:00:00 by UPI ref no 629488880002 Avl Bal Rs:14,000.00 -Union Bank of India',
      direction: TxnDirection.credit,
      amountMinor: 150000,
      kind: TxnKind.general,
      bank: 'Union Bank',
      accountLast4: '2208',
      balanceMinor: 1400000,
    ),
  ]);
}

import 'package:hisab/domain/sms/parsed_transaction.dart';

import 'sms_cases.dart';

void main() {
  runSmsCases('Wallet top-ups', const [
    SmsCase(
      'Paytm wallet add money',
      sender: 'VM-PAYTMM-S',
      body: 'Rs.500 added to your Paytm Wallet from HDFC Bank A/c XX7781. Updated balance: Rs.750.',
      direction: TxnDirection.credit,
      amountMinor: 50000,
      kind: TxnKind.walletTopUp,
      bank: 'Paytm',
      instrument: Instrument.wallet,
      balanceMinor: 75000,
    ),
    SmsCase(
      'Amazon Pay balance top-up',
      sender: 'VM-AMZPAY-S',
      body: 'Rs.1,000.00 has been added to your Amazon Pay balance on 21-10-26. Amazon Pay balance: Rs.1,240.00',
      direction: TxnDirection.credit,
      amountMinor: 100000,
      kind: TxnKind.walletTopUp,
      bank: 'Amazon Pay',
      instrument: Instrument.wallet,
    ),
    SmsCase(
      'bank side of a wallet load',
      sender: 'VM-HDFCBK-S',
      body: 'Rs.500.00 debited from A/c XX7781 on 21-10-26 to MobiKwik wallet top-up. UPI Ref 629460600001.',
      direction: TxnDirection.debit,
      amountMinor: 50000,
      kind: TxnKind.walletTopUp,
      bank: 'HDFC Bank',
      accountLast4: '7781',
    ),
    SmsCase(
      'wallet spend is an ordinary debit',
      sender: 'VM-PAYTMM-S',
      body: 'Rs.250 paid from Paytm Wallet to CHAI POINT on 21-10-26. Updated balance: Rs.500',
      direction: TxnDirection.debit,
      amountMinor: 25000,
      kind: TxnKind.general,
      instrument: Instrument.wallet,
      counterparty: 'CHAI POINT',
    ),
  ]);
}

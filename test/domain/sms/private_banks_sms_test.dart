import 'package:hisab/domain/sms/parsed_transaction.dart';

import 'sms_cases.dart';

void main() {
  runSmsCases('IDFC First Bank', const [
    SmsCase(
      'UPI debit with merchant credited',
      sender: 'VM-IDFCFB-S',
      body: 'Your A/c XX9031 debited by Rs. 899.00 on 21/10/26; DECATHLON SPORTS credited. RRN 629499990001. Available balance Rs. 4,101.00. Team IDFC FIRST Bank',
      direction: TxnDirection.debit,
      amountMinor: 89900,
      kind: TxnKind.general,
      bank: 'IDFC First Bank',
      accountLast4: '9031',
      counterparty: 'DECATHLON SPORTS',
      payee: 'Decathlon',
    ),
  ]);

  runSmsCases('Yes Bank', const [
    SmsCase(
      'UPI debit',
      sender: 'VM-YESBNK-S',
      body: 'INR 150.00 debited from YES BANK A/c XX6120 on 21-10-2026 towards UPI/629410100001/FRESH JUICE BAR. Avl Bal INR 3,850.00',
      direction: TxnDirection.debit,
      amountMinor: 15000,
      kind: TxnKind.general,
      bank: 'Yes Bank',
      accountLast4: '6120',
      counterparty: 'FRESH JUICE BAR',
      balanceMinor: 385000,
    ),
  ]);

  runSmsCases('IndusInd Bank', const [
    SmsCase(
      'credit card spend',
      sender: 'VM-INDUSB-S',
      body: 'INR 2,340.00 spent on IndusInd Bank Credit Card XX3345 at RELIANCE DIGITAL on 21-10-26. Avl Lmt INR 97,660.00',
      direction: TxnDirection.debit,
      amountMinor: 234000,
      kind: TxnKind.cardSpend,
      bank: 'IndusInd Bank',
      isCreditCard: true,
      accountLast4: '3345',
      counterparty: 'RELIANCE DIGITAL',
      availableLimitMinor: 9766000,
    ),
    SmsCase(
      'IMPS credit',
      sender: 'VM-INDUSB-S',
      body: 'Your IndusInd A/c 1006XXXX7712 is credited with INR 3,000.00 on 20-10-26 by IMPS from NEHA GUPTA. Ref 629420200001.',
      direction: TxnDirection.credit,
      amountMinor: 300000,
      kind: TxnKind.general,
      accountLast4: '7712',
      instrument: Instrument.imps,
      counterparty: 'NEHA GUPTA',
    ),
  ]);

  runSmsCases('AU Small Finance Bank', const [
    SmsCase(
      'UPI debit',
      sender: 'VM-AUBANK-S',
      body: 'Debited INR 75.00 from A/c XX8854 on 21-10-26 to vegmart@ybl via UPI Ref 629430300001. Bal INR 1,925.00 - AU Bank',
      direction: TxnDirection.debit,
      amountMinor: 7500,
      kind: TxnKind.general,
      bank: 'AU Small Finance Bank',
      accountLast4: '8854',
      counterparty: 'vegmart@ybl',
      payee: 'Vegmart',
      balanceMinor: 192500,
    ),
  ]);

  runSmsCases('Federal Bank', const [
    SmsCase(
      'UPI debit with VPA',
      sender: 'VM-FEDBNK-S',
      body: 'Rs 260.00 debited from your A/c XX4409 to VPA tea.stall@okfederal on 21-10-2026. Ref No 629440400001. Bal Rs 4,740.00 -Federal Bank',
      direction: TxnDirection.debit,
      amountMinor: 26000,
      kind: TxnKind.general,
      bank: 'Federal Bank',
      accountLast4: '4409',
      counterparty: 'tea.stall@okfederal',
      payee: 'Tea Stall',
      balanceMinor: 474000,
    ),
    SmsCase(
      'standing instruction debit',
      sender: 'VM-FEDBNK-S',
      body: 'Rs 5,000.00 debited from your A/c XX4409 on 01-10-2026 by Standing Instruction to RD account. Bal Rs 2,000.00 -Federal Bank',
      direction: TxnDirection.debit,
      amountMinor: 500000,
      kind: TxnKind.autopay,
      accountLast4: '4409',
    ),
  ]);
}

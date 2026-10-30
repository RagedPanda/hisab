import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/sms/parsed_transaction.dart';
import 'package:hisab/domain/sms/sms_categorizer.dart';

import 'sms_cases.dart';

/// A message kind settles the category even when the merchant text would
/// point elsewhere.
void main() {
  const cases = <String, (String, String)>{
    'salary': ('VM-SBIINB-S', 'Dear Customer, Your A/C XXXXX4821 has a credit by NEFT of Rs 85,000.00 on 31/10/26 by ACME SOFTWARE PVT LTD SALARY.'),
    'refunds_cashback': ('VM-SBIINB-S', 'Refund of Rs 349.00 from IRCTC credited to your A/c X4821 on 19Oct26.'),
    'cash_withdrawal': ('AD-ATMSBI-S', 'Rs.2000 withdrawn at SBI ATM S1NW000123001 from A/cX4821 on 21Oct26.'),
    'loan_emi': ('AX-AXISBK-S', 'EMI of INR 8,250.00 for Loan A/c XX550012 has been debited from your A/c no. XX802211 on 05-10-26.'),
    'wallet_topup': ('VM-HDFCBK-S', 'Rs.500.00 debited from A/c XX7781 on 21-10-26 to MobiKwik wallet top-up.'),
    'credit_card_payment': ('VM-HDFCBK-S', 'Rs.15,000.00 debited from A/c XX7781 on 20-10-26 towards CRED CLUB credit card bill. UPI Ref 629450500001.'),
  };
  group('category from message kind', () {
    for (final MapEntry(key: category, value: (sender, body)) in cases.entries) {
      test(category, () => expect(suggestCategoryKey(parseSms(sender, body)!), category));
    }
  });

  test('a bank debit towards a card bill is a card payment, not Other', () {
    final parsed = parseSms('VM-HDFCBK-S', 'Rs 12,000.00 debited from HDFC Bank A/c XX7781 on 21-10-26 towards HDFC Credit Card bill. Avl Bal Rs 30,000.00')!;
    expect(suggestCategoryKey(parsed), 'credit_card_payment');
  });

  test('a refund credited to a credit card is a refund, not a card payment (#119)', () {
    final parsed = parseSms(
      'BP-ICICIT',
      'Dear Customer, a refund of INR 1,299.00 from AMAZON has been credited to your ICICI Bank Credit Card XX2222 on 21-Oct-26.',
    )!;
    expect(parsed.isCreditCard, isTrue);
    expect(parsed.direction, TxnDirection.credit);
    expect(parsed.amountMinor, 129900);
    expect(suggestCategoryKey(parsed), 'refunds_cashback');
  });
}

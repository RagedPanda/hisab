import 'package:flutter_test/flutter_test.dart';
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
    'credit_card_payment': ('VM-HDFCBK-S', 'Payment of Rs 12,000.00 received on your HDFC Bank Credit Card ending 9902 on 20-10-2026.'),
  };
  group('category from message kind', () {
    for (final MapEntry(key: category, value: (sender, body)) in cases.entries) {
      test(category, () => expect(suggestCategoryKey(parseSms(sender, body)!), category));
    }
  });
}

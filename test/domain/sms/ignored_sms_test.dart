import 'sms_cases.dart';

/// Messages that move no money. Each must parse to null.
void main() {
  runIgnoredCases('OTP', const [
    IgnoredSms('card transaction OTP', sender: 'VM-HDFCBK-S', body: '482910 is the OTP for txn of INR 2,000.00 at AMAZON on HDFC Bank Card ending 9902. Valid till 10:15. Do not share OTP for security reasons.'),
    IgnoredSms('UPI PIN OTP', sender: 'JD-ICICIT-S', body: 'Dear Customer, 551203 is your one time password for UPI registration. Never share it with anyone. -ICICI Bank'),
    IgnoredSms('e-mandate OTP', sender: 'VM-SBIINB-S', body: 'OTP 773311 for e-mandate registration of Rs 649.00 for NETFLIX on SBI A/c X4821. Do not share.'),
    IgnoredSms('verification code', sender: 'AX-AXISBK-S', body: 'Use verification code 202611 to authorise the payment of INR 1,499.00 on Axis Bank Card XX4321.'),
  ]);

  runIgnoredCases('Promotional', const [
    IgnoredSms('cashback offer', sender: 'VM-HDFCBK-S', body: 'Get flat 10% cashback on Swiggy with your HDFC Bank Credit Card. T&C apply.'),
    IgnoredSms('promotional DLT suffix', sender: 'VM-HDFCBK-P', body: 'Rs 5,000 credited instantly to your account with our Xpress loan in 10 seconds!'),
    IgnoredSms('pre-approved loan', sender: 'JD-ICICIT-S', body: 'Pre-approved Personal Loan of Rs 3,00,000 credited instantly. Apply now on iMobile.'),
    IgnoredSms('limit enhancement', sender: 'AX-AXISBK-S', body: 'Your Axis Bank Credit Card XX4321 is eligible for a limit enhancement to Rs 1,50,000. Reply YES.'),
    IgnoredSms('upgrade offer', sender: 'VM-SBICRD-S', body: 'Exclusive: Upgrade now to SBI Card ELITE and enjoy 5X reward points on spends above Rs 10,000.'),
  ]);

  runIgnoredCases('Balance only', const [
    IgnoredSms('daily balance', sender: 'VM-HDFCBK-S', body: 'Available Bal in HDFC Bank A/c XX7781 as on yesterday:21-OCT-26 is INR 12,345.00. Cheques are subject to clearing.'),
    IgnoredSms('balance enquiry', sender: 'VM-SBIINB-S', body: 'Your A/C XXXXX4821 has balance of Rs 5,000.00 as on 21/10/26 -SBI'),
    IgnoredSms('card limit', sender: 'VM-SBICRD-S', body: 'Available limit on your SBI Credit Card ending 5512 is Rs 50,000.00 as on 21-10-26.'),
    IgnoredSms('missed-call balance', sender: 'JD-KOTAKB-S', body: 'Bal in Kotak Bank AC X3390 on 21-10-26 10:00 is Rs.9,000.00'),
  ]);

  runIgnoredCases('Mandate and pre-debit notices', const [
    IgnoredSms('UPI mandate created', sender: 'VM-HDFCBK-S', body: 'UPI Mandate for Rs 649.00 towards Netflix Entertainment successfully created on HDFC Bank A/c XX7781.'),
    IgnoredSms('NACH registered', sender: 'JD-KOTAKB-S', body: 'NACH mandate UMRN KKBK7000000001 for max Rs 5,000.00 registered on your Kotak Bank AC X3390.'),
    IgnoredSms('pre-debit notification', sender: 'JD-ICICIT-S', body: 'Your ICICI Bank Credit Card XX6611 will be debited with INR 199.00 on 25-Oct-26 for SPOTIFY via e-mandate.'),
    IgnoredSms('autopay revoked', sender: 'VM-SBIINB-S', body: 'Your AutoPay of Rs 299.00 to HOTSTAR on SBI A/c X4821 has been revoked.'),
  ]);

  runIgnoredCases('Other non-transactions', const [
    IgnoredSms('payment request', sender: 'VM-PHONPE-S', body: 'Anil Rao has requested Rs.500 from you on PhonePe. Pay now.'),
    IgnoredSms('failed debit', sender: 'VM-HDFCBK-S', body: 'Txn of Rs 1,200.00 on HDFC Bank Card 9902 at MYNTRA failed due to incorrect PIN.'),
    IgnoredSms('refund initiated, not yet credited', sender: 'VM-HDFCBK-S', body: 'Refund of Rs 499 has been initiated by MYNTRA and will be credited to your card in 5-7 days.'),
    IgnoredSms('statement', sender: 'VM-HDFCBK-S', body: 'Statement for HDFC Bank Credit Card XX9902: Total amount due Rs 12,000.00, minimum amount due Rs 600.00, due by 05-11-26.'),
  ]);
}

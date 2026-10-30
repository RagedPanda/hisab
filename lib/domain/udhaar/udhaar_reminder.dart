/// The WhatsApp reminder about udhaar someone owes me, with a UPI link that
/// pays me. Pure: the screen supplies the translated sentences.
library;

import '../split/settle_up_links.dart';

/// The note UPI apps show on a payment made from a reminder.
const String kUdhaarUpiNote = 'Hisab';

/// Minor units as a UPI amount without trailing zero paise:
/// 250000 -> "2500", 250050 -> "2500.50".
String upiAmountText(int amountMinor) {
  final amount = upiAmount(amountMinor);
  return amount.endsWith('.00') ? amount.substring(0, amount.length - 3) : amount;
}

/// A query value percent-encoded for a `upi://` link: spaces as %20 (some
/// UPI apps show a form-encoded '+' literally) and '@' kept readable, since
/// a VPA is `name@bank`.
String upiQueryValue(String value) => Uri.encodeComponent(value).replaceAll('%40', '@');

/// `upi://pay?pa=…&pn=…&am=…&cu=INR&tn=Hisab`: any UPI app opens it with me
/// as the payee and the amount filled in. A blank [payeeName] is left out.
String upiPayLink({required String upiId, required String payeeName, required int amountMinor, String currency = 'INR', String note = kUdhaarUpiNote}) {
  final params = {
    'pa': upiId,
    if (payeeName.trim().isNotEmpty) 'pn': payeeName.trim(),
    'am': upiAmountText(amountMinor),
    'cu': currency,
    'tn': note,
  };
  return 'upi://pay?${[for (final param in params.entries) '${param.key}=${upiQueryValue(param.value)}'].join('&')}';
}

/// The reminder: [greeting] ("Hi Rahul, a reminder about ₹2,500 from 12
/// Oct.") followed by [payLine] ("Pay via UPI: upi://…") when there is one.
String udhaarReminderText({required String greeting, String? payLine}) =>
    [greeting.trim(), if (payLine != null && payLine.trim().isNotEmpty) payLine.trim()].join(' ');

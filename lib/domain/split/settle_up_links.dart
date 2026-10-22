import 'debt_simplifier.dart';

/// What I can do about one settle-up transfer.
enum SettleRole {
  /// Someone owes me: I can remind them.
  remind,

  /// I owe someone: I can pay them.
  pay,

  /// Two other people: I can only record that it happened.
  others,
}

SettleRole settleRoleFor(Transfer transfer, String? myMemberId) {
  if (myMemberId == null) return SettleRole.others;
  if (transfer.to == myMemberId) return SettleRole.remind;
  if (transfer.from == myMemberId) return SettleRole.pay;
  return SettleRole.others;
}

final _upiIdPattern = RegExp(r'^[a-z0-9][a-z0-9._-]{1,255}@[a-z][a-z0-9]{1,63}$');

/// The UPI ID trimmed and lower-cased, or null when it is not a valid VPA
/// (`name@bank`). An empty input is null too, meaning "no UPI ID".
String? normaliseUpiId(String raw) {
  final cleaned = raw.trim().toLowerCase();
  return _upiIdPattern.hasMatch(cleaned) ? cleaned : null;
}

/// Minor units as the decimal amount UPI expects, e.g. 123450 -> "1234.50".
String upiAmount(int amountMinor) {
  final rupees = amountMinor ~/ 100;
  final paise = (amountMinor % 100).toString().padLeft(2, '0');
  return '$rupees.$paise';
}

/// A `upi://pay` link any UPI app opens with payee, amount and note filled in.
Uri upiPayUri({required String upiId, required String payeeName, required int amountMinor, required String note, String currency = 'INR'}) => Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {'pa': upiId, 'pn': payeeName, 'am': upiAmount(amountMinor), 'cu': currency, 'tn': note},
    );

/// The phone number as WhatsApp's international digits, assuming India for
/// bare 10-digit numbers. Null when there are too few digits to dial.
String? internationalDigits(String phone, {String defaultCountryCode = '91'}) {
  final hasPlus = phone.trim().startsWith('+');
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (!hasPlus) {
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = '$defaultCountryCode${digits.substring(1)}';
    } else if (digits.length == 10) {
      digits = '$defaultCountryCode$digits';
    }
  }
  return digits.length < 8 ? null : digits;
}

/// `https://wa.me/<number>?text=` chat link, or null when the phone is unusable.
Uri? whatsAppUri(String phone, String text) {
  final number = internationalDigits(phone);
  // Percent-encoded (not form-encoded): some apps show a literal '+' for spaces.
  return number == null ? null : Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(text)}');
}

/// `sms:` link with the body prefilled, or null when the phone is unusable.
Uri? smsUri(String phone, String text) {
  final number = internationalDigits(phone);
  return number == null ? null : Uri.parse('sms:+$number?body=${Uri.encodeComponent(text)}');
}

/// Whole calendar days from [at] to [now] (0 = same day).
int daysBetween(DateTime at, DateTime now) =>
    DateTime(now.year, now.month, now.day).difference(DateTime(at.year, at.month, at.day)).inDays;

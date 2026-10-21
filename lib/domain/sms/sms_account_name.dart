/// Display name for an account discovered from a bank SMS.
///
/// Card issuers such as "SBI Card" already end in "Card", so the suffix is
/// only added when the bank name does not carry it.
String smsAccountName({required String? bank, required bool isCreditCard, required String? last4}) {
  final bankName = bank ?? 'Bank';
  final suffix = last4 == null ? '' : ' ••$last4';
  if (!isCreditCard || bankName.toLowerCase().endsWith('card')) return '$bankName$suffix';
  return '$bankName Card$suffix';
}

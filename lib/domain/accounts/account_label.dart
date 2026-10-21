/// Account name split into the display name and the masked number, so the
/// balance card can put "••1234" on its own line (P2-7).
class AccountLabel {
  const AccountLabel({required this.name, this.mask});
  final String name;
  final String? mask;
}

const String kAccountMaskMarker = '••';

AccountLabel splitAccountLabel(String fullName) {
  final index = fullName.indexOf(kAccountMaskMarker);
  if (index <= 0) return AccountLabel(name: fullName.trim());
  return AccountLabel(name: fullName.substring(0, index).trim(), mask: fullName.substring(index).trim());
}

/// Icon name for each account type; unknown types fall back to cash.
const Map<String, String> kAccountTypeIcons = {
  'bank': 'account_balance',
  'card': 'credit_card',
  'wallet': 'account_balance_wallet',
  'cash': 'payments',
};

String accountIconFor(String type) => kAccountTypeIcons[type] ?? kAccountTypeIcons['cash']!;

/// Sum of the balances that count towards the headline total.
int includedBalanceTotal(Iterable<({bool includeInTotal, int balanceMinor})> accounts) =>
    accounts.where((account) => account.includeInTotal).fold(0, (sum, account) => sum + account.balanceMinor);

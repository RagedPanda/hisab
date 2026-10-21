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

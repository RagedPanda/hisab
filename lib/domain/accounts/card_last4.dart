/// The "Last 4 digits" field of a card in the account editor. The digits are
/// what card SMS are matched on (see `matchingCardId`), so a card added by
/// hand picks up its bank's messages. Pure.
library;

final _last4Pattern = RegExp(r'^\d{4}$');

/// Whether [text] is a usable entry: empty (not set) or exactly four digits.
bool isValidLast4Input(String text) {
  final trimmed = text.trim();
  return trimmed.isEmpty || _last4Pattern.hasMatch(trimmed);
}

/// The digits to store for [text], null when left empty.
String? last4FromInput(String text) {
  final trimmed = text.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// The SMS key a card keeps after its digits are edited: its own while the
/// digits stay, otherwise none, so messages for the old digits stop landing
/// on it and the next SMS for the new digits finds it by them.
String? smsKeyAfterLast4Edit({String? smsKey, String? previousLast4, String? newLast4}) => previousLast4 == newLast4 ? smsKey : null;

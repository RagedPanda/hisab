/// What is wrong with an entry's accounts, if anything, before it is saved.
enum EntryAccountProblem { none, missingAccount, missingBothAccounts, sameAccount }

/// Every personal entry needs an account (#110), and a transfer needs two
/// different ones (#111). Group expenses never touch a personal account.
/// [accountCreatedOnSave] is true for an SMS entry whose account is made from
/// the message while saving.
EntryAccountProblem entryAccountProblem({
  required String kind,
  required bool inGroup,
  required String? accountId,
  required String? toAccountId,
  bool accountCreatedOnSave = false,
}) {
  if (inGroup) return EntryAccountProblem.none;
  if (kind == 'transfer') {
    if (accountId == null || toAccountId == null) return EntryAccountProblem.missingBothAccounts;
    return accountId == toAccountId ? EntryAccountProblem.sameAccount : EntryAccountProblem.none;
  }
  if (accountId == null && !accountCreatedOnSave) return EntryAccountProblem.missingAccount;
  return EntryAccountProblem.none;
}

/// The To account once From becomes [fromId]: kept unless it is now the same
/// account, so the To picker never shows a choice that cannot be saved (#111).
String? toAccountAfterFromChange({required String? fromId, required String? toId}) => toId == fromId ? null : toId;

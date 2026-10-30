import '../../data/db/database.dart';

/// The account a brand-new entry should start on.
///
/// Prefers the account the user pinned in Settings ([configuredId]) when it
/// still exists; otherwise falls back to a cash account, and finally to the
/// first account there is. Pure so it unit-tests without a database.
String? defaultEntryAccountId(List<Account> accounts, {String configuredId = ''}) {
  if (configuredId.isNotEmpty) {
    for (final account in accounts) {
      if (account.id == configuredId) return account.id;
    }
  }
  for (final account in accounts) {
    if (account.type == 'cash') return account.id;
  }
  return accounts.isEmpty ? null : accounts.first.id;
}

/// The bank account a card bill payment read from SMS is taken to come from
/// when no bank SMS names it: the default account when it is a bank account,
/// else the only bank account there is. Null (the user picks) otherwise.
String? cardPaymentSourceAccountId(List<Account> accounts, {String configuredId = ''}) {
  final banks = [for (final account in accounts) if (account.type == 'bank') account];
  for (final bank in banks) {
    if (bank.id == configuredId) return bank.id;
  }
  return banks.length == 1 ? banks.single.id : null;
}

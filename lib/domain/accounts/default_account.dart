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

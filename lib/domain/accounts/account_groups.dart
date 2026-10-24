import 'account_label.dart';

/// Order the entry editor offers account types in.
const List<String> kAccountTypePickerOrder = ['cash', 'bank', 'card', 'wallet'];

/// The stored [type], or cash for a type the app does not know.
String normalizedAccountType(String type) => kAccountTypeIcons.containsKey(type) ? type : 'cash';

/// The accounts of one type, in their original order.
class AccountTypeGroup<T> {
  const AccountTypeGroup({required this.type, required this.accounts});
  final String type;
  final List<T> accounts;

  /// The account a tap on the type picks straight away: the only one, if any.
  T? get onlyAccount => accounts.length == 1 ? accounts.single : null;
}

/// Groups [accounts] by type in [kAccountTypePickerOrder], leaving out types
/// with no accounts.
List<AccountTypeGroup<T>> groupAccountsByType<T>(Iterable<T> accounts, String Function(T) typeOf) => [
      for (final type in kAccountTypePickerOrder)
        if (accounts.where((account) => normalizedAccountType(typeOf(account)) == type).toList() case final ofType when ofType.isNotEmpty)
          AccountTypeGroup(type: type, accounts: ofType),
    ];

/// The account a tap on [group]'s type selects: the selected account when it
/// already belongs to the group, else the group's most recently used account
/// ([recentIds] is most recent first), else its first account (#110).
T accountToPickForType<T>(AccountTypeGroup<T> group, {required String? selectedId, required List<String> recentIds, required String Function(T) idOf}) {
  final byId = {for (final account in group.accounts) idOf(account): account};
  final current = byId[selectedId];
  if (current != null) return current;
  for (final id in recentIds) {
    final recent = byId[id];
    if (recent != null) return recent;
  }
  return group.accounts.first;
}

/// The type of the group holding the account [selectedId], or null.
String? typeHolding<T>(List<AccountTypeGroup<T>> groups, String? selectedId, String Function(T) idOf) {
  if (selectedId == null) return null;
  for (final group in groups) {
    if (group.accounts.any((account) => idOf(account) == selectedId)) return group.type;
  }
  return null;
}

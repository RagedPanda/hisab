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

import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../data/db/database.dart';
import '../../domain/accounts/account_groups.dart';
import '../../domain/accounts/account_label.dart';
import '../../l10n/l10n.dart';
import 'account_choice_chips.dart';
import 'account_type_label.dart';

/// Account types first (only those the user has), then the accounts of the
/// selected account's type. Tapping a type always selects an account in it:
/// the current one if it is already of that type, else the type's most
/// recently used ([recentAccountIds], most recent first), else its first.
/// A type with several accounts also shows them as a second row. The open
/// type always follows [selectedId], so the chips and the account agree.
class GroupedAccountPicker extends StatelessWidget {
  const GroupedAccountPicker({super.key, required this.accounts, required this.selectedId, required this.onPick, this.recentAccountIds = const []});
  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String?> onPick;
  final List<String> recentAccountIds;

  String _idOf(Account account) => account.id;

  @override
  Widget build(BuildContext context) {
    final groups = groupAccountsByType(accounts, (account) => account.type);
    if (groups.isEmpty) return AccountChoiceChips(accounts: const [], selectedId: null, onPick: onPick);
    final l10n = context.l10n;
    final openType = typeHolding(groups, selectedId, _idOf);
    final openGroup = groups.where((group) => group.type == openType).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final group in groups)
              ChoiceChip(
                key: ValueKey('account-type-${group.type}'),
                avatar: Icon(iconFor(accountIconFor(group.type)), size: 18),
                label: Text(accountTypeLabel(l10n, group.type)),
                selected: group.type == openType,
                onSelected: (_) => onPick(_idOf(accountToPickForType(group, selectedId: selectedId, recentIds: recentAccountIds, idOf: _idOf))),
              ),
          ],
        ),
        if (openGroup != null && openGroup.onlyAccount == null) ...[
          const SizedBox(height: 8),
          AccountChoiceChips(accounts: openGroup.accounts, selectedId: selectedId, onPick: onPick),
        ],
      ],
    );
  }
}

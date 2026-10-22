import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/database.dart';
import '../../l10n/l10n.dart';

/// One chip per account to pick from; offers "Add account" when there are none.
class AccountChoiceChips extends StatelessWidget {
  const AccountChoiceChips({super.key, required this.accounts, required this.selectedId, required this.onPick});
  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String?> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final account in accounts)
          ChoiceChip(
            avatar: CircleAvatar(backgroundColor: Color(account.color), radius: 6),
            label: Text(account.name),
            selected: selectedId == account.id,
            onSelected: (_) => onPick(account.id),
          ),
        if (accounts.isEmpty) ActionChip(label: Text(context.l10n.addAccount), avatar: const Icon(Icons.add, size: 16), onPressed: () => context.push('/accounts')),
      ],
    );
  }
}

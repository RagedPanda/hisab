import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_icons.dart';
import '../../data/db/database.dart';
import '../../domain/accounts/account_groups.dart';
import '../../domain/accounts/account_label.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'account_type_label.dart';

/// One row showing the chosen account, like the category tile; tapping it
/// opens a sheet of every account grouped by type. With no accounts yet the
/// row offers "Add account" instead.
class AccountPickerTile extends StatelessWidget {
  const AccountPickerTile({super.key, required this.label, required this.accounts, required this.selectedId, required this.onPick});
  final String label;
  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = accounts.where((account) => account.id == selectedId).firstOrNull;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: selected == null
          ? const IconBadge(icon: 'account_balance_wallet', color: 0xFF9E9E9E)
          : IconBadge(icon: accountIconFor(normalizedAccountType(selected.type)), color: selected.color),
      title: Text(selected?.name ?? (accounts.isEmpty ? l10n.addAccount : l10n.errorPickAccount)),
      subtitle: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        if (accounts.isEmpty) {
          context.push('/accounts');
          return;
        }
        final picked = await showAccountPicker(context, accounts: accounts, selectedId: selectedId);
        if (picked != null) onPick(picked);
      },
    );
  }
}

/// Bottom sheet listing [accounts] under their type; returns the picked id,
/// or null when dismissed.
Future<String?> showAccountPicker(BuildContext context, {required List<Account> accounts, required String? selectedId}) {
  final l10n = context.l10n;
  final groups = groupAccountsByType(accounts, (account) => account.type);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        for (final group in groups) ...[
          SectionHeader(accountTypeLabel(l10n, group.type), padding: const EdgeInsets.fromLTRB(16, 8, 16, 4)),
          for (final account in group.accounts)
            ListTile(
              key: ValueKey('account-option-${account.id}'),
              leading: Icon(iconFor(accountIconFor(group.type)), color: Color(account.color)),
              title: Text(account.name),
              trailing: account.id == selectedId ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(account.id),
            ),
        ],
      ],
    ),
  );
}

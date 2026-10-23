import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../data/db/database.dart';
import '../../domain/accounts/account_groups.dart';
import '../../domain/accounts/account_label.dart';
import '../../l10n/l10n.dart';
import 'account_choice_chips.dart';
import 'account_type_label.dart';

/// Account types first (only those the user has), then the accounts of the
/// chosen type. A type with a single account picks it in one tap; a type
/// with several shows them as a second row, with none picked until the user
/// chooses. Opens on the type of [selectedId] when there is one.
class GroupedAccountPicker extends StatefulWidget {
  const GroupedAccountPicker({super.key, required this.accounts, required this.selectedId, required this.onPick});
  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String?> onPick;

  @override
  State<GroupedAccountPicker> createState() => _GroupedAccountPickerState();
}

class _GroupedAccountPickerState extends State<GroupedAccountPicker> {
  String? _openType;

  List<AccountTypeGroup<Account>> get _groups => groupAccountsByType(widget.accounts, (account) => account.type);

  @override
  void initState() {
    super.initState();
    _openType = typeHolding(_groups, widget.selectedId, (account) => account.id);
  }

  @override
  void didUpdateWidget(GroupedAccountPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedType = typeHolding(_groups, widget.selectedId, (account) => account.id);
    if (selectedType != null) _openType = selectedType;
  }

  void _openGroup(AccountTypeGroup<Account> group) {
    setState(() => _openType = group.type);
    final only = group.onlyAccount;
    if (only != null) {
      widget.onPick(only.id);
    } else if (typeHolding([group], widget.selectedId, (account) => account.id) == null) {
      widget.onPick(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    if (groups.isEmpty) return AccountChoiceChips(accounts: const [], selectedId: null, onPick: widget.onPick);
    final l10n = context.l10n;
    final openGroup = groups.where((group) => group.type == _openType).firstOrNull;
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
                selected: group.type == openGroup?.type,
                onSelected: (_) => _openGroup(group),
              ),
          ],
        ),
        if (openGroup != null && openGroup.onlyAccount == null) ...[
          const SizedBox(height: 8),
          AccountChoiceChips(accounts: openGroup.accounts, selectedId: widget.selectedId, onPick: widget.onPick),
        ],
      ],
    );
  }
}

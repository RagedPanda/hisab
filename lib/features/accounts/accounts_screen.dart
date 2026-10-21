import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';

/// (stored type value, icon name). Labels come from [_typeLabel].
const _types = [('bank', 'account_balance'), ('card', 'credit_card'), ('wallet', 'account_balance_wallet'), ('cash', 'payments')];

String _typeLabel(AppLocalizations l10n, String type) => switch (type) {
      'bank' => l10n.accountTypeBank,
      'card' => l10n.accountTypeCard,
      'wallet' => l10n.accountTypeWallet,
      _ => l10n.accountTypeCash,
    };

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accounts)),
      floatingActionButton: FloatingActionButton.extended(heroTag: 'add-account', onPressed: () => _showForm(context, ref), icon: const Icon(Icons.add), label: Text(l10n.account)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Card(
            child: Column(children: [
              for (final account in accounts)
                ListTile(
                  leading: IconBadge(icon: _types.firstWhere((t) => t.$1 == account.type, orElse: () => _types.last).$2, color: account.color),
                  title: Text(account.name),
                  subtitle: Text([
                    if (account.bankName != null) account.bankName!,
                    if (account.last4 != null) '••${account.last4}',
                    if (account.balanceAsOf != null) l10n.asOf(formatShortDate(account.balanceAsOf!)),
                    if (!account.includeInTotal) l10n.excludedFromTotal,
                  ].join(' · ')),
                  trailing: Text(formatMinor(account.balanceMinor, symbol: symbol), style: TextStyle(fontWeight: FontWeight.w700, color: account.balanceMinor < 0 ? kExpenseColor : null)),
                  onTap: () => _showForm(context, ref, existing: account),
                ),
              if (accounts.isEmpty) ListTile(title: Text(l10n.noAccountsTitle)),
            ]),
          ),
          const SizedBox(height: 12),
          Text(l10n.noAccountsBody, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Future<void> _showForm(BuildContext context, WidgetRef ref, {Account? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final balanceController = TextEditingController(text: existing == null ? '' : minorToDouble(existing.balanceMinor).toStringAsFixed(2));
    var type = existing?.type ?? 'bank';
    var color = existing?.color ?? kPaletteColors.first;
    var include = existing?.includeInTotal ?? true;
    final l10n = context.l10n;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(sheetContext).bottom + 16),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(existing == null ? l10n.newAccount : l10n.editAccount, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(controller: nameController, autofocus: existing == null, decoration: InputDecoration(labelText: l10n.name, hintText: l10n.accountNameHint), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final option in _types) ChoiceChip(label: Text(_typeLabel(l10n, option.$1)), selected: type == option.$1, onSelected: (_) => setSheetState(() => type = option.$1)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(labelText: type == 'card' ? l10n.outstandingBalance : l10n.currentBalance),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in kPaletteColors)
                    GestureDetector(
                      onTap: () => setSheetState(() => color = option),
                      child: CircleAvatar(radius: 16, backgroundColor: Color(option), child: color == option ? const Icon(Icons.check, color: Colors.white, size: 18) : null),
                    ),
                ],
              ),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l10n.includeInTotal), value: include, onChanged: (v) => setSheetState(() => include = v)),
              const SizedBox(height: 8),
              Row(children: [
                if (existing != null)
                  TextButton(
                    onPressed: () async {
                      if (await confirmDialog(sheetContext, title: l10n.deleteNamed(existing.name))) {
                        await ref.read(accountsRepositoryProvider).delete(existing.id);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      }
                    },
                    child: Text(l10n.delete),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final balance = parseAmountToMinor(balanceController.text.replaceAll('-', '')) ?? 0;
                    final signed = balanceController.text.trim().startsWith('-') ? -balance : balance;
                    final repo = ref.read(accountsRepositoryProvider);
                    if (existing == null) {
                      await repo.create(name: name, type: type, color: color, balanceMinor: signed, includeInTotal: include);
                    } else {
                      await repo.update(AccountsCompanion(
                        id: Value(existing.id),
                        name: Value(name),
                        type: Value(type),
                        color: Value(color),
                        balanceMinor: Value(signed),
                        balanceAsOf: Value(signed == existing.balanceMinor ? existing.balanceAsOf : DateTime.now()),
                        includeInTotal: Value(include),
                      ));
                    }
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  child: Text(l10n.save),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

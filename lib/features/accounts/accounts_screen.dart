import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../shell/widgets/common.dart';

const _types = [('bank', 'Bank account', 'account_balance'), ('card', 'Credit card', 'credit_card'), ('wallet', 'Wallet / UPI', 'account_balance_wallet'), ('cash', 'Cash', 'payments')];

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final symbol = ref.watch(settingsProvider).currencySymbol;
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton.extended(heroTag: 'add-account', onPressed: () => _showForm(context, ref), icon: const Icon(Icons.add), label: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Card(
            child: Column(children: [
              for (final account in accounts)
                ListTile(
                  leading: IconBadge(icon: _types.firstWhere((t) => t.$1 == account.type, orElse: () => _types.last).$3, color: account.color),
                  title: Text(account.name),
                  subtitle: Text([
                    if (account.bankName != null) account.bankName!,
                    if (account.last4 != null) '••${account.last4}',
                    if (account.balanceAsOf != null) 'as of ${formatShortDate(account.balanceAsOf!)}',
                    if (!account.includeInTotal) 'excluded from total',
                  ].join(' · ')),
                  trailing: Text(formatMinor(account.balanceMinor, symbol: symbol), style: TextStyle(fontWeight: FontWeight.w700, color: account.balanceMinor < 0 ? kExpenseColor : null)),
                  onTap: () => _showForm(context, ref, existing: account),
                ),
              if (accounts.isEmpty) const ListTile(title: Text('No accounts yet')),
            ]),
          ),
          const SizedBox(height: 12),
          Text('Bank accounts detected from SMS are added automatically with their reported balance. Manual entries adjust the balance of the account you pick.',
              style: Theme.of(context).textTheme.bodySmall),
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
              Text(existing == null ? 'New account' : 'Edit account', style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(controller: nameController, autofocus: existing == null, decoration: const InputDecoration(labelText: 'Name', hintText: 'HDFC Savings, Paytm, Cash'), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final option in _types) ChoiceChip(label: Text(option.$2), selected: type == option.$1, onSelected: (_) => setSheetState(() => type = option.$1)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(labelText: type == 'card' ? 'Outstanding (negative = you owe)' : 'Current balance'),
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
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Include in total balance'), value: include, onChanged: (v) => setSheetState(() => include = v)),
              const SizedBox(height: 8),
              Row(children: [
                if (existing != null)
                  TextButton(
                    onPressed: () async {
                      if (await confirmDialog(sheetContext, title: 'Delete ${existing.name}?')) {
                        await ref.read(accountsRepositoryProvider).delete(existing.id);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      }
                    },
                    child: const Text('Delete'),
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
                      await repo.create(name: name, type: type, color: color, balanceMinor: signed);
                      await repo.update(AccountsCompanion(id: Value((await repo.getAll()).last.id), includeInTotal: Value(include)));
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
                  child: const Text('Save'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../domain/accounts/account_label.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'account_type_label.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accounts)),
      floatingActionButton: FloatingActionButton.extended(heroTag: 'add-account', onPressed: () => showAccountForm(context, ref), icon: const Icon(Icons.add), label: Text(l10n.account)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Card(
            child: Column(children: [
              for (final account in accounts)
                ListTile(
                  leading: IconBadge(icon: accountIconFor(account.type), color: account.color),
                  title: Text(account.name),
                  subtitle: Text([
                    if (account.bankName != null) account.bankName!,
                    if (account.last4 != null) '••${account.last4}',
                    if (account.balanceAsOf != null) l10n.asOf(formatShortDate(account.balanceAsOf!)),
                    if (!account.includeInTotal) l10n.excludedFromTotal,
                  ].join(' · ')),
                  trailing: Text(
                    account.type == 'card' ? l10n.cardDue(formatMinor(account.balanceMinor.abs(), symbol: symbol)) : formatMinor(account.balanceMinor, symbol: symbol),
                    style: TextStyle(fontWeight: FontWeight.w700, color: account.balanceMinor < 0 && account.type != 'card' ? kExpenseColor : null),
                  ),
                  onTap: () => showAccountForm(context, ref, existing: account),
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
}

/// Opens the create/edit account sheet. [focusBalance] lands the cursor in the
/// balance field, used by the "Set opening balance" prompt.
Future<void> showAccountForm(BuildContext context, WidgetRef ref, {Account? existing, bool focusBalance = false}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    // Card balances are stored negative (money owed) but entered as the
    // positive amount due, so there is never a sign to type on a number pad.
    final balanceController = TextEditingController(text: existing == null ? '' : amountInputText(existing.type == 'card' ? existing.balanceMinor.abs() : existing.balanceMinor));
    var type = existing?.type ?? 'bank';
    var color = existing?.color ?? kPaletteColors.first;
    var include = existing?.includeInTotal ?? true;
    final l10n = context.l10n;
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
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
              TextField(controller: nameController, autofocus: existing == null && !focusBalance, decoration: InputDecoration(labelText: l10n.name, hintText: l10n.accountNameHint), textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final option in kAccountTypeIcons.keys) ChoiceChip(label: Text(accountTypeLabel(l10n, option)), selected: type == option, onSelected: (_) => setSheetState(() => type = option)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: balanceController,
                autofocus: focusBalance,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: amountInputFormatters,
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
                if (existing != null) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final signed = signedBalanceForType(type, parseAmountToMinor(balanceController.text) ?? 0);
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
                ),
              ]),
            ],
          ),
        ),
      ),
    );
}

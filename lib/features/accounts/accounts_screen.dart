import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../domain/accounts/account_label.dart';
import '../../domain/accounts/balance_input.dart';
import '../../domain/cards/card_summary.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import '../reminders/reminder_actions.dart';
import 'account_type_label.dart';
import 'card_reminder_sync.dart';

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
                    account.type != 'card'
                        ? formatMinor(account.balanceMinor, symbol: symbol)
                        : account.balanceMinor > 0
                            ? l10n.cardInCredit(formatMinor(account.balanceMinor, symbol: symbol))
                            : l10n.cardDue(formatMinor(account.balanceMinor.abs(), symbol: symbol)),
                    style: TextStyle(fontWeight: FontWeight.w700, color: account.balanceMinor < 0 && account.type != 'card' ? kExpenseColor : null),
                  ),
                  onTap: () => account.type == 'card' ? openCardAccount(context, account.id) : showAccountForm(context, ref, existing: account),
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

/// Opens the credit card screen for [accountId].
void openCardAccount(BuildContext context, String accountId) => context.push('/accounts/card/$accountId');

/// Opens the create/edit account sheet. [focusBalance] lands the cursor in the
/// balance field, used by the "Set opening balance" prompt.
Future<void> showAccountForm(BuildContext context, WidgetRef ref, {Account? existing, bool focusBalance = false}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    // The field takes a plain amount (there is no sign to type on a number
    // pad); [balanceNegative] carries the direction, so a card's credit stays
    // credit (#98) and a type change keeps what the balance means.
    final balanceController = TextEditingController(text: existing == null ? '' : amountInputText(balanceInputMinor(existing.balanceMinor)));
    var type = existing?.type ?? 'bank';
    var balanceNegative = existing == null ? defaultBalanceNegative(type) : existing.balanceMinor < 0;
    var color = existing?.color ?? kPaletteColors.first;
    var include = existing?.includeInTotal ?? true;
    var statementDay = existing?.statementDay;
    var dueDay = existing?.dueDay;
    String? statementError;
    final limitController = TextEditingController(text: existing?.creditLimitMinor == null ? '' : amountInputText(existing!.creditLimitMinor!));
    final lastStatementController = TextEditingController(text: existing?.lastStatementMinor == null ? '' : amountInputText(existing!.lastStatementMinor!));
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
                  for (final option in kAccountTypeIcons.keys) ChoiceChip(label: Text(accountTypeLabel(l10n, option)), selected: type == option, onSelected: (_) => setSheetState(() {
                            balanceNegative = balanceNegativeAfterTypeChange(negative: balanceNegative, enteredMinor: parseAmountToMinor(balanceController.text) ?? 0, toType: option);
                            type = option;
                          })),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: balanceController,
                autofocus: focusBalance,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: amountInputFormatters,
                decoration: InputDecoration(labelText: type != 'card' ? l10n.currentBalance : balanceNegative ? l10n.outstandingBalance : l10n.cardCreditOnCard),
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                key: const ValueKey('account.balanceDirection'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: false, label: Text(type == 'card' ? l10n.cardBalanceCredit : l10n.balanceInAccount)),
                  ButtonSegment(value: true, label: Text(type == 'card' ? l10n.cardBalanceOwed : l10n.balanceOverdrawn)),
                ],
                selected: {balanceNegative},
                onSelectionChanged: (selection) => setSheetState(() => balanceNegative = selection.single),
              ),
              if (type == 'card') ...[
                const SizedBox(height: 12),
                _CardFields(
                  statementDay: statementDay,
                  dueDay: dueDay,
                  limitController: limitController,
                  lastStatementController: lastStatementController,
                  statementError: statementError,
                  onStatementChanged: () {
                    if (statementError != null) setSheetState(() => statementError = null);
                  },
                  onStatementDay: (value) => setSheetState(() => statementDay = value),
                  onDueDay: (value) => setSheetState(() => dueDay = value),
                ),
              ],
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
                        await syncCardReminderSafely(() => ref.read(cardReminderSyncProvider).removeForAccount(existing.id));
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
                    final signed = signedBalanceFromInput(enteredMinor: parseAmountToMinor(balanceController.text) ?? 0, negative: balanceNegative);
                    final repo = ref.read(accountsRepositoryProvider);
                    final card = cardFieldsFromForm(
                      isCard: type == 'card',
                      statementDay: statementDay,
                      dueDay: dueDay,
                      limitText: limitController.text,
                      lastStatementText: lastStatementController.text,
                      existing: existing,
                    );
                    if (type == 'card') {
                      final amountDueMinor = outstandingMinor(signed);
                      final statementAt = card.lastStatementAt;
                      final paidSince = existing == null || statementAt == null
                          ? 0
                          : paymentsSinceMinor(await ref.read(entriesRepositoryProvider).getAccountMovements(existing.id, since: statementAt), cardId: existing.id, since: statementAt);
                      final previousStatement = existing?.type == 'card' ? existing?.lastStatementMinor : null;
                      if (lastStatementExceedsAmountDue(lastStatementMinor: card.lastStatementMinor, amountDueMinor: amountDueMinor, previousStatementMinor: previousStatement, paidSinceStatementMinor: paidSince)) {
                        final symbol = ref.read(settingsProvider).currencySymbol;
                        setSheetState(() => statementError = l10n.cardStatementOverAmountDue(formatMinor(amountDueMinor, symbol: symbol)));
                        return;
                      }
                    }
                    final String accountId;
                    if (existing == null) {
                      accountId = (await repo.create(
                        name: name,
                        type: type,
                        color: color,
                        balanceMinor: signed,
                        includeInTotal: include,
                        statementDay: card.statementDay,
                        dueDay: card.dueDay,
                        creditLimitMinor: card.creditLimitMinor,
                        lastStatementMinor: card.lastStatementMinor,
                        lastStatementAt: card.lastStatementAt,
                      ))
                          .id;
                    } else {
                      accountId = existing.id;
                      await repo.update(AccountsCompanion(
                        id: Value(existing.id),
                        name: Value(name),
                        type: Value(type),
                        color: Value(color),
                        balanceMinor: Value(signed),
                        balanceAsOf: Value(signed == existing.balanceMinor ? existing.balanceAsOf : DateTime.now()),
                        includeInTotal: Value(include),
                        statementDay: Value(card.statementDay),
                        dueDay: Value(card.dueDay),
                        creditLimitMinor: Value(card.creditLimitMinor),
                        lastStatementMinor: Value(card.lastStatementMinor),
                        lastStatementAt: Value(card.lastStatementAt),
                      ));
                    }
                    // A card with a due date gets a due reminder with alerts:
                    // the same permission sheets as any reminder (decision 22).
                    final hasDueReminder = type == 'card' &&
                        cardDue(today: startOfDay(DateTime.now()), statementDay: card.statementDay, dueDay: card.dueDay, lastStatementMinor: card.lastStatementMinor, lastStatementAt: card.lastStatementAt) != null;
                    if (hasDueReminder && sheetContext.mounted) await askReminderPermissionsIfNeeded(sheetContext);
                    await syncCardReminderSafely(() => ref.read(cardReminderSyncProvider).syncAccountById(accountId));
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

typedef CardFormFields = ({int? statementDay, int? dueDay, int? creditLimitMinor, int? lastStatementMinor, DateTime? lastStatementAt});

/// The card columns to save from the account sheet; all null for other types.
CardFormFields cardFieldsFromForm({
  required bool isCard,
  required int? statementDay,
  required int? dueDay,
  required String limitText,
  required String lastStatementText,
  Account? existing,
  DateTime? now,
}) {
  if (!isCard) return (statementDay: null, dueDay: null, creditLimitMinor: null, lastStatementMinor: null, lastStatementAt: null);
  final lastStatementMinor = parseAmountToMinor(lastStatementText);
  return (
    statementDay: statementDay,
    dueDay: dueDay,
    creditLimitMinor: parseAmountToMinor(limitText),
    lastStatementMinor: lastStatementMinor,
    lastStatementAt: lastStatementDateAfterEdit(
      today: now ?? DateTime.now(),
      statementDay: statementDay,
      newAmountMinor: lastStatementMinor,
      previousAmountMinor: existing?.lastStatementMinor,
      previousAt: existing?.lastStatementAt,
    ),
  );
}

/// Statement and due day pickers, credit limit and last statement amount.
class _CardFields extends StatelessWidget {
  const _CardFields({
    required this.statementDay,
    required this.dueDay,
    required this.limitController,
    required this.lastStatementController,
    required this.statementError,
    required this.onStatementChanged,
    required this.onStatementDay,
    required this.onDueDay,
  });
  final int? statementDay;
  final int? dueDay;
  final TextEditingController limitController;
  final TextEditingController lastStatementController;
  final String? statementError;
  final VoidCallback onStatementChanged;
  final ValueChanged<int?> onStatementDay;
  final ValueChanged<int?> onDueDay;

  static final List<int> _days = List.generate(31, (index) => index + 1);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget dayPicker({required Key key, required String label, required int? value, required ValueChanged<int?> onChanged}) => DropdownButtonFormField<int?>(
          key: key,
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            DropdownMenuItem<int?>(value: null, child: Text(l10n.cardDayNotSet)),
            for (final day in _days) DropdownMenuItem<int?>(value: day, child: Text('$day')),
          ],
          onChanged: onChanged,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: dayPicker(key: const ValueKey('account.statementDay'), label: l10n.cardStatementDay, value: statementDay, onChanged: onStatementDay)),
            const SizedBox(width: 12),
            Expanded(child: dayPicker(key: const ValueKey('account.dueDay'), label: l10n.cardDueDay, value: dueDay, onChanged: onDueDay)),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('account.creditLimit'),
          controller: limitController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: amountInputFormatters,
          decoration: InputDecoration(labelText: l10n.cardCreditLimit),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('account.lastStatement'),
          controller: lastStatementController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: amountInputFormatters,
          onChanged: (_) => onStatementChanged(),
          decoration: InputDecoration(labelText: l10n.cardLastStatementAmount, errorText: statementError, errorMaxLines: 3),
        ),
        const SizedBox(height: 6),
        Text(l10n.cardDetailsHint, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

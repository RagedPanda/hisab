import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../data/repositories/udhaar_repository.dart';
import '../../domain/udhaar/udhaar.dart';
import '../../l10n/l10n.dart';
import 'person_dialog.dart';
import 'udhaar_labels.dart';
import 'udhaar_providers.dart';
import 'udhaar_reminder_action.dart';
import 'udhaar_routes.dart';

/// One person's udhaar: what they owe me or I owe them, a WhatsApp reminder
/// when they owe me, buttons to add more, and every entry with the balance
/// after it.
class PersonUdhaarScreen extends ConsumerWidget {
  const PersonUdhaarScreen({super.key, required this.personId});
  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final person = ref.watch(personProvider(personId)).value;
    final entries = ref.watch(personUdhaarEntriesProvider(personId)).value ?? const <Entry>[];
    final accounts = {for (final account in ref.watch(accountsProvider).value ?? const <Account>[]) account.id: account.name};
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final theme = Theme.of(context);
    final name = person?.name ?? '';
    final lines = [for (final entry in entries) ?udhaarLineOf(entry)];
    final after = balancesAfter(lines);
    final balance = after.firstOrNull ?? 0;
    final repayment = repaymentKindFor(balance);
    final since = outstandingSince(lines);
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          if (person != null)
            IconButton(
              key: const Key('udhaar.editPerson'),
              tooltip: l10n.udhaarEditPerson,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editPerson(context, ref, person),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              udhaarBalanceSentence(l10n, name: name, balance: balance, format: moneyFormat),
              key: const Key('udhaar.balance'),
              style: theme.textTheme.headlineSmall?.copyWith(color: udhaarBalanceColor(balance), fontWeight: FontWeight.w700).tabular,
            ),
          ),
          if (person != null && balance > 0 && since != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.tonalIcon(
                  key: const Key('udhaar.remind'),
                  onPressed: () => sendUdhaarReminder(context, ref, person: person, balance: balance, since: since),
                  icon: const Icon(Icons.chat_outlined),
                  label: Text(l10n.udhaarRemind),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              _AddButton(buttonKey: const Key('udhaar.addLent'), label: l10n.udhaarKindLent, icon: udhaarKindIcon(UdhaarKind.lent), location: udhaarEntryLocation(personId: personId, kind: UdhaarKind.lent)),
              _AddButton(buttonKey: const Key('udhaar.addBorrowed'), label: l10n.udhaarKindBorrowed, icon: udhaarKindIcon(UdhaarKind.borrowed), location: udhaarEntryLocation(personId: personId, kind: UdhaarKind.borrowed)),
              if (repayment != null)
                _AddButton(
                  buttonKey: const Key('udhaar.addRepayment'),
                  label: l10n.udhaarRepayment,
                  icon: Icons.replay,
                  location: udhaarEntryLocation(personId: personId, kind: repayment, amountMinor: balance.abs()),
                ),
            ]),
          ),
          if (entries.isEmpty)
            Padding(padding: const EdgeInsets.all(16), child: Text(l10n.udhaarPersonEmpty(name), style: theme.textTheme.bodyMedium))
          else
            for (final (index, entry) in entries.indexed)
              _EntryRow(entry: entry, name: name, accountName: accounts[udhaarAccountOf(from: entry.accountId, to: entry.toAccountId)], balanceAfter: after[index]),
        ],
      ),
    );
  }

  Future<void> _editPerson(BuildContext context, WidgetRef ref, Person person) async {
    final fields = await showPersonDialog(context, title: context.l10n.udhaarEditPerson, name: person.name, phone: person.phone);
    if (fields == null) return;
    await ref.read(peopleRepositoryProvider).updatePerson(person.id, name: fields.name, phone: fields.phone);
    await ref.read(udhaarRepositoryProvider).renamePerson(person.id, fields.name);
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.buttonKey, required this.label, required this.icon, required this.location});
  final Key buttonKey;
  final String label;
  final IconData icon;
  final String location;

  @override
  Widget build(BuildContext context) =>
      OutlinedButton.icon(key: buttonKey, onPressed: () => context.push(location), icon: Icon(icon), label: Text(label));
}

/// One udhaar entry: what happened, when and on which account, its amount
/// and the balance it left.
class _EntryRow extends ConsumerWidget {
  const _EntryRow({required this.entry, required this.name, required this.accountName, required this.balanceAfter});
  final Entry entry;
  final String name;
  final String? accountName;
  final int balanceAfter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final kind = UdhaarKind.parse(entry.udhaarKind) ?? UdhaarKind.lent;
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final details = [formatShortDate(entry.occurredAt, locale: locale), ?accountName, if (entry.note.isNotEmpty) entry.note];
    final muted = theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return ListTile(
      key: ValueKey('udhaar.entry.${entry.id}'),
      leading: CircleAvatar(
        backgroundColor: (kind.isMoneyOut ? kExpenseColor : kIncomeColor).withValues(alpha: 0.14),
        child: Icon(udhaarKindIcon(kind), color: kind.isMoneyOut ? kExpenseColor : kIncomeColor),
      ),
      title: Text(udhaarEntryTitle(l10n, kind, name), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(details.join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(formatMinor(entry.amountMinor, format: moneyFormat), style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600).tabular),
          Text(l10n.udhaarBalanceAfter(formatMinor(balanceAfter, format: moneyFormat)), style: muted?.tabular),
        ],
      ),
      onTap: () => context.push(udhaarEntryLocation(id: entry.id)),
    );
  }
}

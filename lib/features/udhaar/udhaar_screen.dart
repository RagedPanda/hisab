import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../domain/udhaar/udhaar.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'person_dialog.dart';
import 'udhaar_labels.dart';
import 'udhaar_providers.dart';
import 'udhaar_reminder_action.dart';
import 'udhaar_routes.dart';

/// People and udhaar: everyone with money outstanding either way, largest
/// first, then everyone else on the People list.
class UdhaarScreen extends ConsumerWidget {
  const UdhaarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final people = ref.watch(peopleProvider).value ?? const <Person>[];
    final balances = ref.watch(udhaarBalancesProvider).value ?? const <String, int>{};
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final byId = {for (final person in people) person.id: person};
    final owing = [for (final id in outstandingPeople(balances)) ?byId[id]];
    final others = [for (final person in people) if ((balances[person.id] ?? 0) == 0) person];
    final totals = udhaarTotals(balances);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.udhaarTitle),
        actions: [
          IconButton(key: const Key('udhaar.upiId'), tooltip: l10n.udhaarMyUpiId, icon: const Icon(Icons.qr_code_2), onPressed: () => editMyUpiId(context, ref)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('udhaar.add'),
        onPressed: () => context.push(udhaarEntryLocation()),
        icon: const Icon(Icons.add),
        label: Text(l10n.udhaarAdd),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          if (owing.isEmpty)
            Padding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 8), child: Text(l10n.udhaarEmpty, style: theme.textTheme.bodyMedium))
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Wrap(spacing: 16, runSpacing: 4, children: [
                if (totals.owedToMe > 0)
                  Text(l10n.youGetAmount(formatMinor(totals.owedToMe, format: moneyFormat)), style: theme.textTheme.titleSmall?.copyWith(color: kIncomeColor).tabular),
                if (totals.iOwe > 0)
                  Text(l10n.youOweAmount(formatMinor(totals.iOwe, format: moneyFormat)), style: theme.textTheme.titleSmall?.copyWith(color: kExpenseColor).tabular),
              ]),
            ),
            for (final person in owing) UdhaarPersonTile(person: person, balance: balances[person.id] ?? 0),
          ],
          SectionHeader(l10n.udhaarOtherPeople),
          for (final person in others) UdhaarPersonTile(person: person, balance: 0),
          ListTile(
            key: const Key('udhaar.addPerson'),
            leading: const Icon(Icons.person_add_alt_1_outlined),
            title: Text(l10n.udhaarAddPerson),
            onTap: () async {
              final id = await addPersonFromDialog(context, ref);
              if (id != null && context.mounted) context.push(udhaarPersonLocation(id));
            },
          ),
        ],
      ),
    );
  }
}

/// Asks for a new person and saves them to People; returns their id, or
/// null when cancelled.
Future<String?> addPersonFromDialog(BuildContext context, WidgetRef ref) async {
  final fields = await showPersonDialog(context, title: context.l10n.udhaarAddPerson);
  if (fields == null) return null;
  return ref.read(peopleRepositoryProvider).addPerson(name: fields.name, phone: fields.phone);
}

/// One person and what they owe me or I owe them; opens their page.
class UdhaarPersonTile extends ConsumerWidget {
  const UdhaarPersonTile({super.key, required this.person, required this.balance});
  final Person person;
  final int balance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final amount = formatMinor(balance.abs(), format: ref.watch(homeMoneyFormatProvider));
    final status = balance > 0
        ? l10n.udhaarOwesYouShort(amount)
        : balance < 0
            ? l10n.udhaarYouOweShort(amount)
            : null;
    return ListTile(
      key: ValueKey('udhaar.person.${person.id}'),
      leading: CircleAvatar(child: Text(person.name.characters.firstOrNull?.toUpperCase() ?? '?')),
      title: Text(person.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: status == null
          ? const Icon(Icons.chevron_right)
          : Text(status, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: udhaarBalanceColor(balance), fontWeight: FontWeight.w600).tabular),
      onTap: () => context.push(udhaarPersonLocation(person.id)),
    );
  }
}

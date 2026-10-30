import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../domain/udhaar/udhaar.dart';
import '../../l10n/l10n.dart';
import '../dashboard/widgets/dashboard_card.dart';
import 'udhaar_providers.dart';
import 'udhaar_routes.dart';
import 'udhaar_screen.dart';

/// How many people the Home card lists above its "see all" row.
const int kUdhaarCardPeople = 3;

/// Home card: who owes me and whom I owe outside groups; hidden when every
/// udhaar is settled.
class UdhaarCard extends ConsumerWidget {
  const UdhaarCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(udhaarBalancesProvider).value ?? const <String, int>{};
    final people = {for (final person in ref.watch(peopleProvider).value ?? const <Person>[]) person.id: person};
    final owing = [for (final id in outstandingPeople(balances)) ?people[id]];
    if (owing.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final totals = udhaarTotals(balances);
    return DashboardSection(
      title: l10n.udhaarTitle,
      trailing: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
          if (totals.owedToMe > 0)
            Text(l10n.youGetAmount(formatMinor(totals.owedToMe, format: moneyFormat, showDecimals: false)), style: theme.textTheme.labelLarge?.copyWith(color: kIncomeColor).tabular),
          if (totals.iOwe > 0)
            Text(l10n.youOweAmount(formatMinor(totals.iOwe, format: moneyFormat, showDecimals: false)), style: theme.textTheme.labelLarge?.copyWith(color: kExpenseColor).tabular),
        ]),
      ),
      child: DashboardCard(
        key: const Key('dashboard.udhaarCard'),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (final person in owing.take(kUdhaarCardPeople)) UdhaarPersonTile(person: person, balance: balances[person.id] ?? 0),
            ListTile(
              key: const Key('dashboard.udhaarSeeAll'),
              title: Text(l10n.seeAll),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(kUdhaarLocation),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../../groups/net_badge.dart';
import '../../shell/widgets/common.dart';
import '../dashboard_keys.dart';
import '../dashboard_providers.dart';
import 'dashboard_card.dart';

/// Shared-expense groups and what is owed either way; hidden without groups.
class GroupsCard extends ConsumerWidget {
  const GroupsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(groupsOverviewProvider);
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return AsyncCard(
      value: overview,
      skeletonHeight: 120,
      builder: (data) {
        if (data.isEmpty) return const SizedBox.shrink();
        final net = data.owedToMe - data.iOwe;
        final totalText = net >= 0
            ? l10n.youGetAmount(formatMinor(data.owedToMe, format: moneyFormat, showDecimals: false))
            : l10n.youOweAmount(formatMinor(data.iOwe, format: moneyFormat, showDecimals: false));
        return DashboardSection(
          title: l10n.groups,
          trailing: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(totalText, style: theme.textTheme.labelLarge?.copyWith(color: net >= 0 ? kIncomeColor : kExpenseColor).tabular),
          ),
          child: DashboardCard(
            key: kGroupsCardKey,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final summary in data.shown)
                  ListTile(
                    leading: IconBadge(icon: summary.group.icon, color: kSeedColor.toARGB32()),
                    title: Text(summary.group.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(l10n.memberCount(summary.members.length)),
                    trailing: GroupNetBadge(net: summary.myNetMinor, moneyFormat: ref.watch(groupMoneyFormatProvider(summary.group.currencyLabel))),
                    onTap: () => context.push('/groups/${summary.group.id}'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

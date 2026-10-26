import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../l10n/l10n.dart';
import '../../shell/widgets/budget_row.dart';
import '../../shell/widgets/common.dart';
import '../dashboard_keys.dart';
import '../dashboard_providers.dart';
import 'dashboard_card.dart';

/// Up to four budgets with their progress, or a nudge to set one.
class BudgetsCard extends ConsumerWidget {
  const BudgetsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(budgetsOverviewProvider);
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final l10n = context.l10n;
    void openBudgets() => context.push('/budgets');
    return AsyncCard(
      value: overview,
      skeletonHeight: 160,
      builder: (data) {
        if (data.isEmpty) return const SizedBox.shrink();
        return DashboardSection(
          title: l10n.budgets,
          trailing: SectionAction(label: l10n.manage, onPressed: openBudgets),
          child: DashboardCard(
            key: kBudgetsCardKey,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final view in data.shown) BudgetRow(view: view, moneyFormat: moneyFormat, onTap: openBudgets),
                if (data.more > 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SectionAction(label: l10n.andMoreCount(data.more), onPressed: openBudgets),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

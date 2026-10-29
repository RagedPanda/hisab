import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/money.dart';
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
                _SafeToSpendLine(moneyFormat: moneyFormat),
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

/// "Safe to spend ₹Y/day" atop the budgets, only with an overall monthly
/// budget; at ₹0 it adds a short over-budget hint.
class _SafeToSpendLine extends ConsumerWidget {
  const _SafeToSpendLine({required this.moneyFormat});
  final MoneyFormat moneyFormat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safe = ref.watch(safeToSpendProvider).value;
    if (safe == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      key: kSafeToSpendKey,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Icon(Icons.savings_outlined, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          // Shrinks rather than ellipsises, so the amount is never cut off.
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.safeToSpendPerDay(formatMinor(safe.perDayMinor, format: moneyFormat, showDecimals: false)),
                maxLines: 1,
                style: theme.textTheme.labelLarge?.tabular,
              ),
            ),
          ),
          if (safe.isOver) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(999)),
              child: Text(l10n.safeToSpendOverBudget, maxLines: 1, style: theme.textTheme.labelMedium?.copyWith(color: scheme.onErrorContainer, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}

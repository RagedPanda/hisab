import 'package:flutter/material.dart';

import '../../../core/money.dart';
import '../../../core/theme.dart';
import '../../../domain/budget/budget_math.dart';
import '../../../l10n/category_names.dart';
import '../../../l10n/l10n.dart';
import '../../budgets/budget_views.dart';
import 'common.dart';

/// Colour of a budget bar by its semantic state, never by the category colour (P2-13).
Color budgetBandColor(BudgetBand band, ColorScheme scheme) => switch (band) {
      BudgetBand.onTrack => scheme.primary,
      BudgetBand.nearLimit => kAccentColor,
      BudgetBand.over => kExpenseColor,
    };

/// One budget with progress bar, percent used and what is left; shared by the
/// dashboard overview and the Budgets screen (P2-14).
class BudgetRow extends StatelessWidget {
  const BudgetRow({super.key, required this.view, required this.symbol, this.onTap, this.trailing});
  final BudgetView view;
  final String symbol;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final progress = view.progress;
    final barColor = budgetBandColor(progress.band, theme.colorScheme);
    final name = view.budget.categoryId == null ? l10n.overall : view.category?.displayName(context) ?? l10n.category;
    final limit = formatMinor(progress.limitMinor, symbol: symbol, showDecimals: false);
    final caption = progress.isOver
        ? l10n.budgetOverBy(formatMinor(-progress.remainingMinor, symbol: symbol, showDecimals: false), limit)
        : l10n.budgetLeftWithDays(formatMinor(progress.remainingMinor, symbol: symbol, showDecimals: false), limit, view.daysLeft);
    return ListTile(
      onTap: onTap,
      leading: IconBadge(icon: view.category?.icon ?? 'all_inclusive', color: view.category?.color ?? kSeedColor.toARGB32()),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.usedFraction.clamp(0, 1),
              color: barColor,
              backgroundColor: barColor.withValues(alpha: 0.15),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(caption, style: theme.textTheme.bodySmall?.tabular),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${progress.usedPercent}%', style: theme.textTheme.labelLarge?.copyWith(color: barColor).tabular),
          ?trailing,
        ],
      ),
    );
  }
}

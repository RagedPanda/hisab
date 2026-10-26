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
  const BudgetRow({super.key, required this.view, required this.moneyFormat, this.onTap, this.trailing});
  final BudgetView view;
  final MoneyFormat moneyFormat;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final progress = view.progress;
    final barColor = budgetBandColor(progress.band, theme.colorScheme);
    final name = view.budget.categoryId == null ? l10n.overall : view.category?.displayName(context) ?? l10n.category;
    final limit = formatMinor(progress.limitMinor, format: moneyFormat, showDecimals: false);
    final caption = progress.isOver
        ? l10n.budgetOverBy(formatMinor(-progress.remainingMinor, format: moneyFormat, showDecimals: false), limit)
        : l10n.budgetLeftWithDays(formatMinor(progress.remainingMinor, format: moneyFormat, showDecimals: false), limit, view.daysLeft);
    return ListTile(
      onTap: onTap,
      leading: IconBadge(icon: view.category?.icon ?? 'all_inclusive', color: view.category?.color ?? kSeedColor.toARGB32()),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          BudgetProgressBar(progress: progress),
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

/// Spend-so-far bar coloured by budget band, with a tick where spend would be
/// if it tracked the calendar exactly. Used by budget rows and projects.
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({super.key, required this.progress, this.height = 6});
  final BudgetProgress progress;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: progress.usedFraction.clamp(0, 1),
            color: budgetBandColor(progress.band, scheme),
            backgroundColor: scheme.surfaceContainerHighest,
            minHeight: height,
          ),
        ),
        // Where the bar would be if spend tracked the calendar exactly.
        if (progress.elapsedFraction < 1)
          Align(
            alignment: Alignment(-1 + 2 * progress.elapsedFraction, 0),
            child: Container(width: 1, height: height, color: scheme.outline),
          ),
      ],
    );
  }
}

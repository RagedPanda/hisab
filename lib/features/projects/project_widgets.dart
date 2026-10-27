import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../domain/budget/budget_math.dart';
import '../../domain/projects/project_math.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/budget_row.dart';

String projectStatusLabel(AppLocalizations l10n, ProjectStatus status) => switch (status) {
      ProjectStatus.active => l10n.projectStatusActive,
      ProjectStatus.completed => l10n.projectStatusCompleted,
      ProjectStatus.archived => l10n.projectStatusArchived,
    };

/// Small pill naming a project's status; active projects show none.
class ProjectStatusChip extends StatelessWidget {
  const ProjectStatusChip({super.key, required this.status});
  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      ProjectStatus.active => (scheme.primaryContainer, scheme.onPrimaryContainer),
      ProjectStatus.completed => (kIncomeColor.withValues(alpha: 0.14), kIncomeColor),
      ProjectStatus.archived => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Text(projectStatusLabel(context.l10n, status), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground, fontWeight: FontWeight.w600)),
    );
  }
}

/// Budget bar with "left" or "over" caption, or a plain "no budget" line.
class ProjectBudgetSummary extends StatelessWidget {
  const ProjectBudgetSummary({super.key, required this.budget, required this.moneyFormat, this.trailing});
  final BudgetProgress? budget;
  final MoneyFormat moneyFormat;

  /// Extra text after the caption, such as the entry count.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final captionStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant).tabular;
    final progress = budget;
    if (progress == null) {
      return Text([l10n.noBudgetSet, ?trailing].join(' · '), style: captionStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    final limit = formatMinor(progress.limitMinor, format: moneyFormat, showDecimals: false);
    final caption = progress.isOver
        ? l10n.budgetOverBy(formatMinor(-progress.remainingMinor, format: moneyFormat, showDecimals: false), limit)
        : l10n.leftOfBudget(formatMinor(progress.remainingMinor, format: moneyFormat, showDecimals: false), limit);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BudgetProgressBar(progress: progress),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: Text([caption, ?trailing].join(' · '), style: captionStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text('${progress.usedPercent}%', style: theme.textTheme.labelLarge?.copyWith(color: budgetBandColor(progress.band, theme.colorScheme)).tabular),
          ],
        ),
      ],
    );
  }
}

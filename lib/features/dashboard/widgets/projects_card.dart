import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../../shell/widgets/budget_row.dart';
import '../../shell/widgets/common.dart';
import '../dashboard_keys.dart';
import '../dashboard_providers.dart';
import 'dashboard_card.dart';

/// Active projects with what each has cost so far; hidden until there is one.
/// Tapping the card opens the Projects screen.
class ProjectsCard extends ConsumerWidget {
  const ProjectsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(projectsOverviewProvider);
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    void openProjects() => context.push('/projects');
    return AsyncCard(
      value: overview,
      skeletonHeight: 120,
      builder: (data) {
        if (data.isEmpty) return const SizedBox.shrink();
        return DashboardSection(
          title: l10n.projects,
          trailing: SectionAction(label: l10n.seeAll, onPressed: openProjects),
          child: DashboardCard(
            key: kProjectsCardKey,
            onTap: openProjects,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                for (final (index, view) in data.shown.indexed) ...[
                  if (index > 0) const SizedBox(height: 14),
                  Row(
                    children: [
                      IconBadge(icon: view.project.icon, color: view.project.color, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(view.project.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                                ),
                                Text(
                                  view.totals.budget == null
                                      ? formatMinor(view.totals.spentMinor, format: moneyFormat, showDecimals: false)
                                      : l10n.spentOfBudget(
                                          formatMinor(view.totals.spentMinor, format: moneyFormat, showDecimals: false),
                                          formatMinor(view.totals.budget!.limitMinor, format: moneyFormat, showDecimals: false, compact: true),
                                        ),
                                  style: theme.textTheme.labelLarge?.tabular,
                                ),
                              ],
                            ),
                            if (view.totals.budget != null) ...[
                              const SizedBox(height: 6),
                              BudgetProgressBar(progress: view.totals.budget!, height: 4),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                if (data.more > 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: SectionAction(label: l10n.andMoreCount(data.more), onPressed: openProjects),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

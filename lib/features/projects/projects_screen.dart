import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/repositories/projects_repository.dart';
import '../../domain/projects/project_math.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'project_widgets.dart';

/// Whether the projects list includes archived projects; off by default.
class _ShowArchivedNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

final _showArchivedProvider = NotifierProvider<_ShowArchivedNotifier, bool>(_ShowArchivedNotifier.new);

/// Every project as a card: icon, spend, budget bar and status, grouped
/// active, completed, then archived.
class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final views = ref.watch(projectViewsProvider);
    final showArchived = ref.watch(_showArchivedProvider);
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final all = views.value ?? const <ProjectView>[];
    final hasArchived = all.any((view) => view.status == ProjectStatus.archived);
    final visible = showArchived ? all : all.where((view) => view.status != ProjectStatus.archived).toList();
    void create() => context.push('/projects/new');

    return HomeFallbackPop(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.projects),
          actions: [
            if (hasArchived)
              IconButton(
                tooltip: showArchived ? l10n.hideArchived : l10n.showArchived,
                isSelected: showArchived,
                icon: const Icon(Icons.inventory_2_outlined),
                selectedIcon: const Icon(Icons.inventory_2),
                onPressed: () => ref.read(_showArchivedProvider.notifier).toggle(),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'add-project',
          onPressed: create,
          icon: const Icon(Icons.add),
          label: Text(l10n.newProject),
        ),
        body: !views.hasValue
            ? const SizedBox.shrink()
            : visible.isEmpty
                ? EmptyState(
                    icon: Icons.folder_outlined,
                    title: l10n.noProjectsTitle,
                    message: l10n.noProjectsBody,
                    action: FilledButton.tonal(onPressed: create, child: Text(l10n.startProject)),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    children: [
                      for (final (index, view) in visible.indexed) ...[
                        if (index == 0 || visible[index - 1].status != view.status)
                          SectionHeader(projectStatusLabel(l10n, view.status), padding: const EdgeInsets.fromLTRB(4, 16, 4, 8)),
                        ProjectCard(view: view, symbol: symbol),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.view, required this.symbol});
  final ProjectView view;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final project = view.project;
    final totals = view.totals;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/projects/${project.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBadge(icon: project.icon, color: project.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Text(
                          l10n.spentAmount(formatMinor(totals.spentMinor, symbol: symbol, showDecimals: false)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.tabular,
                        ),
                      ],
                    ),
                  ),
                  if (view.status != ProjectStatus.active) ProjectStatusChip(status: view.status),
                ],
              ),
              const SizedBox(height: 12),
              ProjectBudgetSummary(budget: totals.budget, symbol: symbol, trailing: l10n.entryCountLabel(totals.entryCount)),
            ],
          ),
        ),
      ),
    );
  }
}

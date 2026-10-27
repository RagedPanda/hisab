import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../data/repositories/entries_repository.dart';
import '../../data/repositories/projects_repository.dart';
import '../../domain/categories/category_filter.dart';
import '../../domain/projects/project_math.dart';
import '../../domain/projects/project_metrics.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../dashboard/dashboard_providers.dart';
import '../dashboard/widgets/category_donut.dart';
import '../dashboard/widgets/trend_card.dart';
import '../reminders/project_reminders_section.dart';
import '../shell/widgets/common.dart';
import 'project_fields_section.dart';
import 'project_providers.dart';
import 'project_widgets.dart';

/// One project: spend against budget, where it went by category and month,
/// and its entries. Tapping a donut slice narrows the entry list.
class ProjectDetailScreen extends ConsumerStatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewValue = ref.watch(projectViewProvider(widget.projectId));
    final entries = ref.watch(projectEntriesProvider(widget.projectId)).value ?? const <EntryDetails>[];
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final settings = ref.watch(settingsProvider);
    final fields = ref.watch(projectFieldsProvider(widget.projectId)).value ?? const <ProjectField>[];
    final metrics = ref.watch(projectMetricsProvider(widget.projectId)).value ?? const ProjectMetrics();
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    if (!viewValue.hasValue) return Scaffold(appBar: AppBar());
    final view = viewValue.value;
    if (view == null) {
      return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.folder_off_outlined, title: l10n.projectNotFound));
    }
    final project = view.project;
    final totals = view.totals;
    final breakdown = buildCategoryBreakdown(totals.byCategory, categories);
    final months = projectMonths(byMonth: totals.byMonth, startDate: project.startDate, endDate: project.endDate, now: DateTime.now(), startDay: settings.monthStartDay);
    final bars = projectMonthTotals(totals.byMonth, months, startDay: settings.monthStartDay);
    final selected = _selectedCategoryId;
    final shownEntries = selected == null
        ? entries
        : entries.where((details) => matchesCategoryFilter(selectedId: selected, categoryId: details.category?.id, parentId: details.category?.parentId)).toList();

    return HomeFallbackPop(
      child: Scaffold(
        appBar: AppBar(
          title: Text(project.name),
          actions: [
            IconButton(tooltip: l10n.edit, icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/projects/${project.id}/edit')),
            _ProjectMenu(view: view),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'add-project-entry',
          onPressed: () => context.push(Uri(path: '/entry', queryParameters: {'project': project.id}).toString()),
          icon: const Icon(Icons.add),
          label: Text(l10n.addEntry),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          children: [
            _ProjectHero(view: view, moneyFormat: moneyFormat),
            if (fields.isNotEmpty) ProjectMetricsSection(metrics: metrics, fields: fields, moneyFormat: moneyFormat),
            if (totals.spentMinor > 0) ...[
              SectionHeader(l10n.spendingByCategory, padding: const EdgeInsets.fromLTRB(4, 20, 4, 8)),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CategoryDonut(
                    data: breakdown,
                    selectedId: selected,
                    moneyFormat: moneyFormat,
                    totalCaption: l10n.allTime,
                    onSliceTap: (share) => setState(() => _selectedCategoryId = selected == share.categoryId ? null : share.categoryId),
                  ),
                ),
              ),
              if (bars.length > 1) ...[
                SectionHeader(l10n.spendingByMonth, padding: const EdgeInsets.fromLTRB(4, 20, 4, 8)),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(height: kTrendChartHeight, child: MonthlyBars(months: bars, moneyFormat: moneyFormat)),
                  ),
                ),
              ],
            ],
            ProjectRemindersSection(projectId: project.id),
            ProjectFieldsSection(projectId: project.id, fields: fields),
            SectionHeader(
              l10n.entries,
              padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
              trailing: selected == null
                  ? null
                  : InputChip(
                      label: Text(breakdown.categoriesById[selected]?.displayName(context) ?? l10n.uncategorised),
                      onDeleted: () => setState(() => _selectedCategoryId = null),
                    ),
            ),
            if (shownEntries.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.noProjectEntriesTitle, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(l10n.noProjectEntriesBody, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final details in shownEntries)
                      EntryTile(details: details, showDate: true, onTap: () => context.push('/entry?id=${details.entry.id}')),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProjectHero extends StatelessWidget {
  const _ProjectHero({required this.view, required this.moneyFormat});
  final ProjectView view;
  final MoneyFormat moneyFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final project = view.project;
    final totals = view.totals;
    final dates = _datesLabel(l10n, project, locale);
    return Card(
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
                  child: Text(
                    dates ?? l10n.spentSoFar,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                ProjectStatusChip(status: view.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              formatMinor(totals.spentMinor, format: moneyFormat, showDecimals: false),
              style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700).tabular,
            ),
            const SizedBox(height: 12),
            ProjectBudgetSummary(budget: totals.budget, moneyFormat: moneyFormat, trailing: l10n.entryCountLabel(totals.entryCount)),
            if (totals.incomeMinor > 0) ...[
              const SizedBox(height: 6),
              Text(l10n.receivedAmount(formatMinor(totals.incomeMinor, format: moneyFormat, showDecimals: false)), style: theme.textTheme.bodySmall?.copyWith(color: kIncomeColor).tabular),
            ],
            if (project.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(project.notes, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  String? _datesLabel(AppLocalizations l10n, Project project, String locale) {
    final start = project.startDate == null ? null : formatShortDate(project.startDate!, locale: locale);
    final end = project.endDate == null ? null : formatShortDate(project.endDate!, locale: locale);
    if (start != null && end != null) return l10n.projectDates(start, end);
    if (start != null) return l10n.sinceDate(start);
    if (end != null) return l10n.untilDate(end);
    return null;
  }
}

/// Complete or reopen, archive, delete; each with an Undo on the snackbar.
class _ProjectMenu extends ConsumerWidget {
  const _ProjectMenu({required this.view});
  final ProjectView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final status = view.status;
    final project = view.project;
    final repo = ref.read(projectsRepositoryProvider);

    Future<void> changeStatus(ProjectStatus next, String message) async {
      await repo.setStatus(project.id, next);
      if (!context.mounted) return;
      showUndoSnackBar(ScaffoldMessenger.of(context), message: message, undoLabel: l10n.undo, onUndo: () => repo.setStatus(project.id, status));
    }

    Future<void> delete() async {
      final confirmed = await confirmDialog(context, title: l10n.deleteNamed(project.name), message: l10n.deleteProjectBody, confirmLabel: l10n.delete);
      if (!confirmed || !context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      await repo.delete(project.id);
      if (context.mounted) context.pop();
      showUndoSnackBar(messenger, message: l10n.projectDeleted, undoLabel: l10n.undo, onUndo: () => repo.restore(project.id));
    }

    return PopupMenuButton<VoidCallback>(
      onSelected: (action) => action(),
      itemBuilder: (_) => [
        if (status == ProjectStatus.active)
          PopupMenuItem(value: () => changeStatus(ProjectStatus.completed, l10n.projectMarkedCompleted), child: Text(l10n.markCompleted))
        else
          PopupMenuItem(value: () => changeStatus(ProjectStatus.active, l10n.projectReopened), child: Text(l10n.reopenProject)),
        if (status != ProjectStatus.archived)
          PopupMenuItem(value: () => changeStatus(ProjectStatus.archived, l10n.projectArchivedSnack), child: Text(l10n.archiveProject)),
        PopupMenuItem(value: delete, child: Text(l10n.deleteProject)),
      ],
    );
  }
}

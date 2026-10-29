import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../domain/subscriptions/subscription_costs.dart';
import '../../domain/subscriptions/subscription_templates.dart';
import '../../l10n/l10n.dart';
import '../dashboard/widgets/dashboard_card.dart';
import '../shell/widgets/common.dart';
import 'subscription_labels.dart';
import 'subscription_providers.dart';

/// Recurring rules flagged as subscriptions: what they cost per month and
/// per year, when each renews, and which are paused or cancelled.
class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  SubscriptionSort _sort = SubscriptionSort.costHighToLow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final views = ref.watch(subscriptionViewsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subscriptions),
        actions: [
          PopupMenuButton<SubscriptionSort>(
            icon: const Icon(Icons.sort),
            tooltip: l10n.subscriptionSort,
            initialValue: _sort,
            onSelected: (sort) => setState(() => _sort = sort),
            itemBuilder: (_) => [
              for (final sort in SubscriptionSort.values) PopupMenuItem(value: sort, child: Text(subscriptionSortLabel(l10n, sort))),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.subscriptionAdd),
      ),
      body: views.when(
        loading: () => const LoadingPlaceholder(),
        error: (error, _) => Center(child: Text('$error')),
        data: (views) {
          if (views.isEmpty) {
            return EmptyState(icon: Icons.autorenew, title: l10n.subscriptionsEmptyTitle, message: l10n.subscriptionsEmptyBody);
          }
          final byId = {for (final view in views) view.rule.id: view};
          final items = [for (final view in views) subscriptionItemOf(view, locale)];
          final sorted = sortSubscriptions(items, _sort);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _TotalsCard(totals: subscriptionTotals(items)),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  for (final item in sorted) _SubscriptionTile(view: byId[item.id]!, item: item, onTap: () => _showActions(context, byId[item.id]!, item)),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final key = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _TemplateSheet(),
    );
    if (key == null || !context.mounted) return;
    context.push(key.isEmpty ? '/subscriptions/new' : '/subscriptions/new?template=$key');
  }

  Future<void> _showActions(BuildContext context, RecurringRuleView view, SubscriptionItem item) async {
    final l10n = context.l10n;
    final repo = ref.read(recurringRepositoryProvider);
    final monthStartDay = ref.read(settingsProvider).monthStartDay;
    final messenger = ScaffoldMessenger.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: Text(item.name, style: Theme.of(sheetContext).textTheme.titleMedium)),
          ListTile(leading: const Icon(Icons.edit_outlined), title: Text(l10n.edit), onTap: () => Navigator.pop(sheetContext, 'edit')),
          if (item.status == SubscriptionStatus.active)
            ListTile(leading: const Icon(Icons.pause_circle_outline), title: Text(l10n.subscriptionPause), onTap: () => Navigator.pop(sheetContext, 'pause')),
          if (item.status == SubscriptionStatus.paused)
            ListTile(leading: const Icon(Icons.play_circle_outline), title: Text(l10n.subscriptionResume), onTap: () => Navigator.pop(sheetContext, 'resume')),
          if (item.status != SubscriptionStatus.cancelled)
            ListTile(leading: const Icon(Icons.block), title: Text(l10n.subscriptionMarkCancelled), onTap: () => Navigator.pop(sheetContext, 'cancel')),
          ListTile(leading: const Icon(Icons.delete_outline), title: Text(l10n.delete), onTap: () => Navigator.pop(sheetContext, 'delete')),
        ]),
      ),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case 'edit':
        context.push('/subscriptions/${item.id}/edit');
      case 'pause':
        await repo.setPaused(item.id, true, now: DateTime.now(), monthStartDay: monthStartDay);
      case 'resume':
        await repo.setPaused(item.id, false, now: DateTime.now(), monthStartDay: monthStartDay);
      case 'cancel':
        final confirmed = await confirmDialog(context, title: l10n.subscriptionCancelConfirm(item.name), message: l10n.subscriptionCancelConfirmBody, confirmLabel: l10n.subscriptionMarkCancelled);
        if (confirmed) await repo.setStatus(item.id, RecurringStatus.ended);
      case 'delete':
        await repo.delete(item.id);
        showUndoSnackBar(messenger, message: l10n.subscriptionDeleted, undoLabel: l10n.undo, onUndo: () => repo.restore(item.id));
    }
  }
}

class _TotalsCard extends ConsumerWidget {
  const _TotalsCard({required this.totals});
  final ({int monthlyMinor, int yearlyMinor, int activeCount}) totals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    Widget column(String label, int minor) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(formatMinor(minor, format: moneyFormat, showDecimals: false), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700).tabular),
            ),
          ]),
        );
    return DashboardCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [column(l10n.subscriptionsMonthlyTotal, totals.monthlyMinor), const SizedBox(width: 16), column(l10n.subscriptionsYearlyTotal, totals.yearlyMinor)]),
        const SizedBox(height: 8),
        Text(l10n.subscriptionsActiveCount(totals.activeCount), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

class _SubscriptionTile extends ConsumerWidget {
  const _SubscriptionTile({required this.view, required this.item, required this.onTap});
  final RecurringRuleView view;
  final SubscriptionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final locale = Localizations.localeOf(context).toString();
    final price = '${formatMinor(item.amountMinor, format: moneyFormat)} · ${subscriptionCycleLabel(l10n, item.frequency, item.interval)}';
    final renewal = nextRenewal(item);
    final category = view.category;
    final String? statusText = switch (item.status) {
      SubscriptionStatus.paused => l10n.subscriptionPaused,
      SubscriptionStatus.cancelled => l10n.subscriptionCancelled,
      SubscriptionStatus.active => null,
    };
    final muted = theme.colorScheme.onSurfaceVariant;
    return Opacity(
      opacity: item.countsTowardTotals ? 1 : 0.6,
      child: ListTile(
        onTap: onTap,
        leading: IconBadge(icon: category?.icon, color: category?.color ?? theme.colorScheme.primary.toARGB32()),
        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(price, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (renewal != null)
            Text(subscriptionRenewalLabel(l10n, renewal, DateTime.now(), locale: locale),
                style: theme.textTheme.bodySmall?.copyWith(color: daysUntilRenewal(renewal, DateTime.now()) < 0 ? theme.colorScheme.error : muted)),
        ]),
        trailing: statusText != null
            ? _StatusMarker(statusText)
            : Text(l10n.subscriptionPerMonth(formatMinor(itemMonthlyMinor(item), format: moneyFormat, showDecimals: false)),
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600).tabular),
      ),
    );
  }
}

class _StatusMarker extends StatelessWidget {
  const _StatusMarker(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
    );
  }
}

/// Quick-add list: common Indian subscriptions, then "Something else".
/// Pops the template key, or '' for a blank form.
class _TemplateSheet extends StatelessWidget {
  const _TemplateSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, controller) => ListView(
        controller: controller,
        children: [
          SectionHeader(l10n.subscriptionPickService, padding: const EdgeInsets.fromLTRB(16, 0, 16, 8)),
          for (final template in subscriptionTemplates)
            ListTile(
              title: Text(subscriptionTemplateName(l10n, template)),
              subtitle: Text(subscriptionCycleLabel(l10n, template.frequency, template.interval)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, template.key),
            ),
          ListTile(leading: const Icon(Icons.add), title: Text(l10n.subscriptionCustom), onTap: () => Navigator.pop(context, '')),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

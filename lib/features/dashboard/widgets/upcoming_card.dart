import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../domain/upcoming/upcoming_items.dart';
import '../../../l10n/l10n.dart';
import '../../shell/widgets/common.dart';
import '../../upcoming/upcoming_actions.dart';
import '../../upcoming/upcoming_providers.dart';
import '../../upcoming/upcoming_routes.dart';
import '../../upcoming/widgets/upcoming_item_tile.dart';
import '../dashboard_keys.dart';
import 'dashboard_card.dart';

/// Recurring bills, reminders and card dues for the next 7 or 30 days, with
/// anything overdue on top; tapping a row opens its source.
class UpcomingCard extends ConsumerWidget {
  const UpcomingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(upcomingOverviewProvider);
    final l10n = context.l10n;
    void openCalendar() => context.push(kUpcomingCalendarRoute);
    return AsyncCard(
      value: overview,
      skeletonHeight: 120,
      builder: (data) {
        if (data.isEmpty) return const SizedBox.shrink();
        return DashboardSection(
        title: l10n.upcoming,
        trailing: IconButton(
          key: const ValueKey('upcoming.calendar'),
          tooltip: l10n.upcomingCalendarOpen,
          onPressed: openCalendar,
          icon: const Icon(Icons.calendar_month_outlined),
        ),
        child: DashboardCard(
          key: kUpcomingCardKey,
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _UpcomingHeader(overview: data),
              ),
              const SizedBox(height: 4),
              for (final item in data.shown)
                UpcomingItemTile(
                  key: ValueKey('upcoming.${item.source.name}.${item.sourceId}.${item.dueAt.millisecondsSinceEpoch}'),
                  item: item,
                  onTap: () => openUpcomingItem(context, ref, item),
                ),
              if (data.more > 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SectionAction(label: l10n.upcomingShowAll(data.more), onPressed: openCalendar),
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

/// The 7 / 30 day toggle plus the overdue count and amount to pay.
class _UpcomingHeader extends ConsumerWidget {
  const _UpcomingHeader({required this.overview});
  final UpcomingOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final summary = overview.summary;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<UpcomingWindow>(
          key: const ValueKey('upcoming.window'),
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: [
            for (final window in UpcomingWindow.values)
              ButtonSegment(
                value: window,
                label: Text(l10n.upcomingWindowDays(window.days), key: ValueKey('upcoming.window.${window.name}')),
              ),
          ],
          selected: {overview.window},
          onSelectionChanged: (selection) => ref.read(upcomingWindowProvider.notifier).select(selection.first),
        ),
        if (summary.overdueCount > 0)
          Text(
            l10n.upcomingOverdueCount(summary.overdueCount),
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w700),
          ),
        if (summary.dueOutMinor > 0) Text(l10n.upcomingDueTotal(formatMinor(summary.dueOutMinor, format: moneyFormat)), style: captionStyle(context)),
      ],
    );
  }
}


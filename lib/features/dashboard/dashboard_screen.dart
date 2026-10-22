import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'widgets/accounts_card.dart';
import 'widgets/budgets_card.dart';
import 'widgets/category_donut.dart';
import 'widgets/dashboard_card.dart';
import 'widgets/groups_card.dart';
import 'widgets/hero_card.dart';
import 'widgets/projects_card.dart';
import 'widgets/recent_card.dart';
import 'widgets/trend_card.dart';
import 'widgets/upcoming_card.dart';

export 'dashboard_keys.dart';

/// Home tab: one sliver per card, in the order the spec fixes, each card
/// reading its own combined provider so the composition stays thin.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pending = ref.watch(pendingSmsProvider).value ?? const [];
    final gutter = dashboardGutter(MediaQuery.sizeOf(context).width);
    final cards = <Widget>[
      if (pending.isNotEmpty) _PendingSmsBanner(count: pending.length),
      const HeroCard(),
      const TrendCard(),
      const CategoryDonutCard(),
      const BudgetsCard(),
      const ProjectsCard(),
      const UpcomingCard(),
      const AccountsCard(),
      const GroupsCard(),
      const RecentCard(),
    ];
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(l10n.appName),
            actions: [
              if (pending.isNotEmpty)
                IconButton(
                  tooltip: l10n.smsToReview(pending.length),
                  onPressed: () => context.push('/sms/review'),
                  icon: Badge(label: Text('${pending.length}'), child: const Icon(Icons.sms_outlined)),
                ),
              const MonthSwitcher(),
            ],
          ),
          for (final card in cards)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              sliver: SliverToBoxAdapter(child: card),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
        ],
      ),
    );
  }
}

/// Compact row for bank SMS waiting in the review queue, above the hero so
/// it is never missed. Opens the queue.
class _PendingSmsBanner extends StatelessWidget {
  const _PendingSmsBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DashboardSection(
      child: Card(
        color: theme.colorScheme.secondaryContainer,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(Icons.sms_outlined, color: theme.colorScheme.onSecondaryContainer),
          title: Text(context.l10n.smsToReview(count), style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
          trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSecondaryContainer),
          onTap: () => context.push('/sms/review'),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../l10n/l10n.dart';
import '../recurring/recurring_list_model.dart';
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
    final recurringWaiting = ref.watch(recurringWaitingCountProvider);
    final gutter = dashboardGutter(MediaQuery.sizeOf(context).width);
    final cards = <Widget>[
      if (pending.isNotEmpty) _ActionBanner(icon: Icons.sms_outlined, label: l10n.smsToReview(pending.length), route: '/sms'),
      if (recurringWaiting > 0) _ActionBanner(key: const ValueKey('dashboard.recurringBanner'), icon: Icons.repeat, label: l10n.recurringToConfirm(recurringWaiting), route: '/recurring'),
      const HeroCard(),
      const UpcomingCard(),
      const TrendCard(),
      const CategoryDonutCard(),
      const BudgetsCard(),
      const ProjectsCard(),
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
                  onPressed: () => context.push('/sms'),
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

/// Something waiting for the person (bank SMS to review, recurring entries
/// to confirm), above the hero so it is never missed.
class _ActionBanner extends StatelessWidget {
  const _ActionBanner({super.key, required this.icon, required this.label, required this.route});
  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DashboardSection(
      child: Card(
        color: theme.colorScheme.secondaryContainer,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon, color: theme.colorScheme.onSecondaryContainer),
          title: Text(label, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
          trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSecondaryContainer),
          onTap: () => context.push(route),
        ),
      ),
    );
  }
}

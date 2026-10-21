import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../dashboard_keys.dart';
import '../dashboard_providers.dart';
import 'dashboard_card.dart';

/// Reminders and bills due soon. The data model arrives in phase 3; until
/// then the slot exists, keyed, and renders nothing because there are no
/// reminders at all.
class UpcomingCard extends ConsumerWidget {
  const UpcomingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(upcomingOverviewProvider);
    final l10n = context.l10n;
    return AsyncCard(
      value: overview,
      skeletonHeight: 72,
      builder: (data) {
        if (!data.hasReminders) return const SizedBox.shrink(key: kUpcomingCardKey);
        return DashboardSection(
          title: l10n.upcoming,
          child: DashboardCard(
            key: kUpcomingCardKey,
            child: Row(
              children: [
                Icon(Icons.event_available_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.upcomingEmpty, style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/category_names.dart';
import '../../../l10n/l10n.dart';
import '../../shell/widgets/common.dart';
import '../dashboard_keys.dart';
import '../dashboard_providers.dart';
import 'dashboard_card.dart';

/// The latest entries of the month, narrowed to the donut's selected category.
class RecentCard extends ConsumerWidget {
  const RecentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentEntriesProvider);
    final l10n = context.l10n;
    return AsyncCard(
      value: recent,
      skeletonHeight: 180,
      builder: (data) => DashboardSection(
        title: l10n.recent,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data.filter != null)
              InputChip(
                label: Text(data.filter!.displayName(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                onDeleted: () => ref.read(selectedDashboardCategoryProvider.notifier).clear(),
                visualDensity: VisualDensity.compact,
              ),
            SectionAction(label: l10n.seeAll, onPressed: () => context.go('/transactions')),
          ],
        ),
        child: data.entries.isEmpty
            ? DashboardCard(
                key: kRecentCardKey,
                padding: EdgeInsets.zero,
                child: data.hasEntriesInWindow
                    ? EmptyState(icon: Icons.receipt_long_outlined, title: l10n.noEntriesThisMonthTitle, message: l10n.noEntriesThisMonthBody)
                    : EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: l10n.noEntriesYetTitle,
                        message: l10n.noEntriesYetBody,
                        action: FilledButton.tonal(onPressed: () => context.push('/entry'), child: Text(l10n.addEntry)),
                      ),
              )
            : DashboardCard(
                key: kRecentCardKey,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (final details in data.entries)
                      EntryTile(details: details, showDate: true, onTap: () => context.push('/entry?id=${details.entry.id}')),
                  ],
                ),
              ),
      ),
    );
  }
}

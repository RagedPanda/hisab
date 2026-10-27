import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../data/repositories/groups_repository.dart';
import '../../core/settings.dart';
import '../../domain/split/group_net.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'group_form.dart';
import 'net_badge.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summaries = ref.watch(groupSummariesProvider);
    final settings = ref.watch(settingsProvider);
    final deviceLocale = ref.watch(deviceLocaleProvider);
    final appSymbol = settings.currencySymbol;
    final list = summaries.value ?? const <GroupSummary>[];
    final totals = groupTotalsByCurrency(list, appSymbol: appSymbol);
    String sideText(bool owedToMe) => [
          for (final amount in summarySideAmounts(totals, owedToMe: owedToMe))
            _unbreakable(formatMinor(amount.minor, format: groupMoneyFormatFor(amount.symbol, settings, deviceLocale))),
        ].join(l10n.groupsTotalsSeparator);
    final active = [for (final summary in list) if (summary.group.archivedAt == null) summary];
    final archived = [for (final summary in list) if (summary.group.archivedAt != null) summary];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.groups), actions: [
        IconButton(tooltip: l10n.activityTitle, icon: const Icon(Icons.history), onPressed: () => context.push('/activity')),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-group',
        onPressed: () => showGroupForm(context, ref),
        icon: const Icon(Icons.group_add_outlined),
        label: Text(l10n.newGroup),
      ),
      body: !summaries.hasValue
          ? const SizedBox.shrink()
          : list.isEmpty
          ? EmptyState(
              icon: Icons.groups_outlined,
              title: l10n.noGroupsTitle,
              message: l10n.noGroupsBody,
              action: FilledButton.tonal(onPressed: () => showGroupForm(context, ref), child: Text(l10n.startGroup)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: _Total(label: l10n.youAreOwed, value: sideText(true), color: kIncomeColor)),
                      Expanded(child: _Total(label: l10n.youOwe, value: sideText(false), color: kExpenseColor)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                for (final summary in active) _GroupTile(summary: summary),
                if (archived.isNotEmpty)
                  Theme(
                    // No divider lines around the expansion tile, to match the cards.
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: const PageStorageKey('archived-groups'),
                      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                      childrenPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.archive_outlined),
                      title: Text(l10n.groupArchivedSection(archived.length)),
                      children: [for (final summary in archived) _GroupTile(summary: summary)],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Keeps "AED 1,400" on one line, so a narrow summary wraps only between
/// currencies.
String _unbreakable(String amount) => amount.replaceAll(' ', '\u00A0');

class _GroupTile extends ConsumerWidget {
  const _GroupTile({required this.summary});
  final GroupSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final moneyFormat = ref.watch(groupMoneyFormatProvider(summary.group.currencyLabel));
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: IconBadge(icon: summary.group.icon, color: 0xFF0F6E6B),
        title: Text(summary.group.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(l10n.groupSubtitle(summary.members.length, formatMinor(summary.totalSpentMinor, format: moneyFormat, showDecimals: false, compact: true)), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: GroupNetBadge(net: summary.myNetMinor, moneyFormat: moneyFormat),
        onTap: () => context.push('/groups/${summary.group.id}'),
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      );
}

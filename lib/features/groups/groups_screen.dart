import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../data/repositories/groups_repository.dart';
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
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final list = summaries.value ?? const <GroupSummary>[];
    final totals = groupNetTotals(list.map((summary) => summary.myNetMinor));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.groups)),
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
                    child: Row(children: [
                      Expanded(child: _Total(label: l10n.youAreOwed, value: formatMinor(totals.owedToMe, symbol: symbol), color: kIncomeColor)),
                      Expanded(child: _Total(label: l10n.youOwe, value: formatMinor(totals.iOwe, symbol: symbol), color: kExpenseColor)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                for (final summary in list)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: IconBadge(icon: summary.group.icon, color: 0xFF0F6E6B),
                      title: Text(summary.group.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(l10n.groupSubtitle(summary.members.length, formatMinor(summary.totalSpentMinor, symbol: symbol, showDecimals: false, compact: true)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: GroupNetBadge(net: summary.myNetMinor, symbol: symbol),
                      onTap: () => context.push('/groups/${summary.group.id}'),
                    ),
                  ),
              ],
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

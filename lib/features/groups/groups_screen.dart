import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/repositories/groups_repository.dart';
import '../shell/widgets/common.dart';
import 'group_form.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(groupSummariesProvider);
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final list = summaries.value ?? const <GroupSummary>[];
    final totalOwedToMe = list.where((s) => s.myNetMinor > 0).fold(0, (sum, s) => sum + s.myNetMinor);
    final totalIOwe = list.where((s) => s.myNetMinor < 0).fold(0, (sum, s) => sum - s.myNetMinor);

    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-group',
        onPressed: () => showGroupForm(context, ref),
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('New group'),
      ),
      body: list.isEmpty
          ? const EmptyState(
              icon: Icons.groups_outlined,
              title: 'Split bills with friends',
              message: 'Create a group for a trip, flat or dinner. Add expenses, split them equally, by percentage, shares or exact amounts, and settle up.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Expanded(child: _Total(label: 'You are owed', value: formatMinor(totalOwedToMe, symbol: symbol), color: const Color(0xFF2E9E6B))),
                      Expanded(child: _Total(label: 'You owe', value: formatMinor(totalIOwe, symbol: symbol), color: const Color(0xFFD9534F))),
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
                      subtitle: Text('${summary.members.length} members · ${formatMinor(summary.totalSpentMinor, symbol: symbol, showDecimals: false)} spent'),
                      trailing: _NetBadge(net: summary.myNetMinor, symbol: symbol),
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

class _NetBadge extends StatelessWidget {
  const _NetBadge({required this.net, required this.symbol});
  final int net;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    if (net == 0) return Text('settled', style: Theme.of(context).textTheme.bodySmall);
    final color = net > 0 ? const Color(0xFF2E9E6B) : const Color(0xFFD9534F);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(net > 0 ? 'you get' : 'you owe', style: Theme.of(context).textTheme.bodySmall),
        Text(formatMinor(net.abs(), symbol: symbol), style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/repositories/groups_repository.dart';
import '../shell/widgets/common.dart';

final _groupProvider = StreamProvider.family((ref, String id) => ref.watch(groupsRepositoryProvider).watchGroup(id));
final _membersProvider = StreamProvider.family((ref, String id) => ref.watch(groupsRepositoryProvider).watchMembers(id));
final _entriesProvider = StreamProvider.family((ref, String id) => ref.watch(groupsRepositoryProvider).watchGroupEntries(id));
final _settlementsProvider = StreamProvider.family((ref, String id) => ref.watch(groupsRepositoryProvider).watchSettlements(id));
final _balancesProvider = StreamProvider.family((ref, String id) => ref.watch(groupsRepositoryProvider).watchBalances(id));

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(_groupProvider(groupId)).value;
    final members = ref.watch(_membersProvider(groupId)).value ?? const <Member>[];
    final entries = ref.watch(_entriesProvider(groupId)).value ?? const <(Entry, List<Split>)>[];
    final settlements = ref.watch(_settlementsProvider(groupId)).value ?? const <Settlement>[];
    final balances = ref.watch(_balancesProvider(groupId)).value;
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final symbol = ref.watch(settingsProvider).currencySymbol;
    if (group == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final memberById = {for (final m in members) m.id: m};
    final categoryById = {for (final c in categories) c.id: c};
    String nameOf(String id) {
      final member = memberById[id];
      if (member == null) return 'Unknown';
      return member.isMe ? 'You' : member.name;
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          actions: [
            IconButton(
              tooltip: 'Share summary',
              icon: const Icon(Icons.ios_share),
              onPressed: () => SharePlus.instance.share(ShareParams(text: _summaryText(group, members, balances, symbol))),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                final repo = ref.read(groupsRepositoryProvider);
                switch (value) {
                  case 'rename':
                    final name = await promptText(context, title: 'Rename group', initial: group.name);
                    if (name != null && name.isNotEmpty) await repo.updateGroup(GroupsCompanion(id: Value(group.id), name: Value(name)));
                  case 'simplify':
                    await repo.updateGroup(GroupsCompanion(id: Value(group.id), simplifyDebts: Value(!group.simplifyDebts)));
                  case 'delete':
                    if (await confirmDialog(context, title: 'Delete ${group.name}?', message: 'All expenses in this group will be removed.')) {
                      await repo.deleteGroup(group.id);
                      if (context.mounted) context.pop();
                    }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'simplify', child: Text(group.simplifyDebts ? 'Turn off simplify debts' : 'Turn on simplify debts')),
                const PopupMenuItem(value: 'delete', child: Text('Delete group')),
              ],
            ),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Expenses'), Tab(text: 'Balances'), Tab(text: 'Members')]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'add-group-expense',
          onPressed: members.length < 2
              ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one more member first')))
              : () => context.push('/entry?group=$groupId'),
          icon: const Icon(Icons.add),
          label: const Text('Add expense'),
        ),
        body: TabBarView(
          children: [
            _ExpensesTab(entries: entries, settlements: settlements, nameOf: nameOf, categoryById: categoryById, symbol: symbol, groupId: groupId),
            _BalancesTab(group: group, members: members, balances: balances, nameOf: nameOf, symbol: symbol),
            _MembersTab(groupId: groupId, members: members, balances: balances, symbol: symbol),
          ],
        ),
      ),
    );
  }

  static String _summaryText(Group group, List<Member> members, GroupBalances? balances, String symbol) {
    final buffer = StringBuffer('${group.name} — balances\n');
    final byId = {for (final m in members) m.id: m.name};
    for (final transfer in balances?.suggested ?? const []) {
      buffer.writeln('${byId[transfer.from]} pays ${byId[transfer.to]} ${formatMinor(transfer.amountMinor, symbol: symbol)}');
    }
    if (balances == null || balances.suggested.isEmpty) buffer.writeln('All settled up.');
    buffer.writeln('\nShared from Hisab');
    return buffer.toString();
  }
}

class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab({required this.entries, required this.settlements, required this.nameOf, required this.categoryById, required this.symbol, required this.groupId});
  final List<(Entry, List<Split>)> entries;
  final List<Settlement> settlements;
  final String Function(String) nameOf;
  final Map<String, Category> categoryById;
  final String symbol;
  final String groupId;

  @override
  Widget build(BuildContext context) {
    final rows = <(DateTime, Widget)>[
      for (final (entry, splits) in entries)
        (
          entry.occurredAt,
          ListTile(
            leading: IconBadge(icon: categoryById[entry.categoryId]?.icon, color: categoryById[entry.categoryId]?.color ?? 0xFF607D8B),
            title: Text(entry.note.isNotEmpty ? entry.note : (entry.payee ?? categoryById[entry.categoryId]?.name ?? 'Expense')),
            subtitle: Text('${nameOf(entry.paidByMemberId ?? '')} paid · ${splits.length} people · ${formatShortDate(entry.occurredAt)}'),
            trailing: Text(formatMinor(entry.amountMinor, symbol: symbol), style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: () => context.push('/entry?id=${entry.id}'),
          )
        ),
      for (final settlement in settlements)
        (
          settlement.occurredAt,
          ListTile(
            leading: const IconBadge(icon: 'handshake', color: 0xFF2E9E6B),
            title: Text('${nameOf(settlement.fromMemberId)} paid ${nameOf(settlement.toMemberId)}'),
            subtitle: Text('Settlement · ${formatShortDate(settlement.occurredAt)}'),
            trailing: Text(formatMinor(settlement.amountMinor, symbol: symbol), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2E9E6B))),
          )
        ),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    if (rows.isEmpty) {
      return const EmptyState(icon: Icons.receipt_long_outlined, title: 'No expenses yet', message: 'Add the first shared expense with the button below.');
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [Card(child: Column(children: [for (final row in rows) row.$2]))]);
  }
}

class _BalancesTab extends ConsumerWidget {
  const _BalancesTab({required this.group, required this.members, required this.balances, required this.nameOf, required this.symbol});
  final Group group;
  final List<Member> members;
  final GroupBalances? balances;
  final String Function(String) nameOf;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (balances == null) return const Center(child: CircularProgressIndicator());
    final net = balances!.net;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        const SectionHeader('Net balances'),
        Card(
          child: Column(children: [
            for (final member in members)
              ListTile(
                leading: CircleAvatar(child: Text(member.name.isEmpty ? '?' : member.name[0].toUpperCase())),
                title: Text(nameOf(member.id)),
                trailing: Text(
                  (net[member.id] ?? 0) == 0
                      ? 'settled'
                      : '${(net[member.id] ?? 0) > 0 ? 'gets back' : 'owes'} ${formatMinor((net[member.id] ?? 0).abs(), symbol: symbol)}',
                  style: TextStyle(fontWeight: FontWeight.w600, color: (net[member.id] ?? 0) >= 0 ? const Color(0xFF2E9E6B) : const Color(0xFFD9534F)),
                ),
              ),
          ]),
        ),
        SectionHeader(group.simplifyDebts ? 'Settle up (simplified)' : 'Settle up'),
        if (balances!.suggested.isEmpty)
          const Card(child: ListTile(leading: Icon(Icons.check_circle_outline), title: Text('Everyone is settled up')))
        else
          Card(
            child: Column(children: [
              for (final transfer in balances!.suggested)
                ListTile(
                  leading: const Icon(Icons.arrow_forward),
                  title: Text('${nameOf(transfer.from)} → ${nameOf(transfer.to)}'),
                  trailing: Text(formatMinor(transfer.amountMinor, symbol: symbol), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                    onPressed: () async {
                      final text = await promptText(context, title: 'Record payment', initial: minorToDouble(transfer.amountMinor).toStringAsFixed(2), keyboardType: const TextInputType.numberWithOptions(decimal: true));
                      final amount = text == null ? null : parseAmountToMinor(text);
                      if (amount == null || amount <= 0) return;
                      await ref.read(groupsRepositoryProvider).addSettlement(groupId: group.id, fromMemberId: transfer.from, toMemberId: transfer.to, amountMinor: amount);
                    },
                    child: const Text('Record payment'),
                  ),
                ),
            ]),
          ),
      ],
    );
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.groupId, required this.members, required this.balances, required this.symbol});
  final String groupId;
  final List<Member> members;
  final GroupBalances? balances;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(groupsRepositoryProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Card(
          child: Column(children: [
            for (final member in members)
              ListTile(
                leading: CircleAvatar(child: Text(member.name.isEmpty ? '?' : member.name[0].toUpperCase())),
                title: Text(member.isMe ? '${member.name} (you)' : member.name),
                subtitle: member.phone == null ? null : Text(member.phone!),
                trailing: member.isMe
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.person_remove_outlined),
                        onPressed: () async {
                          final owed = balances?.net[member.id] ?? 0;
                          if (owed != 0) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settle this member\'s balance before removing them')));
                            return;
                          }
                          if (await confirmDialog(context, title: 'Remove ${member.name}?', confirmLabel: 'Remove')) await repo.removeMember(member.id);
                        },
                      ),
                onTap: () async {
                  final name = await promptText(context, title: 'Rename member', initial: member.name);
                  if (name != null && name.isNotEmpty) await repo.updateMember(MembersCompanion(id: Value(member.id), name: Value(name)));
                },
              ),
            ListTile(
              leading: const Icon(Icons.person_add_outlined),
              title: const Text('Add member'),
              onTap: () async {
                final name = await promptText(context, title: 'Member name', hint: 'Name');
                if (name != null && name.isNotEmpty) await repo.addMember(groupId, name);
              },
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Text('Members are stored on this device. Shared sync with invite codes is planned; see Settings → Sync.', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

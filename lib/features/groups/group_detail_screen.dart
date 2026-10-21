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
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
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
    final l10n = context.l10n;
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
      if (member == null) return l10n.unknown;
      return member.isMe ? l10n.you : member.name;
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          actions: [
            IconButton(
              tooltip: l10n.shareSummary,
              icon: const Icon(Icons.ios_share),
              onPressed: () => SharePlus.instance.share(ShareParams(text: _summaryText(l10n, group, members, balances, symbol))),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                final repo = ref.read(groupsRepositoryProvider);
                switch (value) {
                  case 'rename':
                    final name = await promptText(context, title: l10n.renameGroup, initial: group.name);
                    if (name != null && name.isNotEmpty) await repo.updateGroup(GroupsCompanion(id: Value(group.id), name: Value(name)));
                  case 'simplify':
                    await repo.updateGroup(GroupsCompanion(id: Value(group.id), simplifyDebts: Value(!group.simplifyDebts)));
                  case 'delete':
                    if (await confirmDialog(context, title: l10n.deleteNamed(group.name), message: l10n.deleteGroupBody, confirmLabel: l10n.delete)) {
                      await repo.deleteGroup(group.id);
                      if (context.mounted) context.pop();
                    }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'rename', child: Text(l10n.rename)),
                PopupMenuItem(value: 'simplify', child: Text(group.simplifyDebts ? l10n.simplifyOff : l10n.simplifyOn)),
                PopupMenuItem(value: 'delete', child: Text(l10n.deleteGroup)),
              ],
            ),
          ],
          bottom: TabBar(tabs: [Tab(text: l10n.kindExpenses), Tab(text: l10n.balances), Tab(text: l10n.members)]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'add-group-expense',
          onPressed: members.length < 2
              ? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.addMemberFirst)))
              : () => context.push('/entry?group=$groupId'),
          icon: const Icon(Icons.add),
          label: Text(l10n.addExpense),
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

  static String _summaryText(AppLocalizations l10n, Group group, List<Member> members, GroupBalances? balances, String symbol) {
    final buffer = StringBuffer('${l10n.shareHeader(group.name)}\n');
    final byId = {for (final m in members) m.id: m.name};
    for (final transfer in balances?.suggested ?? const []) {
      buffer.writeln(l10n.sharePays(byId[transfer.from] ?? l10n.unknown, byId[transfer.to] ?? l10n.unknown, formatMinor(transfer.amountMinor, symbol: symbol)));
    }
    if (balances == null || balances.suggested.isEmpty) buffer.writeln(l10n.allSettledUp);
    buffer.writeln('\n${l10n.sharedFromHisab}');
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
    final l10n = context.l10n;
    final rows = <(DateTime, Widget)>[
      for (final (entry, splits) in entries)
        (
          entry.occurredAt,
          ListTile(
            leading: IconBadge(icon: categoryById[entry.categoryId]?.icon, color: categoryById[entry.categoryId]?.color ?? 0xFF607D8B),
            title: Text(entry.note.isNotEmpty ? entry.note : (entry.payee ?? categoryById[entry.categoryId]?.displayName(context) ?? l10n.kindExpense)),
            subtitle: Text(l10n.paidByLine(nameOf(entry.paidByMemberId ?? ''), splits.length, formatShortDate(entry.occurredAt))),
            trailing: Text(formatMinor(entry.amountMinor, symbol: symbol), style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: () => context.push('/entry?id=${entry.id}'),
          )
        ),
      for (final settlement in settlements)
        (
          settlement.occurredAt,
          ListTile(
            leading: const IconBadge(icon: 'handshake', color: 0xFF2E9E6B),
            title: Text(l10n.settlementLine(nameOf(settlement.fromMemberId), nameOf(settlement.toMemberId))),
            subtitle: Text(l10n.settlementSubtitle(formatShortDate(settlement.occurredAt))),
            trailing: Text(formatMinor(settlement.amountMinor, symbol: symbol), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2E9E6B))),
          )
        ),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    if (rows.isEmpty) {
      return EmptyState(icon: Icons.receipt_long_outlined, title: l10n.noGroupExpensesTitle, message: l10n.noGroupExpensesBody);
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
    final l10n = context.l10n;
    if (balances == null) return const Center(child: CircularProgressIndicator());
    final net = balances!.net;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        SectionHeader(l10n.netBalances),
        Card(
          child: Column(children: [
            for (final member in members)
              ListTile(
                leading: CircleAvatar(child: Text(member.name.isEmpty ? '?' : member.name[0].toUpperCase())),
                title: Text(nameOf(member.id)),
                trailing: Text(
                  (net[member.id] ?? 0) == 0
                      ? l10n.settled
                      : '${(net[member.id] ?? 0) > 0 ? l10n.getsBack : l10n.owes} ${formatMinor((net[member.id] ?? 0).abs(), symbol: symbol)}',
                  style: TextStyle(fontWeight: FontWeight.w600, color: (net[member.id] ?? 0) >= 0 ? const Color(0xFF2E9E6B) : const Color(0xFFD9534F)),
                ),
              ),
          ]),
        ),
        SectionHeader(group.simplifyDebts ? l10n.settleUpSimplified : l10n.settleUp),
        if (balances!.suggested.isEmpty)
          Card(child: ListTile(leading: const Icon(Icons.check_circle_outline), title: Text(l10n.everyoneSettled)))
        else
          Card(
            child: Column(children: [
              for (final transfer in balances!.suggested)
                ListTile(
                  leading: const Icon(Icons.arrow_forward),
                  title: Text(l10n.transferArrow(nameOf(transfer.from), nameOf(transfer.to))),
                  trailing: Text(formatMinor(transfer.amountMinor, symbol: symbol), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                    onPressed: () async {
                      final amount = await promptAmount(context, title: l10n.recordPayment, initialMinor: transfer.amountMinor);
                      if (amount == null || amount <= 0) return;
                      await ref.read(groupsRepositoryProvider).addSettlement(groupId: group.id, fromMemberId: transfer.from, toMemberId: transfer.to, amountMinor: amount);
                    },
                    child: Text(l10n.recordPayment),
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
    final l10n = context.l10n;
    final repo = ref.read(groupsRepositoryProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Card(
          child: Column(children: [
            for (final member in members)
              ListTile(
                leading: CircleAvatar(child: Text(member.name.isEmpty ? '?' : member.name[0].toUpperCase())),
                title: Text(member.isMe ? l10n.youSuffix(member.name) : member.name),
                subtitle: member.phone == null ? null : Text(member.phone!),
                trailing: member.isMe
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.person_remove_outlined),
                        onPressed: () async {
                          final owed = balances?.net[member.id] ?? 0;
                          if (owed != 0) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.settleBeforeRemove)));
                            return;
                          }
                          if (await confirmDialog(context, title: l10n.removeNamed(member.name), confirmLabel: l10n.remove)) await repo.removeMember(member.id);
                        },
                      ),
                onTap: () async {
                  final name = await promptText(context, title: l10n.renameMember, initial: member.name);
                  if (name != null && name.isNotEmpty) await repo.updateMember(MembersCompanion(id: Value(member.id), name: Value(name)));
                },
              ),
            ListTile(
              leading: const Icon(Icons.person_add_outlined),
              title: Text(l10n.addMember),
              onTap: () async {
                final name = await promptText(context, title: l10n.memberName, hint: l10n.name);
                if (name != null && name.isNotEmpty) await repo.addMember(groupId, name);
              },
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Text(l10n.membersLocalNotice, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

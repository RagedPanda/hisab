import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../data/repositories/groups_repository.dart';
import '../../domain/split/debt_simplifier.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'member_display.dart';

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
      return member == null ? l10n.unknown : memberShortName(l10n, member);
    }
    final myMemberId = members.where((member) => member.isMe).firstOrNull?.id;

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
            _ExpensesTab(entries: entries, settlements: settlements, nameOf: nameOf, categoryById: categoryById, symbol: symbol, groupId: groupId, myMemberId: myMemberId),
            _BalancesTab(group: group, members: members, settlements: settlements, balances: balances, nameOf: nameOf, symbol: symbol),
            _MembersTab(groupId: groupId, members: members, balances: balances, symbol: symbol),
          ],
        ),
      ),
    );
  }

  static String _summaryText(AppLocalizations l10n, Group group, List<Member> members, GroupBalances? balances, String symbol) {
    final buffer = StringBuffer('${l10n.shareHeader(group.name)}\n');
    final byId = {for (final member in members) member.id: memberShortName(l10n, member)};
    for (final transfer in balances?.suggested ?? const []) {
      buffer.writeln(l10n.sharePays(byId[transfer.from] ?? l10n.unknown, byId[transfer.to] ?? l10n.unknown, formatMinor(transfer.amountMinor, symbol: symbol)));
    }
    if (balances == null || balances.suggested.isEmpty) buffer.writeln(l10n.allSettledUp);
    buffer.writeln('\n${l10n.sharedFromHisab}');
    return buffer.toString();
  }
}

class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab({
    required this.entries,
    required this.settlements,
    required this.nameOf,
    required this.categoryById,
    required this.symbol,
    required this.groupId,
    required this.myMemberId,
  });
  final List<(Entry, List<Split>)> entries;
  final List<Settlement> settlements;
  final String Function(String) nameOf;
  final Map<String, Category> categoryById;
  final String symbol;
  final String groupId;
  final String? myMemberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final rows = <(DateTime, Widget)>[
      for (final (entry, splits) in entries)
        (
          entry.occurredAt,
          ListTile(
            leading: IconBadge(icon: categoryById[entry.categoryId]?.icon, color: categoryById[entry.categoryId]?.color ?? 0xFF607D8B),
            title: Text(entry.note.isNotEmpty ? entry.note : (entry.payee ?? categoryById[entry.categoryId]?.displayName(context) ?? l10n.kindExpense), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(_expenseSubtitle(l10n, entry, splits), maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: _AmountWithDate(amountMinor: entry.amountMinor, date: entry.occurredAt, symbol: symbol, locale: locale),
            onTap: () => context.push('/entry?id=${entry.id}'),
          )
        ),
      for (final settlement in settlements)
        (
          settlement.occurredAt,
          ListTile(
            leading: const IconBadge(icon: 'handshake', color: 0xFF2E9E6B),
            title: Text(l10n.settlementLine(nameOf(settlement.fromMemberId), nameOf(settlement.toMemberId)), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(l10n.settlementSubtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: _AmountWithDate(amountMinor: settlement.amountMinor, date: settlement.occurredAt, symbol: symbol, locale: locale, color: kIncomeColor),
            onTap: () => confirmRemoveSettlement(context, ref, settlement),
          )
        ),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    if (rows.isEmpty) {
      return EmptyState(icon: Icons.receipt_long_outlined, title: l10n.noGroupExpensesTitle, message: l10n.noGroupExpensesBody);
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [Card(child: Column(children: [for (final row in rows) row.$2]))]);
  }

  String _expenseSubtitle(AppLocalizations l10n, Entry entry, List<Split> splits) {
    final myShare = splits.where((split) => split.memberId == myMemberId).firstOrNull;
    final parts = [
      l10n.paidByPeople(nameOf(entry.paidByMemberId ?? ''), splits.length),
      if (myShare != null) l10n.yourShare(formatMinor(myShare.amountMinor, symbol: symbol)),
    ];
    return parts.join(' · ');
  }
}

/// Amount over a short date, right-aligned, matching the dashboard entry rows.
class _AmountWithDate extends StatelessWidget {
  const _AmountWithDate({required this.amountMinor, required this.date, required this.symbol, required this.locale, this.color});
  final int amountMinor;
  final DateTime date;
  final String symbol;
  final String locale;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(formatMinor(amountMinor, symbol: symbol), style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600, color: color).tabular),
        Text(formatRowDate(date, locale: locale), style: theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant).tabular),
      ],
    );
  }
}

/// Asks before soft-deleting a recorded payment, then offers Undo.
Future<void> confirmRemoveSettlement(BuildContext context, WidgetRef ref, Settlement settlement) async {
  final l10n = context.l10n;
  final confirmed = await confirmDialog(context, title: l10n.removePayment, message: l10n.removePaymentBody, confirmLabel: l10n.remove);
  if (!confirmed || !context.mounted) return;
  final repo = ref.read(groupsRepositoryProvider);
  await repo.deleteSettlement(settlement.id);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(l10n.paymentRemoved),
    action: SnackBarAction(label: l10n.undo, onPressed: () => repo.restoreSettlement(settlement.id)),
  ));
}

class _BalancesTab extends ConsumerWidget {
  const _BalancesTab({required this.group, required this.members, required this.settlements, required this.balances, required this.nameOf, required this.symbol});
  final Group group;
  final List<Member> members;
  final List<Settlement> settlements;
  final GroupBalances? balances;
  final String Function(String) nameOf;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (balances == null) return const Center(child: CircularProgressIndicator());
    final net = balances!.net;
    final locale = Localizations.localeOf(context).toString();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        SectionHeader(l10n.netBalances),
        Card(
          child: Column(children: [
            for (final member in members)
              ListTile(
                leading: MemberAvatar(member: member),
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
                    onPressed: () => _recordPayment(context, ref, transfer),
                    child: Text(l10n.recordPayment),
                  ),
                ),
            ]),
          ),
        if (settlements.isNotEmpty) ...[
          SectionHeader(l10n.settledPayments),
          Card(
            child: Column(children: [
              for (final settlement in settlements)
                ListTile(
                  leading: const Icon(Icons.handshake_outlined),
                  title: Text(l10n.transferArrow(nameOf(settlement.fromMemberId), nameOf(settlement.toMemberId)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(formatRowDate(settlement.occurredAt, locale: locale)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(formatMinor(settlement.amountMinor, symbol: symbol), style: const TextStyle(fontWeight: FontWeight.w600).tabular),
                      PopupMenuButton<void>(
                        tooltip: l10n.moreOptions,
                        itemBuilder: (context) => [
                          PopupMenuItem(onTap: () => confirmRemoveSettlement(context, ref, settlement), child: Text(l10n.removePayment)),
                        ],
                      ),
                    ],
                  ),
                ),
            ]),
          ),
        ],
      ],
    );
  }

  Future<void> _recordPayment(BuildContext context, WidgetRef ref, Transfer transfer) async {
    final l10n = context.l10n;
    final amount = await promptAmount(context, title: l10n.recordPayment, initialMinor: transfer.amountMinor);
    if (amount == null || amount <= 0 || !context.mounted) return;
    final repo = ref.read(groupsRepositoryProvider);
    final id = await repo.addSettlement(groupId: group.id, fromMemberId: transfer.from, toMemberId: transfer.to, amountMinor: amount);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.paymentRecorded(l10n.transferArrow(nameOf(transfer.from), nameOf(transfer.to)), formatMinor(amount, symbol: symbol))),
      action: SnackBarAction(label: l10n.undo, onPressed: () => repo.deleteSettlement(id)),
    ));
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
                leading: MemberAvatar(member: member),
                title: Text(memberDisplayName(l10n, member)),
                subtitle: member.phone == null ? null : Text(member.phone!),
                trailing: member.isMe
                    ? null
                    : IconButton(
                        tooltip: l10n.removeNamed(member.name),
                        icon: const Icon(Icons.person_remove_outlined),
                        onPressed: () async {
                          final current = balances;
                          final settled = current != null && isMemberSettled(memberId: member.id, net: current.net, transfers: current.suggested);
                          if (!settled) {
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

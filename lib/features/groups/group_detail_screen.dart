import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' hide Split;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../data/repositories/groups_repository.dart';
import '../../domain/split/debt_simplifier.dart';
import '../../domain/split/group_settings.dart';
import '../../domain/split/settle_up_links.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'group_actions.dart';
import 'group_expenses_tab.dart';
import 'member_display.dart';
import 'member_sheet.dart';
import 'record_payment_sheet.dart';
import 'settle_up_messages.dart';
import 'settle_up_sheet.dart';

/// One stream for the whole screen so every tab sees the same snapshot.
final groupDetailProvider = StreamProvider.family((ref, String id) => ref.watch(groupsRepositoryProvider).watchGroupDetail(id));

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(groupDetailProvider(groupId)).value;
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final appSymbol = ref.watch(settingsProvider).currencySymbol;
    if (detail == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final group = detail.group;
    final symbol = groupSymbol(currencyLabel: group.currencyLabel, appSymbol: appSymbol);
    final archived = group.archivedAt != null;
    final members = detail.members;
    final entries = detail.entries;
    final settlements = detail.settlements;
    final balances = detail.balances;
    // Resolved from every member ever in the group, so history keeps the
    // names of people who have since been removed.
    final memberById = {for (final m in detail.allMembers) m.id: m};
    final categoryById = {for (final c in categories) c.id: c};
    String nameOf(String id) {
      final member = memberById[id];
      return member == null ? l10n.unknown : memberShortName(l10n, member);
    }
    final myMemberId = detail.me?.id;
    // Members offered in the payment sheet: current ones, plus whoever an
    // existing payment already names (they may have been removed since).
    Future<void> openPaymentSheet({Settlement? existing, String? from, String? to, int? amountMinor}) {
      final referenced = {existing?.fromMemberId, existing?.toMemberId};
      final candidates = detail.allMembers.where((member) => member.deletedAt == null || referenced.contains(member.id)).toList();
      return showRecordPaymentSheet(context, ref, group: group, members: candidates, balances: balances, symbol: symbol, existing: existing, fromMemberId: from, toMemberId: to, amountMinor: amountMinor);
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
              onPressed: () => _showShareOptions(context, ref, detail: detail, symbol: symbol),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'settings':
                    await context.push('/groups/$groupId/settings');
                  case 'archive':
                    await confirmArchiveGroup(context, ref, detail);
                  case 'unarchive':
                    await ref.read(groupsRepositoryProvider).unarchiveGroup(group.id);
                  case 'delete':
                    if (await confirmDeleteGroup(context, ref, detail) && context.mounted) context.pop();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'settings', child: Text(l10n.groupSettingsTitle)),
                PopupMenuItem(value: archived ? 'unarchive' : 'archive', child: Text(archived ? l10n.groupUnarchive : l10n.groupArchive)),
                PopupMenuItem(value: 'delete', child: Text(l10n.deleteGroup)),
              ],
            ),
          ],
          bottom: TabBar(tabs: [Tab(text: l10n.kindExpenses), Tab(text: l10n.balances), Tab(text: l10n.members)]),
        ),
        floatingActionButton: archived
            ? null
            : FloatingActionButton.extended(
                heroTag: 'add-group-expense',
                onPressed: members.length < 2
                    ? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.addMemberFirst)))
                    : () => context.push('/entry?group=$groupId'),
                icon: const Icon(Icons.add),
                label: Text(l10n.addExpense),
              ),
        body: Column(children: [
          if (archived) _ArchivedBanner(left: detail.me == null, onUnarchive: () => ref.read(groupsRepositoryProvider).unarchiveGroup(group.id)),
          Expanded(child: TabBarView(
          children: [
            GroupExpensesTab(
              groupId: groupId,
              groupType: GroupType.parse(group.type),
              notes: group.notes,
              entries: entries,
              settlements: settlements,
              timelineByEntryId: detail.timelineByEntryId,
              settledUpTo: detail.settledUpTo,
              myMemberId: myMemberId,
              nameOf: nameOf,
              categoryById: categoryById,
              symbol: symbol,
              openPayment: (settlement) => openPaymentSheet(existing: settlement),
            ),
            _BalancesTab(detail: detail, nameOf: nameOf, symbol: symbol, openPayment: openPaymentSheet),
            _MembersTab(groupId: groupId, members: members, balances: balances, symbol: symbol),
          ],
        )),
        ]),
      ),
    );
  }

  /// Share balances summary, remind everyone who owes me, or copy the summary.
  static Future<void> _showShareOptions(BuildContext context, WidgetRef ref, {required GroupDetail detail, required String symbol}) {
    final l10n = context.l10n;
    final summary = summaryText(l10n, detail.group, detail.members, detail.balances, symbol);
    final myId = detail.me?.id;
    final owedToMe = [for (final transfer in detail.balances.suggested) if (settleRoleFor(transfer, myId) == SettleRole.remind) transfer];
    final nameById = {for (final member in detail.allMembers) member.id: memberShortName(l10n, member)};
    Future<void> remindEveryone() async {
      final message = remindEveryoneMessage(
        l10n,
        groupName: detail.group.name,
        transfers: [
          for (final transfer in owedToMe)
            (from: nameById[transfer.from] ?? l10n.unknown, to: nameById[transfer.to] ?? l10n.unknown, amount: formatMinor(transfer.amountMinor, symbol: symbol)),
        ],
      );
      if (!await ref.read(textSharerProvider)(message)) return;
      final repo = ref.read(groupsRepositoryProvider);
      for (final transfer in owedToMe) {
        await repo.recordSettleUpReminder(groupId: detail.group.id, memberId: transfer.from, channel: 'share', message: message);
      }
    }

    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) {
        void run(Future<void> Function() action) {
          Navigator.of(sheetContext).pop();
          action();
        }

        return SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.ios_share),
              title: Text(l10n.shareBalancesSummary),
              onTap: () => run(() => ref.read(textSharerProvider)(summary)),
            ),
            if (owedToMe.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(l10n.remindEveryoneWhoOwes),
                onTap: () => run(remindEveryone),
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(l10n.copyAsText),
              onTap: () => run(() async {
                await Clipboard.setData(ClipboardData(text: summary));
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.copied)));
              }),
            ),
          ]),
        );
      },
    );
  }

  static String summaryText(AppLocalizations l10n, Group group, List<Member> members, GroupBalances balances, String symbol) {
    final buffer = StringBuffer('${l10n.shareHeader(group.name)}\n');
    final byId = {for (final member in members) member.id: memberShortName(l10n, member)};
    for (final transfer in balances.suggested) {
      buffer.writeln(l10n.sharePays(byId[transfer.from] ?? l10n.unknown, byId[transfer.to] ?? l10n.unknown, formatMinor(transfer.amountMinor, symbol: symbol)));
    }
    if (balances.suggested.isEmpty) buffer.writeln(l10n.allSettledUp);
    buffer.writeln('\n${l10n.sharedFromHisab}');
    return buffer.toString();
  }
}

/// Shown above the tabs of an archived group, with Unarchive.
class _ArchivedBanner extends StatelessWidget {
  const _ArchivedBanner({required this.left, required this.onUnarchive});

  /// I left the group, rather than only archiving it.
  final bool left;
  final VoidCallback onUnarchive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(children: [
          Icon(Icons.archive_outlined, color: scheme.onSecondaryContainer),
          const SizedBox(width: 12),
          Expanded(child: Text(left ? l10n.groupLeftBanner : l10n.groupArchivedBanner, style: TextStyle(color: scheme.onSecondaryContainer))),
          TextButton(onPressed: onUnarchive, child: Text(l10n.groupUnarchive)),
        ]),
      ),
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
  const _BalancesTab({required this.detail, required this.nameOf, required this.symbol, required this.openPayment});
  final GroupDetail detail;
  final Future<void> Function({Settlement? existing, String? from, String? to, int? amountMinor}) openPayment;
  final String Function(String) nameOf;
  final String symbol;

  /// Opens Remind or Pay for [transfer] with the prewritten message.
  void _openSettleUp(BuildContext context, Transfer transfer, SettleRole role) {
    final l10n = context.l10n;
    final memberById = {for (final member in detail.allMembers) member.id: member};
    final counterpart = memberById[role == SettleRole.remind ? transfer.from : transfer.to];
    if (counterpart == null) return;
    // The message goes to the other person, so it names them, never "You".
    String plainName(String id) => memberById[id]?.name ?? l10n.unknown;
    showSettleUpSheet(
      context,
      group: detail.group,
      transfer: transfer,
      role: role,
      counterpart: counterpart,
      symbol: symbol,
      lastRemindedAt: detail.lastRemindedAt[counterpart.id],
      message: settleUpMessage(
        l10n,
        role: role,
        transfer: (from: plainName(transfer.from), to: plainName(transfer.to), amount: formatMinor(transfer.amountMinor, symbol: symbol)),
        groupName: detail.group.name,
      ),
      onRecordPayment: () => openPayment(from: transfer.from, to: transfer.to, amountMinor: transfer.amountMinor),
    );
  }

  Widget _transferTile(BuildContext context, Transfer transfer) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final role = settleRoleFor(transfer, detail.me?.id);
    final lastReminded = role == SettleRole.remind ? detail.lastRemindedAt[transfer.from] : null;
    final compact = TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 36), tapTargetSize: MaterialTapTargetSize.shrinkWrap);
    return ListTile(
      leading: const Icon(Icons.arrow_forward),
      title: Text(l10n.transferArrow(nameOf(transfer.from), nameOf(transfer.to))),
      trailing: Text(formatMinor(transfer.amountMinor, symbol: symbol), style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lastReminded != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(l10n.remindedDaysAgo(daysBetween(lastReminded, DateTime.now())), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
          Wrap(
            spacing: 4,
            children: [
              if (role != SettleRole.others)
                TextButton.icon(
                  style: compact,
                  onPressed: () => _openSettleUp(context, transfer, role),
                  icon: Icon(role == SettleRole.remind ? Icons.notifications_active_outlined : Icons.send_outlined, size: 18),
                  label: Text(role == SettleRole.remind ? (lastReminded == null ? l10n.remindAction : l10n.remindAgain) : l10n.payAction),
                ),
              TextButton(
                style: compact,
                onPressed: () => openPayment(from: transfer.from, to: transfer.to, amountMinor: transfer.amountMinor),
                child: Text(l10n.recordPayment),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final group = detail.group;
    final members = detail.members;
    final settlements = detail.settlements;
    final balances = detail.balances;
    final net = balances.net;
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
        Card(
          child: Column(children: [
            if (balances.suggested.isEmpty)
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(l10n.nothingToRemind),
                subtitle: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => ref.read(textSharerProvider)(GroupDetailScreen.summaryText(l10n, group, members, balances, symbol)),
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: Text(l10n.shareSummaryAnyway),
                  ),
                ),
              )
            else
              for (final transfer in balances.suggested) _transferTile(context, transfer),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_card_outlined),
              title: Text(l10n.recordAPayment),
              subtitle: Text(l10n.recordAPaymentHint),
              onTap: () => openPayment(),
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
                  subtitle: Text('${formatRowDate(settlement.occurredAt, locale: locale)} · ${paymentMethodLabel(settlement.method, l10n)}'),
                  onTap: () => openPayment(existing: settlement),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(formatMinor(settlement.amountMinor, symbol: symbol), style: const TextStyle(fontWeight: FontWeight.w600).tabular),
                      PopupMenuButton<void>(
                        tooltip: l10n.moreOptions,
                        itemBuilder: (context) => [
                          PopupMenuItem(onTap: () => openPayment(existing: settlement), child: Text(l10n.editPayment)),
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
}

/// "phone · UPI ID" for a member's row, or null when neither is set.
String? _contactLine(Member member) {
  final parts = [member.phone, member.upiId].whereType<String>().where((part) => part.isNotEmpty);
  return parts.isEmpty ? null : parts.join(' · ');
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.groupId, required this.members, required this.balances, required this.symbol});
  final String groupId;
  final List<Member> members;
  final GroupBalances balances;
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
                subtitle: _contactLine(member) == null ? null : Text(_contactLine(member)!, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: member.isMe
                    ? null
                    : IconButton(
                        tooltip: l10n.removeNamed(member.name),
                        icon: const Icon(Icons.person_remove_outlined),
                        onPressed: () async {
                          // Pairwise debts, not the simplified ones: with simplify on a
                          // member in the middle of a chain nets to zero yet still owes.
                          final settled = isMemberSettled(memberId: member.id, net: balances.net, transfers: balances.pairwise);
                          if (!settled) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.settleBeforeRemove)));
                            return;
                          }
                          if (await confirmDialog(context, title: l10n.removeNamed(member.name), confirmLabel: l10n.remove)) await repo.removeMember(member.id);
                        },
                      ),
                onTap: () async {
                  final details = await showMemberSheet(context, existing: member);
                  if (details == null) return;
                  await repo.updateMember(MembersCompanion(id: Value(member.id), name: Value(details.name), phone: Value(details.phone), upiId: Value(details.upiId)));
                },
              ),
            ListTile(
              leading: const Icon(Icons.person_add_outlined),
              title: Text(l10n.addMember),
              onTap: () async {
                final details = await showMemberSheet(context);
                if (details != null) await repo.addMember(groupId, details.name, phone: details.phone, upiId: details.upiId);
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

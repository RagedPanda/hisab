import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../data/repositories/groups_repository.dart';
import '../../domain/split/group_settings.dart';
import '../../domain/split/settle_up_links.dart';
import '../../domain/split/settle_with_person.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'member_display.dart';
import 'record_payment_sheet.dart';
import 'settle_up_messages.dart';
import 'settle_up_sheet.dart';

/// The groups settling with a person looks at: every active group, plus
/// [currentGroupId] even when it is archived (its Balances tab is open).
List<PersonSettleGroup> personSettleGroupsOf(Iterable<GroupSummary> summaries, {required String appSymbol, required String currentGroupId}) => [
      for (final summary in summaries)
        if (summary.group.archivedAt == null || summary.group.id == currentGroupId)
          (
            groupId: summary.group.id,
            symbol: groupSymbol(currencyLabel: summary.group.currencyLabel, appSymbol: appSymbol),
            myMemberId: summary.members.where((member) => member.isMe).firstOrNull?.id,
            emailByMemberId: {for (final member in summary.members) member.id: member.email},
            suggested: summary.balances.suggested,
          ),
    ];

/// Lets me pick who in [members] (everyone but me) to settle with, then opens
/// [showSettleWithPersonSheet] for them.
Future<void> showSettlePersonPicker(BuildContext context, {required String groupId, required List<Member> members}) async {
  final picked = await showModalBottomSheet<Member>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(sheetContext.l10n.settleWithPickPerson, style: Theme.of(sheetContext).textTheme.titleLarge),
            ),
            for (final member in members.where((member) => !member.isMe))
              ListTile(
                leading: MemberAvatar(member: member),
                title: Text(member.name),
                onTap: () => Navigator.of(sheetContext).pop(member),
              ),
          ],
        ),
      ),
    ),
  );
  if (picked != null && context.mounted) await showSettleWithPersonSheet(context, groupId: groupId, member: picked);
}

/// Everything between me and [member] of [groupId], in that group or (when
/// they are in other groups too, matched by email) across all of them: a
/// per-group breakdown with totals, then one action that records a payment in
/// each group so every balance with them is zero. Pay with UPI and Share are
/// offered like the single-transfer settle-up sheet.
Future<void> showSettleWithPersonSheet(BuildContext context, {required String groupId, required Member member}) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => SettleWithPersonSheet(groupId: groupId, member: member, messenger: ScaffoldMessenger.of(context)),
  );
}

class SettleWithPersonSheet extends ConsumerStatefulWidget {
  const SettleWithPersonSheet({super.key, required this.groupId, required this.member, required this.messenger});
  final String groupId;
  final Member member;

  /// The screen underneath's messenger, for the Undo snackbar after closing.
  final ScaffoldMessengerState messenger;

  @override
  ConsumerState<SettleWithPersonSheet> createState() => _SettleWithPersonSheetState();
}

class _SettleWithPersonSheetState extends ConsumerState<SettleWithPersonSheet> {
  /// Null until the person picks a scope; see [_showAllGroups].
  bool? _allGroups;
  String _method = paymentMethods.first;

  /// Why Pay with UPI failed, shown inside the sheet.
  String? _problem;

  /// "This group" by default, unless we are square here and only other
  /// groups have something to settle.
  bool _showAllGroups({required bool hasOthers, required bool squareHere}) => hasOthers && (_allGroups ?? squareHere);

  String get _name => widget.member.name;

  Future<void> _record(List<PersonGroupShare> shares, String method) async {
    final l10n = context.l10n;
    final repo = ref.read(groupsRepositoryProvider);
    Navigator.of(context).pop();
    final ids = await repo.addSettlements([for (final share in shares) (groupId: share.groupId, transfer: share.settlement)], method: method);
    showUndoSnackBar(
      widget.messenger,
      message: l10n.settleWithRecorded(_name, shares.length),
      undoLabel: l10n.undo,
      onUndo: () => repo.deleteSettlements(ids),
    );
  }

  Future<void> _payWithUpi(List<PersonGroupShare> shares, {required String upiId, required int amountMinor, required String amountText, required String currency}) async {
    final l10n = context.l10n;
    final uri = upiPayUri(upiId: upiId, payeeName: _name, amountMinor: amountMinor, note: l10n.settleWithTitle(_name), currency: currency);
    if (!await ref.read(linkLauncherProvider)(uri)) {
      if (mounted) setState(() => _problem = l10n.noUpiApp);
      return;
    }
    if (!mounted || !await confirmUpiPaymentWentThrough(context, amount: amountText, name: _name) || !mounted) return;
    await _record(shares, 'upi');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final summaries = ref.watch(groupSummariesProvider).value;
    if (summaries == null) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
    final appSymbol = ref.watch(settingsProvider).currencySymbol;
    final groups = personSettleGroupsOf(summaries, appSymbol: appSymbol, currentGroupId: widget.groupId);
    final summaryById = {for (final summary in summaries) summary.group.id: summary};
    final hereShares = personShares(groups, groupId: widget.groupId, memberId: widget.member.id);
    final hasOthers = hasBalancesInOtherGroups(groups, groupId: widget.groupId, memberId: widget.member.id);
    final allGroups = _showAllGroups(hasOthers: hasOthers, squareHere: hereShares.isEmpty);
    final shares = allGroups ? personShares(groups, groupId: widget.groupId, memberId: widget.member.id, allGroups: true) : hereShares;
    final totals = personTotals(shares);
    String formatIn(String symbol, int minor) => formatMinor(minor.abs(), format: ref.watch(groupMoneyFormatProvider(symbol)));
    final upiAmount = singleCurrencyAmountIOwe(shares);
    final theirMembers = [for (final share in shares) ...?summaryById[share.groupId]?.members.where((member) => member.id == share.theirMemberId)];
    final upiId = theirMembers.map((member) => member.upiId?.trim() ?? '').where((upiId) => upiId.isNotEmpty).firstOrNull;
    final message = settleWithPersonMessage(
      l10n,
      name: _name,
      shares: [
        for (final share in shares) (group: summaryById[share.groupId]?.group.name ?? l10n.unknown, netMinor: share.netMinor, amount: formatIn(share.symbol, share.netMinor)),
      ],
      totals: [for (final total in totals) (netMinor: total.netMinor, amount: formatIn(total.symbol, total.netMinor))],
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.settleWithTitle(_name), style: theme.textTheme.titleLarge),
            if (hasOthers) ...[
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l10n.settleWithThisGroup)),
                  ButtonSegment(value: true, label: Text(l10n.settleWithAllGroups)),
                ],
                selected: {allGroups},
                showSelectedIcon: false,
                onSelectionChanged: (selection) => setState(() => _allGroups = selection.single),
              ),
            ],
            const SizedBox(height: 12),
            if (shares.isEmpty) ...[
              Text(l10n.settleWithSquare(_name), style: theme.textTheme.bodyLarge),
              if (!allGroups && settlesWithOthersIn(groups, groupId: widget.groupId, memberId: widget.member.id)) ...[
                const SizedBox(height: 8),
                Text(l10n.settleWithSquareOthers(_name), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ] else ...[
              for (final share in shares)
                ListTile(
                  key: ValueKey('settle-with-${share.groupId}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(summaryById[share.groupId]?.group.name ?? l10n.unknown),
                  subtitle: Text(share.netMinor > 0 ? l10n.settleWithTheyOwe(_name) : l10n.settleWithIOwe(_name)),
                  trailing: Text(
                    formatIn(share.symbol, share.netMinor),
                    style: TextStyle(fontWeight: FontWeight.w600, color: share.netMinor > 0 ? kIncomeColor : kExpenseColor).tabular,
                  ),
                ),
              const Divider(),
              for (final total in personSummaryTotals(shares))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    switch (total.netMinor) {
                      > 0 => l10n.settleWithTotalTheyOwe(_name, formatIn(total.symbol, total.netMinor)),
                      < 0 => l10n.settleWithTotalIOwe(_name, formatIn(total.symbol, total.netMinor)),
                      _ => l10n.settleWithEvensOut(total.symbol),
                    },
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 4),
              Text(l10n.settleWithExplain(_name), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              if (_problem case final problem?) ...[
                const SizedBox(height: 12),
                Text(problem, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 12),
              Text(l10n.paymentMethod, style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final method in paymentMethods)
                    ChoiceChip(
                      avatar: Icon(paymentMethodIcon(method), size: 18),
                      label: Text(paymentMethodLabel(method, l10n)),
                      selected: _method == method,
                      onSelected: (_) => setState(() => _method = method),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (upiAmount != null && upiId != null) ...[
                FilledButton.icon(
                  onPressed: () => _payWithUpi(
                    shares,
                    upiId: upiId,
                    amountMinor: upiAmount,
                    amountText: formatIn(totals.single.symbol, upiAmount),
                    currency: summaryById[shares.first.groupId]?.group.currency ?? 'INR',
                  ),
                  icon: const Icon(Icons.qr_code_2),
                  label: Text(l10n.payWithUpi),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton.tonalIcon(
                key: const Key('settle-with-record'),
                onPressed: () => _record(shares, _method),
                icon: const Icon(Icons.handshake_outlined),
                label: Text(l10n.settleWithAction(shares.length)),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => ref.read(textSharerProvider)(message),
                icon: const Icon(Icons.ios_share),
                label: Text(l10n.shareAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

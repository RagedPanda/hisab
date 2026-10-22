import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../data/repositories/groups_repository.dart';
import '../../domain/split/group_timeline.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'expense_list_model.dart';
import 'record_payment_sheet.dart';

/// How one group's Expenses tab is being viewed. In memory only: a filter
/// the user picked (null = the default for the group) and whether rows
/// before the settled-up point are shown.
class ExpenseListView {
  const ExpenseListView({this.filter, this.showOlder = false});
  final ExpenseFilter? filter;
  final bool showOlder;
}

class ExpenseListViews extends Notifier<Map<String, ExpenseListView>> {
  @override
  Map<String, ExpenseListView> build() => const {};

  void setFilter(String groupId, ExpenseFilter filter) =>
      state = {...state, groupId: ExpenseListView(filter: filter, showOlder: state[groupId]?.showOlder ?? false)};

  void toggleOlder(String groupId) {
    final current = state[groupId] ?? const ExpenseListView();
    state = {...state, groupId: ExpenseListView(filter: current.filter, showOlder: !current.showOlder)};
  }
}

final expenseListViewsProvider = NotifierProvider<ExpenseListViews, Map<String, ExpenseListView>>(ExpenseListViews.new);

/// The group's expenses and payments, newest first, as seen by me.
class GroupExpensesTab extends ConsumerWidget {
  const GroupExpensesTab({
    super.key,
    required this.groupId,
    required this.entries,
    required this.settlements,
    required this.timelineByEntryId,
    required this.settledUpTo,
    required this.myMemberId,
    required this.nameOf,
    required this.categoryById,
    required this.symbol,
    required this.openPayment,
  });
  final String groupId;
  final List<GroupEntry> entries;
  final List<Settlement> settlements;
  final Map<String, TimelineExpense> timelineByEntryId;
  final DateTime? settledUpTo;
  final String? myMemberId;
  final String Function(String) nameOf;
  final Map<String, Category> categoryById;
  final String symbol;
  final void Function(Settlement) openPayment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (entries.isEmpty && settlements.isEmpty) {
      return EmptyState(icon: Icons.receipt_long_outlined, title: l10n.noGroupExpensesTitle, message: l10n.noGroupExpensesBody);
    }
    final view = ref.watch(expenseListViewsProvider)[groupId] ?? const ExpenseListView();
    final filter = view.filter ?? defaultExpenseFilter(settledUpTo);
    final rows = <LedgerRow<Object>>[
      for (final (entry, _, _) in entries)
        if (timelineByEntryId[entry.id] case final timeline?)
          LedgerRow(source: (entry, timeline), occurredAt: entry.occurredAt, totalMinor: entry.amountMinor, involvesMe: expenseInvolves(myMemberId, timeline)),
      for (final settlement in settlements)
        LedgerRow(
          source: settlement,
          occurredAt: settlement.occurredAt,
          totalMinor: 0,
          isPayment: true,
          involvesMe: paymentInvolves(myMemberId, TimelinePayment(occurredAt: settlement.occurredAt, fromMemberId: settlement.fromMemberId, toMemberId: settlement.toMemberId, amountMinor: settlement.amountMinor)),
        ),
    ];
    final items = buildExpenseList(rows: rows, filter: filter, settledUpTo: settledUpTo, showOlder: view.showOlder);
    final notifier = ref.read(expenseListViewsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final option in [ExpenseFilter.all, ExpenseFilter.mine, if (settledUpTo != null) ExpenseFilter.unsettled])
              ChoiceChip(
                label: Text(switch (option) { ExpenseFilter.all => l10n.all, ExpenseFilter.mine => l10n.filterMine, ExpenseFilter.unsettled => l10n.filterUnsettled }),
                selected: filter == option,
                onSelected: (_) => notifier.setFilter(groupId, option),
              ),
          ],
        ),
        if (items.isEmpty) _Notice(text: l10n.nothingInvolvingYou),
        if (items.firstOrNull is SettledDividerItem) _Notice(text: l10n.expensesAllSettled),
        ..._sections(context, items, onToggleOlder: () => notifier.toggleOlder(groupId)),
      ],
    );
  }

  /// Month headers and dividers stand alone; consecutive rows share a card.
  List<Widget> _sections(BuildContext context, List<ExpenseListItem<Object>> items, {required VoidCallback onToggleOlder}) {
    final widgets = <Widget>[];
    var cardRows = <Widget>[];
    void flush() {
      if (cardRows.isEmpty) return;
      widgets.add(Card(child: Column(children: cardRows)));
      cardRows = [];
    }

    for (final item in items) {
      switch (item) {
        case MonthHeaderItem(:final month, :final totalMinor):
          flush();
          widgets.add(_MonthHeader(month: month, totalMinor: totalMinor, symbol: symbol));
        case SettledDividerItem(:final day, :final olderCount, :final collapsible, :final expanded):
          flush();
          widgets.add(_SettledDivider(day: day, olderCount: olderCount, collapsible: collapsible, expanded: expanded, onToggle: onToggleOlder));
        case RowItem(:final row):
          cardRows.add(switch (row.source) {
            (final Entry entry, final TimelineExpense timeline) => _expenseTile(context, entry, timeline),
            final Settlement settlement => _paymentTile(context, settlement),
            _ => const SizedBox.shrink(),
          });
      }
    }
    flush();
    return widgets;
  }

  Widget _expenseTile(BuildContext context, Entry entry, TimelineExpense timeline) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final category = categoryById[entry.categoryId];
    final payers = timeline.paidMinor.keys.map(nameOf).toList();
    final effect = expenseEffectFor(myMemberId, timeline);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final (label, color) = switch (effect.kind) {
      ExpenseEffectKind.lent => (l10n.youLent, kIncomeColor),
      ExpenseEffectKind.borrowed => (l10n.youBorrowed, kExpenseColor),
      ExpenseEffectKind.paidOwnShare => (l10n.youPaid, null),
      ExpenseEffectKind.notInvolved => (l10n.notInvolved, muted),
    };
    return ListTile(
      leading: IconBadge(icon: category?.icon, color: category?.color ?? 0xFF607D8B),
      title: Text(entry.note.isNotEmpty ? entry.note : (entry.payee ?? category?.displayName(context) ?? l10n.kindExpense), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${formatRowDate(entry.occurredAt, locale: locale)} · ${l10n.payerPaidAmount(payers.join(', '), formatMinor(entry.amountMinor, symbol: symbol))}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _Effect(label: label, amount: effect.kind == ExpenseEffectKind.notInvolved ? null : formatMinor(effect.amountMinor, symbol: symbol), color: color),
      onTap: () => context.push('/entry?id=${entry.id}'),
    );
  }

  Widget _paymentTile(BuildContext context, Settlement settlement) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final fromMe = settlement.fromMemberId == myMemberId;
    final toMe = settlement.toMemberId == myMemberId;
    final title = fromMe
        ? l10n.youPaidName(nameOf(settlement.toMemberId))
        : toMe
            ? l10n.namePaidYou(nameOf(settlement.fromMemberId))
            : l10n.settlementLine(nameOf(settlement.fromMemberId), nameOf(settlement.toMemberId));
    final (label, color) = fromMe ? (l10n.youPaid, null) : (toMe ? (l10n.youReceived, kIncomeColor) : (l10n.notInvolved, muted));
    return ListTile(
      leading: const IconBadge(icon: 'handshake', color: 0xFF2E9E6B),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [formatRowDate(settlement.occurredAt, locale: locale), paymentMethodLabel(settlement.method, l10n), if (settlement.note.isNotEmpty) settlement.note].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _Effect(label: label, amount: formatMinor(settlement.amountMinor, symbol: symbol), color: color),
      onTap: () => openPayment(settlement),
    );
  }
}

/// What a row meant for me: a small coloured label over the amount.
class _Effect extends StatelessWidget {
  const _Effect({required this.label, required this.amount, required this.color});
  final String label;
  final String? amount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: theme.textTheme.labelSmall!.copyWith(color: color ?? theme.colorScheme.onSurfaceVariant)),
        if (amount != null) Text(amount!, style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600, color: color).tabular),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, required this.totalMinor, required this.symbol});
  final DateTime month;
  final int totalMinor;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final style = theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Row(
        children: [
          Expanded(child: Text(formatMonthYear(month, locale: locale), style: style)),
          if (totalMinor > 0) Text(formatMinor(totalMinor, symbol: symbol), style: style.tabular),
        ],
      ),
    );
  }
}

/// "Settled up to 14 Oct", with a show/hide toggle under the Unsettled filter.
class _SettledDivider extends StatelessWidget {
  const _SettledDivider({required this.day, required this.olderCount, required this.collapsible, required this.expanded, required this.onToggle});
  final DateTime day;
  final int olderCount;
  final bool collapsible;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: kIncomeColor),
                    const SizedBox(width: 6),
                    Text(l10n.settledUpTo(formatRowDate(day, locale: locale)), style: theme.textTheme.labelLarge!.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          if (collapsible)
            TextButton.icon(
              onPressed: onToggle,
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              label: Text(expanded ? l10n.hideOlderRows : l10n.showOlderRows(olderCount)),
            ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}

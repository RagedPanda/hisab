import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/money.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../data/repositories/groups_repository.dart';
import '../../domain/recurring/repeat_draft.dart';
import '../../domain/split/group_recurring.dart';
import '../../domain/split/group_settings.dart';
import '../../domain/split/group_timeline.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../recurring/recurring_list_model.dart';
import '../recurring/recurring_screen.dart';
import '../shell/widgets/common.dart';
import 'expense_list_model.dart';
import 'member_display.dart';
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

/// The group's repeating expenses (rent, maid, wifi) that have not ended,
/// grouped waiting, active, paused like the personal Recurring screen.
final groupRecurringItemsProvider = StreamProvider.family<List<RecurringListItem>, String>((ref, groupId) {
  final monthStartDay = ref.watch(settingsProvider.select((settings) => settings.monthStartDay));
  return ref.watch(recurringRepositoryProvider).watchViews(groupId: groupId).map((views) => [
        for (final item in recurringListItems(views, now: DateTime.now(), monthStartDay: monthStartDay))
          if (item.section != RecurringSection.ended) item,
      ]);
});

/// The group's expenses and payments, newest first, as seen by me.
class GroupExpensesTab extends ConsumerWidget {
  const GroupExpensesTab({
    super.key,
    required this.groupId,
    this.groupType = GroupType.other,
    this.notes = '',
    required this.entries,
    required this.settlements,
    required this.timelineByEntryId,
    required this.settledUpTo,
    required this.myMemberId,
    required this.activeMemberIds,
    required this.nameOf,
    required this.categoryById,
    required this.moneyFormat,
    required this.openPayment,
  });
  final String groupId;

  /// Picks the empty-state wording.
  final GroupType groupType;

  /// Group notes from settings, shown as a card on top when not empty.
  final String notes;
  final List<GroupEntry> entries;
  final List<Settlement> settlements;
  final Map<String, TimelineExpense> timelineByEntryId;
  final DateTime? settledUpTo;
  final String? myMemberId;

  /// Members still in the group, for each repeating rule's "your share".
  final Set<String> activeMemberIds;
  final String Function(String) nameOf;
  final Map<String, Category> categoryById;
  final MoneyFormat moneyFormat;
  final void Function(Settlement) openPayment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final repeating = ref.watch(groupRecurringItemsProvider(groupId)).value ?? const <RecurringListItem>[];
    final notesCard = notes.trim().isEmpty ? null : _NotesCard(notes: notes.trim(), onTap: () => context.push('/groups/$groupId/settings'));
    if (entries.isEmpty && settlements.isEmpty && repeating.isEmpty) {
      final empty = EmptyState(icon: Icons.receipt_long_outlined, title: l10n.noGroupExpensesTitle, message: _emptyMessage(l10n));
      if (notesCard == null) return empty;
      return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [notesCard, empty]);
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
        ?notesCard,
        if (repeating.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Text(l10n.groupRecurringUpcoming, style: Theme.of(context).textTheme.titleSmall),
          ),
          for (final (index, item) in repeating.indexed) ...[
            // Section labels (Paused, Waiting) as on the personal Recurring screen;
            // a plain list of active rules needs none.
            if (index == 0 ? item.section != RecurringSection.active : repeating[index - 1].section != item.section)
              SectionHeader(recurringSectionLabel(l10n, item.section), padding: const EdgeInsets.fromLTRB(4, 4, 4, 4)),
            RecurringRuleCard(
              key: ValueKey('group.recurring.${item.view.rule.id}'),
              item: item,
              moneyFormat: moneyFormat,
              yourShareMinor: myShareOfGroupRule(item.view.rule.groupSplit, amountMinor: item.view.rule.amountMinor, activeMemberIds: activeMemberIds, myMemberId: myMemberId),
            ),
          ],
          const SizedBox(height: 8),
        ],
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

  String _emptyMessage(AppLocalizations l10n) => switch (groupType) {
        GroupType.trip => l10n.groupEmptyTrip,
        GroupType.home => l10n.groupEmptyHome,
        GroupType.couple => l10n.groupEmptyCouple,
        GroupType.other => l10n.noGroupExpensesBody,
      };

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
          widgets.add(_MonthHeader(month: month, totalMinor: totalMinor, moneyFormat: moneyFormat));
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
    final payers = payerNamesLine(l10n, timeline.paidMinor.keys.toList(), myMemberId: myMemberId, nameOf: nameOf);
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
        '${formatRowDate(entry.occurredAt, locale: locale)} · ${l10n.payerPaidAmount(payers, formatMinor(entry.amountMinor, format: moneyFormat))}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _Effect(label: label, amount: effect.kind == ExpenseEffectKind.notInvolved ? null : formatMinor(effect.amountMinor, format: moneyFormat), color: color),
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
      leading: const IconBadge(icon: 'handshake', color: 0xFF10B981),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [formatRowDate(settlement.occurredAt, locale: locale), paymentMethodLabel(settlement.method, l10n), if (settlement.note.isNotEmpty) settlement.note].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _Effect(label: label, amount: formatMinor(settlement.amountMinor, format: moneyFormat), color: color),
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
  const _MonthHeader({required this.month, required this.totalMinor, required this.moneyFormat});
  final DateTime month;
  final int totalMinor;
  final MoneyFormat moneyFormat;

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
          if (totalMinor > 0) Text(formatMinor(totalMinor, format: moneyFormat), style: style.tabular),
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

/// The group's notes from settings; tapping opens settings to edit them.
class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes, required this.onTap});
  final String notes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.sticky_note_2_outlined),
        title: Text(context.l10n.groupSettingsNotes, style: theme.textTheme.labelLarge),
        subtitle: Text(notes, maxLines: 4, overflow: TextOverflow.ellipsis),
        onTap: onTap,
      ),
    );
  }
}

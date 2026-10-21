import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../data/repositories/entries_repository.dart';
import '../../domain/accounts/account_label.dart';
import '../../l10n/category_names.dart';
import '../../l10n/l10n.dart';
import '../accounts/accounts_screen.dart';
import '../budgets/budget_views.dart';
import '../shell/widgets/budget_row.dart';
import '../shell/widgets/common.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final totals = ref.watch(monthTotalsProvider).value ?? (expense: 0, income: 0);
    final pending = ref.watch(pendingSmsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          if (pending.isNotEmpty)
            IconButton(
              tooltip: l10n.smsToReview(pending.length),
              onPressed: () => context.push('/sms'),
              icon: Badge(label: Text('${pending.length}'), child: const Icon(Icons.sms_outlined)),
            ),
          const MonthSwitcher(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          _SummaryCard(expense: totals.expense, income: totals.income, symbol: settings.currencySymbol),
          const SizedBox(height: 16),
          const _AccountsStrip(),
          const _SpendingByCategory(),
          const _BudgetsOverview(),
          const _RecentEntries(),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.expense, required this.income, required this.symbol});
  final int expense;
  final int income;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final net = income - expense;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [scheme.primary, scheme.primary.withValues(alpha: 0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.spentThisMonth, style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.85))),
          const SizedBox(height: 4),
          Text(formatMinor(expense, symbol: symbol), style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w800).tabular),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(label: context.l10n.income, value: formatMinor(income, symbol: symbol, showDecimals: false), color: scheme.onPrimary),
              const SizedBox(width: 24),
              _Stat(label: net >= 0 ? context.l10n.saved : context.l10n.overspent, value: formatMinor(net.abs(), symbol: symbol, showDecimals: false), color: scheme.onPrimary),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16, fontFeatures: kTabularFigures)),
        ],
      );
}

class _AccountsStrip extends ConsumerWidget {
  const _AccountsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final total = accounts.where((a) => a.includeInTotal).fold(0, (sum, a) => sum + a.balanceMinor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          context.l10n.balances,
          trailing: TextButton(onPressed: () => context.push('/accounts'), child: Text(formatMinor(total, symbol: symbol, showDecimals: false))),
        ),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: accounts.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == accounts.length) {
                return _AddAccountChip(onTap: () => context.push('/accounts'));
              }
              return _AccountCard(account: accounts[index], symbol: symbol);
            },
          ),
        ),
      ],
    );
  }
}

/// One balance card: name on one line, the ••mask on its own line, credit
/// cards as "Due", and a prompt to set an opening balance when cash goes
/// negative (P2-7, P2-17).
class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.account, required this.symbol});
  final Account account;
  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final label = splitAccountLabel(account.name);
    final isCard = account.type == 'card';
    final needsOpeningBalance = account.type == 'cash' && account.balanceMinor < 0;
    final balanceText = isCard
        ? l10n.cardDue(formatMinor(account.balanceMinor.abs(), symbol: symbol, showDecimals: false))
        : formatMinor(account.balanceMinor, symbol: symbol, showDecimals: false);
    final balanceColor = isCard || needsOpeningBalance ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface;
    return InkWell(
      onTap: () => needsOpeningBalance ? showAccountForm(context, ref, existing: account, focusBalance: true) : context.push('/accounts'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 148,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              IconBadge(icon: _accountIcon(account.type), color: account.color, size: 26),
              const SizedBox(width: 8),
              Expanded(child: Text(label.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelLarge)),
            ]),
            if (label.mask != null) Text(label.mask!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const Spacer(),
            Text(balanceText, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: balanceColor).tabular),
            if (needsOpeningBalance)
              Text(l10n.setOpeningBalance, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}

String _accountIcon(String type) => switch (type) {
      'bank' => 'account_balance',
      'card' => 'credit_card',
      'wallet' => 'account_balance_wallet',
      _ => 'payments',
    };

class _AddAccountChip extends StatelessWidget {
  const _AddAccountChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 92,
          decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.add), Text(context.l10n.account, style: const TextStyle(fontSize: 12))]),
        ),
      );
}

class _SpendingByCategory extends ConsumerWidget {
  const _SpendingByCategory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(monthCategoryTotalsProvider).value ?? const {};
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final symbol = ref.watch(settingsProvider).currencySymbol;
    if (totals.isEmpty) return const SizedBox.shrink();
    final byId = {for (final c in categories) c.id: c};
    // Roll children up into their parents so the chart stays readable.
    final rolled = <String, int>{};
    for (final entry in totals.entries) {
      final category = byId[entry.key];
      final key = category?.parentId ?? category?.id ?? '';
      rolled.update(key, (v) => v + entry.value, ifAbsent: () => entry.value);
    }
    final sorted = rolled.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (sum, e) => sum + e.value);
    final top = sorted.take(6).toList();
    final restValue = sorted.skip(6).fold(0, (sum, e) => sum + e.value);
    final slices = [
      for (final e in top) (name: byId[e.key]?.displayName(context) ?? context.l10n.uncategorised, color: Color(byId[e.key]?.color ?? 0xFF9E9E9E), value: e.value),
      if (restValue > 0) (name: context.l10n.others, color: const Color(0xFF9E9E9E), value: restValue),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(context.l10n.spendingByCategory),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 34,
                        sections: [
                          for (final slice in slices)
                            PieChartSectionData(value: slice.value.toDouble(), color: slice.color, radius: 24, showTitle: false),
                        ],
                      )),
                      Text(
                        formatMinor(total, symbol: symbol, showDecimals: false, compact: true),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700).tabular,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      for (final slice in slices)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(flex: 3, child: Text(slice.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)),
                            SizedBox(
                              width: 44,
                              child: Text('${(slice.value * 100 / total).round()}%', textAlign: TextAlign.end, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600).tabular),
                            ),
                            const SizedBox(width: 8),
                            Text(formatMinor(slice.value, symbol: symbol, showDecimals: false), style: Theme.of(context).textTheme.bodySmall?.tabular),
                          ]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetsOverview extends ConsumerWidget {
  const _BudgetsOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final views = ref.watch(budgetViewsProvider);
    final symbol = ref.watch(settingsProvider).currencySymbol;
    if (views.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(context.l10n.budgets, trailing: TextButton(onPressed: () => context.push('/budgets'), child: Text(context.l10n.manage))),
        Card(
          child: Column(
            children: [
              for (final view in views) BudgetRow(view: view, symbol: symbol, onTap: () => context.push('/budgets')),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentEntries extends ConsumerWidget {
  const _RecentEntries();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(monthEntriesProvider);
    final recent = (async.value ?? const <EntryDetails>[]).take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(context.l10n.recent, trailing: TextButton(onPressed: () => context.go('/transactions'), child: Text(context.l10n.seeAll))),
        // Never flash the empty state before the first stream value arrives (P2-23).
        if (!async.hasValue)
          const LoadingPlaceholder(height: 180)
        else if (recent.isEmpty)
          EmptyState(icon: Icons.receipt_long_outlined, title: context.l10n.noEntriesThisMonthTitle, message: context.l10n.noEntriesThisMonthBody)
        else
          Card(
            child: Column(
              children: [
                for (final details in recent)
                  EntryTile(details: details, showDate: true, onTap: () => context.push('/entry?id=${details.entry.id}')),
              ],
            ),
          ),
      ],
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../domain/budget/budget_math.dart';
import '../shell/widgets/common.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final totals = ref.watch(monthTotalsProvider).value ?? (expense: 0, income: 0);
    final pending = ref.watch(pendingSmsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hisab'),
        actions: [
          if (pending.isNotEmpty)
            IconButton(
              tooltip: '${pending.length} SMS to review',
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
          Text('Spent this month', style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.85))),
          const SizedBox(height: 4),
          Text(formatMinor(expense, symbol: symbol), style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(label: 'Income', value: formatMinor(income, symbol: symbol, showDecimals: false), color: scheme.onPrimary),
              const SizedBox(width: 24),
              _Stat(label: net >= 0 ? 'Saved' : 'Overspent', value: formatMinor(net.abs(), symbol: symbol, showDecimals: false), color: scheme.onPrimary),
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
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
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
          'Balances',
          trailing: TextButton(onPressed: () => context.push('/accounts'), child: Text(formatMinor(total, symbol: symbol, showDecimals: false))),
        ),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: accounts.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == accounts.length) {
                return _AddAccountChip(onTap: () => context.push('/accounts'));
              }
              final account = accounts[index];
              return Container(
                width: 150,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      IconBadge(icon: _accountIcon(account.type), color: account.color, size: 26),
                      const SizedBox(width: 8),
                      Expanded(child: Text(account.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge)),
                    ]),
                    Text(formatMinor(account.balanceMinor, symbol: symbol, showDecimals: false), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add), Text('Account', style: TextStyle(fontSize: 12))]),
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
      for (final e in top) (name: byId[e.key]?.name ?? 'Uncategorised', color: Color(byId[e.key]?.color ?? 0xFF9E9E9E), value: e.value),
      if (restValue > 0) (name: 'Others', color: const Color(0xFF9E9E9E), value: restValue),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Spending by category'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: PieChart(PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 34,
                    sections: [
                      for (final slice in slices)
                        PieChartSectionData(value: slice.value.toDouble(), color: slice.color, radius: 24, showTitle: false),
                    ],
                  )),
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
                            Expanded(child: Text(slice.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)),
                            Text('${(slice.value * 100 / total).round()}%', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Text(formatMinor(slice.value, symbol: symbol, showDecimals: false), style: Theme.of(context).textTheme.bodySmall),
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
    final budgets = ref.watch(budgetsProvider).value ?? const <Budget>[];
    final totals = ref.watch(monthCategoryTotalsProvider).value ?? const {};
    final monthTotals = ref.watch(monthTotalsProvider).value;
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final range = ref.watch(selectedRangeProvider);
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final monthly = budgets.where((b) => b.period == 'month').toList();
    if (monthly.isEmpty) return const SizedBox.shrink();
    final byId = {for (final c in categories) c.id: c};
    final elapsed = elapsedFraction(start: range.start, end: range.end, now: DateTime.now());
    int spentFor(String? categoryId) {
      if (categoryId == null) return monthTotals?.expense ?? 0;
      var sum = totals[categoryId] ?? 0;
      for (final child in categories.where((c) => c.parentId == categoryId)) {
        sum += totals[child.id] ?? 0;
      }
      return sum;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('Budgets', trailing: TextButton(onPressed: () => context.push('/budgets'), child: const Text('Manage'))),
        Card(
          child: Column(
            children: [
              for (final budget in monthly)
                _BudgetRow(
                  name: budget.categoryId == null ? 'Overall' : byId[budget.categoryId]?.name ?? 'Category',
                  icon: byId[budget.categoryId]?.icon,
                  color: byId[budget.categoryId]?.color ?? kSeedColor.toARGB32(),
                  progress: BudgetProgress(limitMinor: budget.amountMinor, spentMinor: spentFor(budget.categoryId), elapsedFraction: elapsed),
                  symbol: symbol,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.name, required this.icon, required this.color, required this.progress, required this.symbol});
  final String name;
  final String? icon;
  final int color;
  final BudgetProgress progress;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final barColor = progress.isOver ? kExpenseColor : (progress.isAheadOfPace ? kAccentColor : Color(color));
    return ListTile(
      leading: IconBadge(icon: icon ?? 'savings', color: color),
      title: Text(name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress.usedFraction.clamp(0, 1), color: barColor, backgroundColor: barColor.withValues(alpha: 0.15), minHeight: 6),
          ),
          const SizedBox(height: 4),
          Text(
            progress.isOver
                ? 'Over by ${formatMinor(-progress.remainingMinor, symbol: symbol, showDecimals: false)}'
                : '${formatMinor(progress.remainingMinor, symbol: symbol, showDecimals: false)} left of ${formatMinor(progress.limitMinor, symbol: symbol, showDecimals: false)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RecentEntries extends ConsumerWidget {
  const _RecentEntries();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(monthEntriesProvider).value ?? const [];
    final recent = entries.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('Recent', trailing: TextButton(onPressed: () => context.go('/transactions'), child: const Text('See all'))),
        if (recent.isEmpty)
          const EmptyState(icon: Icons.receipt_long_outlined, title: 'No entries this month', message: 'Tap + to add your first expense, or turn on SMS reading in Settings.')
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

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/db/database.dart';
import '../../domain/split/group_totals.dart';
import '../../domain/stats/spend_series.dart';
import '../../l10n/l10n.dart';
import '../dashboard/dashboard_providers.dart';
import '../dashboard/widgets/category_donut.dart';
import '../dashboard/widgets/dashboard_card.dart';
import '../dashboard/widgets/trend_card.dart' show kTrendChartHeight;
import '../shell/widgets/common.dart';
import 'group_detail_screen.dart';
import 'member_display.dart';

/// Key of the Totals card on the Balances tab.
const kGroupTotalsCardKey = ValueKey('group-totals-card');

/// What the group spent in a month or all time, my paid and share, and
/// breakdowns by category and by member.
class GroupTotalsScreen extends ConsumerStatefulWidget {
  const GroupTotalsScreen({super.key, required this.groupId});
  final String groupId;

  @override
  ConsumerState<GroupTotalsScreen> createState() => _GroupTotalsScreenState();
}

class _GroupTotalsScreenState extends ConsumerState<GroupTotalsScreen> {
  /// First day of the selected month; null for all time.
  DateTime? _month;
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final detail = ref.watch(groupDetailProvider(widget.groupId)).value;
    final categories = ref.watch(allCategoriesProvider).value ?? const <Category>[];
    final symbol = ref.watch(settingsProvider).currencySymbol;
    if (detail == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.groupTotalsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final locale = Localizations.localeOf(context).toString();
    final expenses = detail.totalsExpenses;
    final months = monthsWithExpenses(expenses);
    final month = months.contains(_month) ? _month : null;
    final range = month == null ? null : monthRange(month);
    final totals = computeGroupTotals(expenses: expenses, payments: detail.totalsPayments, myMemberId: detail.me?.id, range: range);
    final periodLabel = range == null ? l10n.allTime : formatMonthLabel(range, locale: locale);
    final memberById = {for (final member in detail.allMembers) member.id: member};
    String nameOf(String id) {
      final member = memberById[id];
      return member == null ? l10n.unknown : memberShortName(l10n, member);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupTotalsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
        children: [
          ChipRow(
            children: [
              ChoiceChip(label: Text(l10n.groupTotalsAllTime), selected: month == null, onSelected: (_) => setState(() => _month = null)),
              for (final option in months)
                ChoiceChip(
                  label: Text(formatMonthLabel(monthRange(option), locale: locale)),
                  selected: option == month,
                  onSelected: (_) => setState(() => _month = option),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: GroupTotalsSummary(totals: totals, symbol: symbol, showMine: detail.me != null),
          ),
          if (totals.expenseCount == 0)
            Padding(
              padding: const EdgeInsets.all(16),
              child: EmptyState(icon: Icons.insights_outlined, title: l10n.groupTotalsEmpty),
            )
          else ...[
            SectionHeader(l10n.spendingByCategory),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CategoryDonut(
                    data: buildCategoryBreakdown(totals.byCategory, categories),
                    selectedId: _selectedCategoryId,
                    symbol: symbol,
                    totalCaption: periodLabel,
                    onSliceTap: (share) => setState(() => _selectedCategoryId = _selectedCategoryId == share.categoryId ? null : share.categoryId),
                  ),
                ),
              ),
            ),
            SectionHeader(l10n.groupTotalsByMember),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: MemberSpendChart(rows: totals.byMember, nameOf: nameOf, symbol: symbol),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The group's total and my total share as the two headline figures, then
/// what I paid, payments I made or received, and how the period moved my
/// balance. Used on the totals page and, for all time, on the Balances tab.
class GroupTotalsSummary extends StatelessWidget {
  const GroupTotalsSummary({super.key, required this.totals, required this.symbol, required this.showMine, this.onTap});
  final GroupTotals totals;
  final String symbol;

  /// False when the group has no "me" member, so my figures mean nothing.
  final bool showMine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final net = totals.myNetChangeMinor;
    final netColor = net > 0
        ? kIncomeColor
        : net < 0
        ? kExpenseColor
        : theme.colorScheme.onSurfaceVariant;
    final netText = '${net > 0 ? '+' : ''}${formatMinor(net, symbol: symbol)}';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Headline(
                      label: l10n.groupTotalsTotalSpent,
                      value: formatMinor(totals.totalSpentMinor, symbol: symbol),
                    ),
                  ),
                  if (showMine) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _Headline(
                        label: l10n.groupTotalsYourShare,
                        value: formatMinor(totals.myShareMinor, symbol: symbol),
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                  if (onTap != null) Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 4),
              Text(l10n.groupTotalsExpenseCount(totals.expenseCount), style: captionStyle(context)),
              if (showMine) ...[
                const Divider(height: 24),
                _FigureRow(
                  label: l10n.groupTotalsYouPaid,
                  value: formatMinor(totals.myPaidMinor, symbol: symbol),
                ),
                if (totals.myPaymentsSentMinor != 0)
                  _FigureRow(
                    label: l10n.groupTotalsPaymentsMade,
                    value: formatMinor(totals.myPaymentsSentMinor, symbol: symbol),
                  ),
                if (totals.myPaymentsReceivedMinor != 0)
                  _FigureRow(
                    label: l10n.groupTotalsPaymentsReceived,
                    value: formatMinor(totals.myPaymentsReceivedMinor, symbol: symbol),
                  ),
                _FigureRow(label: l10n.groupTotalsNetChange, value: netText, color: netColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A caption over a large amount: the group total and my share.
class _Headline extends StatelessWidget {
  const _Headline({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: color).tabular,
          ),
        ),
      ],
    );
  }
}

class _FigureRow extends StatelessWidget {
  const _FigureRow({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: color).tabular,
          ),
        ],
      ),
    );
  }
}

/// Paid and share side by side for every member, as grouped bars with a
/// legend and the exact figures listed underneath.
class MemberSpendChart extends StatelessWidget {
  const MemberSpendChart({super.key, required this.rows, required this.nameOf, required this.symbol});
  final List<MemberSpend> rows;
  final String Function(String memberId) nameOf;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final paidColor = scheme.primary;
    const shareColor = kAccentColor;
    final largest = rows.fold(0, (maximum, row) => max(maximum, max(row.paidMinor, row.shareMinor)));
    final maxY = niceCeiling(largest / 100);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);
    final rodWidth = rows.length > 5 ? 8.0 : 14.0;
    String amount(int minor) => formatMinor(minor, symbol: symbol, showDecimals: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          children: [
            _LegendDot(color: paidColor, label: l10n.groupTotalsPaid),
            _LegendDot(color: shareColor, label: l10n.groupTotalsShare),
          ],
        ),
        const SizedBox(height: 12),
        ExcludeSemantics(
          child: SizedBox(
            height: kTrendChartHeight,
            child: BarChart(
              duration: chartAnimation(context),
              curve: kChartCurve,
              BarChartData(
                minY: 0,
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 2,
                  getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: maxY / 2,
                      getTitlesWidget: (value, meta) => Text(axisAmountLabel(value, symbol: symbol), style: labelStyle),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: SizedBox(
                          width: 56,
                          child: Text(nameOf(rows[value.round()].memberId), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: labelStyle),
                        ),
                      ),
                    ),
                  ),
                ),
                barGroups: [
                  for (var index = 0; index < rows.length; index++)
                    BarChartGroupData(
                      x: index,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(toY: rows[index].paidMinor / 100, width: rodWidth, color: paidColor, borderRadius: BorderRadius.circular(4)),
                        BarChartRodData(toY: rows[index].shareMinor / 100, width: rodWidth, color: shareColor, borderRadius: BorderRadius.circular(4)),
                      ],
                    ),
                ],
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => scheme.surfaceContainerHighest,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipItem: (group, _, rod, rodIndex) {
                      final row = rows[group.x];
                      return BarTooltipItem(
                        '${rodIndex == 0 ? l10n.groupTotalsPaid : l10n.groupTotalsShare} ${amount(rodIndex == 0 ? row.paidMinor : row.shareMinor)}',
                        theme.textTheme.labelMedium!.copyWith(color: scheme.onSurface).tabular,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final row in rows)
          Semantics(
            label: l10n.groupTotalsMemberRow(nameOf(row.memberId), amount(row.paidMinor), amount(row.shareMinor)),
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(nameOf(row.memberId), maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 72),
                    child: Text(
                      amount(row.paidMinor),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodyMedium?.copyWith(color: paidColor).tabular,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 72),
                    child: Text(amount(row.shareMinor), textAlign: TextAlign.end, style: theme.textTheme.bodyMedium?.tabular),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}

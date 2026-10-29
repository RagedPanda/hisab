import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/dates.dart';
import '../../../core/format.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../domain/stats/spend_series.dart';
import '../../../domain/stats/trend.dart';
import '../../../l10n/l10n.dart';
import '../dashboard_keys.dart';
import '../dashboard_providers.dart';
import 'dashboard_card.dart';

enum TrendMode { daily, monthly }

const double kTrendChartHeight = 160;

/// Cumulative spend for the month against last month's curve, or the last
/// six months as bars. Hidden until the window holds a few expenses.
class TrendCard extends ConsumerStatefulWidget {
  const TrendCard({super.key});

  @override
  ConsumerState<TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends ConsumerState<TrendCard> {
  TrendMode _mode = TrendMode.daily;

  @override
  Widget build(BuildContext context) {
    final trend = ref.watch(trendDataProvider);
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final l10n = context.l10n;
    return AsyncCard(
      value: trend,
      skeletonHeight: 200,
      builder: (data) {
        if (!data.hasEnoughData) return const SizedBox.shrink();
        return DashboardSection(
          title: l10n.spendingTrend,
          trailing: _ModeSwitch(mode: _mode, onChanged: (mode) => setState(() => _mode = mode)),
          child: DashboardCard(
            key: kTrendCardKey,
            child: SizedBox(
              height: kTrendChartHeight,
              child: _mode == TrendMode.daily
                  ? _DailyChart(data: data, moneyFormat: moneyFormat)
                  : MonthlyBars(months: data.months, moneyFormat: moneyFormat, onSelectMonth: (range) => ref.read(selectedMonthProvider.notifier).select(range.start)),
            ),
          ),
        );
      },
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onChanged});
  final TrendMode mode;
  final ValueChanged<TrendMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SegmentedButton<TrendMode>(
      segments: [
        ButtonSegment(value: TrendMode.daily, label: Text(l10n.trendDaily)),
        ButtonSegment(value: TrendMode.monthly, label: Text(l10n.trendMonthly)),
      ],
      selected: {mode},
      onSelectionChanged: (selection) => onChanged(selection.first),
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        textStyle: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

/// Cumulative rupees for each day index, as chart spots (x = day of month).
List<FlSpot> _cumulativeSpots(List<int> series) => [for (var day = 0; day < series.length; day++) FlSpot(day + 1.0, series[day] / 100)];

class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.data, required this.moneyFormat});
  final TrendData data;
  final MoneyFormat moneyFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    if (data.currentTotal == 0) return _EmptyTrend(message: l10n.trendEmpty);
    final maxY = niceCeiling(data.maxValue / 100);
    final labelDays = dayAxisLabels(data.daysInMonth).toSet();
    final labelStyle = theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);
    final previousMonth = DateFormat('MMM', locale).format(data.months[data.months.length - 2].range.start);
    final monthStart = data.months.last.range.start;
    return Semantics(
      label: l10n.trendSemantics(formatMinor(data.currentTotal, format: moneyFormat, showDecimals: false)),
      child: LineChart(
        duration: chartAnimation(context),
        curve: kChartCurve,
        LineChartData(
          minX: 1,
          maxX: data.daysInMonth.toDouble(),
          minY: 0,
          maxY: maxY,
          clipData: const FlClipData.all(),
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
                getTitlesWidget: (value, meta) => Text(axisAmountLabel(value, format: moneyFormat), style: labelStyle, textAlign: TextAlign.left),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) => labelDays.contains(value.round()) && value == value.roundToDouble()
                    ? Padding(padding: const EdgeInsets.only(top: 6), child: Text('${value.round()}', style: labelStyle))
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            verticalLines: [
              if (data.daysElapsed < data.daysInMonth)
                VerticalLine(x: data.daysElapsed.toDouble(), color: scheme.outlineVariant, strokeWidth: 1, dashArray: [2, 3]),
            ],
          ),
          lineBarsData: [
            if (data.hasPrevious)
              LineChartBarData(
                spots: _cumulativeSpots(data.previous),
                color: scheme.outline,
                barWidth: 1.5,
                dashArray: [4, 4],
                isCurved: false,
                dotData: const FlDotData(show: false),
              ),
            LineChartBarData(
              spots: _cumulativeSpots(data.current),
              color: scheme.primary,
              barWidth: 2,
              isCurved: false,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [scheme.primary.withValues(alpha: 0.18), scheme.primary.withValues(alpha: 0)],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => scheme.surfaceContainerHighest,
              tooltipBorderRadius: BorderRadius.circular(8),
              getTooltipItems: (spots) => [
                for (final spot in spots)
                  LineTooltipItem(
                    spot.bar.color == scheme.primary
                        ? '${formatRowDate(monthStart.add(Duration(days: spot.x.round() - 1)), locale: locale)} · ${formatMinor((spot.y * 100).round(), format: moneyFormat, showDecimals: false)}'
                        : '$previousMonth ${formatMinor((spot.y * 100).round(), format: moneyFormat, showDecimals: false)}',
                    theme.textTheme.labelMedium!.copyWith(color: scheme.onSurface).tabular,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One bar per month of [months], the last one highlighted as the current
/// period. Shared by the dashboard trend and project detail; a tap reports
/// the month's range through [onSelectMonth].
class MonthlyBars extends StatelessWidget {
  const MonthlyBars({super.key, required this.months, required this.moneyFormat, this.onSelectMonth});
  final List<PeriodTotal> months;
  final MoneyFormat moneyFormat;
  final ValueChanged<DateRange>? onSelectMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final maxExpense = months.fold(0, (maximum, month) => max(maximum, month.expense));
    final maxY = niceCeiling(maxExpense / 100);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);
    final current = months.length - 1;
    final yearSpan = months.isNotEmpty && months.first.range.start.year != months.last.range.start.year;
    String monthLabel(DateTime start) => DateFormat(yearSpan ? 'MMM yy' : 'MMM', locale).format(start);
    return Semantics(
      label: [for (final month in months) '${monthLabel(month.range.start)} ${formatMinor(month.expense, format: moneyFormat, showDecimals: false)}'].join(', '),
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
                getTitlesWidget: (value, meta) => Text(axisAmountLabel(value, format: moneyFormat), style: labelStyle, textAlign: TextAlign.left),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(monthLabel(months[value.round()].range.start), style: labelStyle),
                ),
              ),
            ),
          ),
          barGroups: [
            for (var index = 0; index < months.length; index++)
              BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: months[index].expense / 100,
                    width: months.length > 8 ? 10 : 18,
                    borderRadius: BorderRadius.circular(6),
                    color: index == current ? scheme.primaryContainer : scheme.primary,
                    borderSide: index == current ? BorderSide(color: scheme.primary, width: 1.5) : BorderSide.none,
                  ),
                ],
              ),
          ],
          barTouchData: BarTouchData(
            touchCallback: (event, response) {
              final group = response?.spot?.touchedBarGroup;
              if (event is FlTapUpEvent && group != null) onSelectMonth?.call(months[group.x].range);
            },
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => scheme.surfaceContainerHighest,
              tooltipBorderRadius: BorderRadius.circular(8),
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                formatMinor(months[group.x].expense, format: moneyFormat, showDecimals: false),
                theme.textTheme.labelMedium!.copyWith(color: scheme.onSurface).tabular,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Flat baseline with a caption for a month that has no spend yet.
class _EmptyTrend extends StatelessWidget {
  const _EmptyTrend({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(child: Center(child: Text(message, style: captionStyle(context), textAlign: TextAlign.center))),
        Container(height: 1, color: scheme.outlineVariant),
        const SizedBox(height: 22),
      ],
    );
  }
}

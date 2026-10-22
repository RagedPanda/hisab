import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../domain/stats/category_shares.dart';
import '../../../l10n/category_names.dart';
import '../../../l10n/l10n.dart';
import '../dashboard_keys.dart';
import '../dashboard_providers.dart';
import 'dashboard_card.dart';

/// Width from which the donut and legend sit side by side.
/// Donut diameter beside the legend, and the least width the legend needs
/// before the two sit side by side instead of stacking.
const double kDonutSideDiameter = 140;
const double kDonutStackedDiameter = 160;
const double kDonutLegendMinWidth = 200;
const double kDonutLegendGap = 16;

/// Whether a card [innerWidth] fits the donut and the legend in one row.
bool donutSideBySide(double innerWidth) => innerWidth - kDonutSideDiameter - kDonutLegendGap >= kDonutLegendMinWidth;

/// Where this month's spend went: top five categories plus "Others". Tapping
/// a slice or legend row narrows the Recent card; tapping it again opens the
/// Entries tab filtered to that category.
class CategoryDonutCard extends ConsumerWidget {
  const CategoryDonutCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdown = ref.watch(categoryBreakdownProvider);
    final selected = ref.watch(selectedDashboardCategoryProvider);
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final l10n = context.l10n;
    return AsyncCard(
      value: breakdown,
      skeletonHeight: 220,
      builder: (data) => DashboardSection(
        title: l10n.spendingByCategory,
        child: DashboardCard(
          key: kCategoryCardKey,
          child: data.shares.isEmpty
              ? EmptyDonut(symbol: symbol, message: l10n.categoriesEmpty)
              : CategoryDonut(
                  data: data,
                  selectedId: selected,
                  symbol: symbol,
                  totalCaption: l10n.thisMonth,
                  onSliceTap: (share) => _toggle(context, ref, selected, share),
                ),
        ),
      ),
    );
  }

  /// First tap narrows the Recent card; a second tap on the same slice opens
  /// the Entries tab filtered to that category.
  void _toggle(BuildContext context, WidgetRef ref, String? selectedId, CategoryShare share) {
    final notifier = ref.read(selectedDashboardCategoryProvider.notifier);
    if (selectedId == share.categoryId) {
      context.go(Uri(path: '/transactions', queryParameters: {'category': share.categoryId!}).toString());
    } else {
      notifier.set(share.categoryId);
    }
  }
}

/// A share resolved to what the chart draws.
class _Slice {
  const _Slice({required this.share, required this.name, required this.color});
  final CategoryShare share;
  final String name;
  final Color color;
}

List<_Slice> _slices(BuildContext context, CategoryBreakdown data) {
  final scheme = Theme.of(context).colorScheme;
  final fallback = chartFallbackColors(scheme);
  final l10n = context.l10n;
  return [
    for (var index = 0; index < data.shares.length; index++)
      () {
        final share = data.shares[index];
        final category = data.categoryOf(share);
        return _Slice(
          share: share,
          name: share.isOthers ? l10n.others : category?.displayName(context) ?? l10n.uncategorised,
          color: share.isOthers
              ? scheme.outline
              : category != null
                  ? Color(category.color)
                  : fallback[index % fallback.length],
        );
      }(),
  ];
}

/// Donut plus legend for any [CategoryBreakdown]: the dashboard month, a
/// project, or anything else that rolls up to categories. Selection is owned
/// by the caller; tapping a slice reports its share through [onSliceTap].
class CategoryDonut extends StatelessWidget {
  const CategoryDonut({super.key, required this.data, required this.selectedId, required this.symbol, required this.totalCaption, this.onSliceTap});
  final CategoryBreakdown data;
  final String? selectedId;
  final String symbol;

  /// Caption under the total when nothing is selected, e.g. "this month".
  final String totalCaption;
  final ValueChanged<CategoryShare>? onSliceTap;

  @override
  Widget build(BuildContext context) {
    final slices = _slices(context, data);
    final selectedIndex = selectedId == null ? null : slices.indexWhere((slice) => slice.share.categoryId == selectedId);
    final selected = selectedIndex == null || selectedIndex < 0 ? null : slices[selectedIndex];
    final l10n = context.l10n;
    void onTap(_Slice slice) {
      if (slice.share.isOthers || onSliceTap == null) return;
      HapticFeedback.selectionClick();
      onSliceTap!(slice.share);
    }

    Widget donut(bool sideBySide) => _Donut(
      slices: slices,
      selectedIndex: selected == null ? null : selectedIndex,
      size: sideBySide ? kDonutSideDiameter : kDonutStackedDiameter,
      centre: selected == null
          ? _Centre(amount: formatMinor(data.totalMinor, symbol: symbol, showDecimals: false), caption: totalCaption)
          : _Centre(amount: formatMinor(selected.share.minor, symbol: symbol, showDecimals: false), caption: selected.name),
      onTap: onTap,
    );
    final legend = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final slice in slices) _LegendRow(slice: slice, selected: slice == selected, symbol: symbol, onTap: () => onTap(slice)),
      ],
    );
    final semantics = '${l10n.spendingByCategory}: ${slices.map((slice) => '${slice.name} ${l10n.percentOf(sharePercent(slice.share))}').join(', ')}';
    return Semantics(
      label: semantics,
      child: LayoutBuilder(
        builder: (context, constraints) => donutSideBySide(constraints.maxWidth)
            ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [donut(true), const SizedBox(width: kDonutLegendGap), Expanded(child: legend)])
            : Column(children: [donut(false), const SizedBox(height: 12), legend]),
      ),
    );
  }
}

class _Donut extends StatelessWidget {
  const _Donut({required this.slices, required this.selectedIndex, required this.size, required this.centre, required this.onTap});
  final List<_Slice> slices;
  final int? selectedIndex;
  final double size;
  final Widget centre;
  final ValueChanged<_Slice> onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ExcludeSemantics(
              child: PieChart(
                duration: chartAnimation(context),
                curve: kChartCurve,
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 46,
                  startDegreeOffset: startDegreeForShare([for (final slice in slices) slice.share], selectedIndex),
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      final index = response?.touchedSection?.touchedSectionIndex;
                      if (event is FlTapUpEvent && index != null && index >= 0 && index < slices.length) onTap(slices[index]);
                    },
                  ),
                  sections: [
                    for (var index = 0; index < slices.length; index++)
                      PieChartSectionData(
                        value: slices[index].share.minor.toDouble(),
                        color: slices[index].color,
                        radius: index == selectedIndex ? 30 : 24,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
            ),
            centre,
          ],
        ),
      );
}

class _Centre extends StatelessWidget {
  const _Centre({required this.amount, required this.caption});
  final String amount;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 84,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(amount, maxLines: 1, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700).tabular)),
          Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.slice, required this.selected, required this.symbol, required this.onTap});
  final _Slice slice;
  final bool selected;
  final String symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return InkWell(
      onTap: slice.share.isOthers ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Text(slice.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium)),
            SizedBox(
              width: 44,
              child: Text(l10n.percentOf(sharePercent(slice.share)), textAlign: TextAlign.end, style: theme.textTheme.labelLarge?.tabular),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 72),
              child: Text(formatMinor(slice.share.minor, symbol: symbol, showDecimals: false), textAlign: TextAlign.end, style: theme.textTheme.bodyMedium?.tabular),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hollow ring with a zero total, for a breakdown with nothing in it yet.
class EmptyDonut extends StatelessWidget {
  const EmptyDonut({super.key, required this.symbol, required this.message});
  final String symbol;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: theme.colorScheme.surfaceContainerHigh, width: 24)),
          child: Text(formatMinor(0, symbol: symbol, showDecimals: false), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700).tabular),
        ),
        const SizedBox(height: 12),
        Text(message, style: captionStyle(context), textAlign: TextAlign.center),
      ],
    );
  }
}

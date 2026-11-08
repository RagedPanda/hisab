/// Building blocks shared by every dashboard card: the card surface, the
/// section wrapper, the skeleton swap and the chart tokens from the spec.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../shell/widgets/common.dart';
import '../../shell/widgets/segment_label.dart';

/// Vertical gap between cards.
const double kDashboardCardGap = 12;

/// Width below which the outer gutter tightens.
const double kNarrowDashboardWidth = 360;

/// Horizontal gutter around the cards for a given viewport width.
double dashboardGutter(double width) => width < kNarrowDashboardWidth ? 12 : 16;

/// Padding of a card's section header, inside the gutter.
const EdgeInsets kDashboardHeaderPadding = EdgeInsets.fromLTRB(4, 4, 0, 4);

/// fl_chart transition for data changes; none when the system asks for reduced motion.
Duration chartAnimation(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 350);

const Curve kChartCurve = Curves.easeOutCubic;

/// A chart axis label kept on one line inside the room the axis reserves for
/// it: at large text sizes it is drawn smaller rather than wrapped or clipped,
/// and every label on the same [axis] of one chart is drawn at the same scale.
/// Given a [width], the label takes that slot, centred, and a longer label
/// ends in an ellipsis.
class ChartAxisLabel extends SingleChildRenderObjectWidget {
  ChartAxisLabel(String label, {super.key, required this.axis, TextStyle? style, this.alignment = Alignment.center, double? width})
      : super(
          child: width == null
              ? Text(label, style: style, maxLines: 1, softWrap: false)
              : SizedBox(width: width, child: Text(label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
        );

  /// The side of the chart this label sits on: `meta.axisSide` in fl_chart's
  /// `getTitlesWidget`.
  final AxisSide axis;
  final Alignment alignment;

  @override
  RenderSegmentLabel createRenderObject(BuildContext context) => RenderSegmentLabel(_groupOf(context), alignment);

  @override
  void updateRenderObject(BuildContext context, RenderSegmentLabel renderObject) => renderObject
    ..group = _groupOf(context)
    ..alignment = alignment;

  static final _groups = Expando<Map<AxisSide, SegmentLabelGroup>>();

  /// The labels on one side of one chart share a group.
  SegmentLabelGroup? _groupOf(BuildContext context) {
    Element? chart;
    context.visitAncestorElements((element) {
      if (element.widget is! LineChart && element.widget is! BarChart) return true;
      chart = element;
      return false;
    });
    final found = chart;
    return found == null ? null : (_groups[found] ??= {})[axis] ??= SegmentLabelGroup();
  }
}

/// Colours for chart slices that have no category colour of their own.
List<Color> chartFallbackColors(ColorScheme scheme) => [scheme.primary, kAccentColor, scheme.tertiary, const Color(0xFF6C8EAD), const Color(0xFF9C7BB8)];

/// A dashboard card surface: 16dp radius, theme card colour, inner padding.
class DashboardCard extends StatelessWidget {
  const DashboardCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: padding, child: child);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}

/// Optional section header above a card, plus the gap to the next card.
class DashboardSection extends StatelessWidget {
  const DashboardSection({super.key, this.title, this.trailing, this.wrapsTrailing = false, required this.child});
  final String? title;
  final Widget? trailing;
  final Widget child;

  /// See [SectionHeader.wrapsTrailing].
  final bool wrapsTrailing;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) SectionHeader(title!, trailing: trailing, padding: kDashboardHeaderPadding, wrapsTrailing: wrapsTrailing),
          child,
          const SizedBox(height: kDashboardCardGap),
        ],
      );
}

/// Shows the skeleton until [value] has data, then fades the content in.
/// A reload keeps the last snapshot on screen, so switching months
/// cross-fades between two complete states instead of via a skeleton.
class AsyncCard<T> extends StatelessWidget {
  const AsyncCard({super.key, required this.value, required this.skeletonHeight, required this.builder, this.contentKey});
  final AsyncValue<T> value;
  final double skeletonHeight;
  final Widget Function(T data) builder;

  /// Changes when the content should cross-fade, e.g. the month shown.
  final Key? contentKey;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: value.hasValue
            ? KeyedSubtree(key: contentKey ?? const ValueKey('content'), child: builder(value.requireValue))
            : Padding(
                key: const ValueKey('skeleton'),
                padding: const EdgeInsets.only(bottom: kDashboardCardGap),
                child: LoadingPlaceholder(height: skeletonHeight),
              ),
      );
}

/// Caption text style for cards.
TextStyle? captionStyle(BuildContext context) =>
    Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);

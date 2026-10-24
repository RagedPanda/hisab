import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dates.dart';
import '../../../core/format.dart';
import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../domain/stats/month_summary.dart';
import '../../../l10n/l10n.dart';
import '../dashboard_keys.dart';
import '../dashboard_providers.dart';
import 'dashboard_card.dart';

/// "This month" at a glance: spend, how it compares to last month, income,
/// what is left, the daily average and how far through the month we are.
class HeroCard extends ConsumerWidget {
  const HeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hero = ref.watch(heroDataProvider);
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    return AsyncCard(
      value: hero,
      skeletonHeight: 168,
      contentKey: ValueKey(hero.value?.range.start),
      builder: (data) => DashboardSection(child: _HeroContent(data: data, moneyFormat: moneyFormat)),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({required this.data, required this.moneyFormat});
  final HeroData data;
  final MoneyFormat moneyFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final summary = data.summary;
    final isDark = theme.brightness == Brightness.dark;
    final foreground = isDark ? scheme.onPrimaryContainer : scheme.onPrimary;
    final gradient = isDark
        ? [scheme.primaryContainer, scheme.surfaceContainerHigh]
        : [scheme.primary, Color.lerp(scheme.primary, scheme.primaryContainer, 0.45)!];
    final amountText = formatMinor(summary.expense, format: moneyFormat, showDecimals: false);
    return Semantics(
      button: true,
      label: '${l10n.spentInMonth(formatMonthName(data.range, locale: locale))} $amountText',
      child: Card(
        key: kHeroCardKey,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: InkWell(
            onTap: () => context.go('/transactions'),
            onLongPress: () => _copyAmount(context, summary.expense),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.spentInMonth(formatMonthName(data.range, locale: locale)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(color: foreground.withValues(alpha: 0.85)),
                        ),
                      ),
                      if (summary.percentVsPrevious != null) _ComparisonPill(percent: summary.percentVsPrevious!, previousRange: data.previousRange, foreground: foreground),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _AnimatedAmount(minor: summary.expense, moneyFormat: moneyFormat, style: theme.textTheme.displaySmall?.copyWith(color: foreground, fontWeight: FontWeight.w700).tabular),
                  const SizedBox(height: 12),
                  if (summary.isEmpty) _EmptyRow(foreground: foreground) else _StatsRow(summary: summary, moneyFormat: moneyFormat, foreground: foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyAmount(BuildContext context, int minor) async {
    final messenger = ScaffoldMessenger.of(context);
    final copied = context.l10n.copied;
    await Clipboard.setData(ClipboardData(text: amountInputText(minor, format: moneyFormat)));
    HapticFeedback.selectionClick();
    messenger.showSnackBar(SnackBar(content: Text(copied)));
  }
}

/// The headline amount, tweened over 300 ms when the value changes.
class _AnimatedAmount extends StatelessWidget {
  const _AnimatedAmount({required this.minor, required this.moneyFormat, required this.style});
  final int minor;
  final MoneyFormat moneyFormat;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<int>(
        tween: IntTween(end: minor),
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => Text(formatMinor(value, format: moneyFormat, showDecimals: false), key: kSummarySpentKey, maxLines: 1, style: style),
      );
}

class _ComparisonPill extends StatelessWidget {
  const _ComparisonPill({required this.percent, required this.previousRange, required this.foreground});
  final int percent;
  final DateRange previousRange;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final month = formatMonthName(previousRange, locale: Localizations.localeOf(context).toString(), short: true);
    final text = percent > 0
        ? l10n.vsLastMonthUp(percent, month)
        : percent < 0
            ? l10n.vsLastMonthDown(-percent, month)
            : l10n.vsLastMonthSame(month);
    // Tint the pill, not the text: coloured text on the gradient would not reach contrast.
    final tint = percent > 0 ? kExpenseColor : percent < 0 ? kIncomeColor : foreground;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: tint.withValues(alpha: percent == 0 ? 0.12 : 0.3), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground, fontWeight: FontWeight.w600).tabular),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.summary, required this.moneyFormat, required this.foreground});
  final MonthSummary summary;
  final MoneyFormat moneyFormat;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final overspent = summary.net < 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _Stat(label: l10n.income, value: formatMinor(summary.income, format: moneyFormat, showDecimals: false), foreground: foreground, dot: kIncomeColor)),
        Expanded(child: _Stat(label: overspent ? l10n.overspent : l10n.saved, value: formatMinor(summary.net.abs(), format: moneyFormat, showDecimals: false), foreground: foreground, dot: overspent ? kExpenseColor : null)),
        Expanded(child: _Stat(label: l10n.dailyAverage, value: l10n.perDay(formatMinor(summary.dailyAverageMinor, format: moneyFormat, showDecimals: false)), foreground: foreground)),
        _MonthProgressRing(fraction: summary.elapsedFraction, elapsed: summary.daysElapsed, total: summary.daysInMonth, foreground: foreground),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.foreground, this.dot});
  final String label;
  final String value;
  final Color foreground;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          if (dot != null) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 4),
          ],
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelMedium?.copyWith(color: foreground.withValues(alpha: 0.8)))),
        ]),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, maxLines: 1, style: theme.textTheme.titleMedium?.copyWith(color: foreground, fontWeight: FontWeight.w600).tabular),
        ),
      ],
    );
  }
}

class _MonthProgressRing extends StatelessWidget {
  const _MonthProgressRing({required this.fraction, required this.elapsed, required this.total, required this.foreground});
  final double fraction;
  final int elapsed;
  final int total;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: context.l10n.daysOfMonth(elapsed, total),
        triggerMode: TooltipTriggerMode.tap,
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            value: fraction,
            strokeWidth: 3,
            color: foreground,
            backgroundColor: foreground.withValues(alpha: 0.25),
            semanticsLabel: context.l10n.daysOfMonth(elapsed, total),
          ),
        ),
      );
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.foreground});
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(l10n.heroEmptyCaption, style: theme.textTheme.bodyMedium?.copyWith(color: foreground.withValues(alpha: 0.85)))),
        const SizedBox(width: 8),
        // A plain button rather than a chip: the app-wide chip theme pins the
        // fill to `surface`, which would wash the label out on the gradient.
        FilledButton(
          onPressed: () => context.push('/entry'),
          style: FilledButton.styleFrom(
            backgroundColor: foreground.withValues(alpha: 0.16),
            foregroundColor: foreground,
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            textStyle: theme.textTheme.labelLarge,
          ),
          child: Text(l10n.addFirstEntry),
        ),
      ],
    );
  }
}

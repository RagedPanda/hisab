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
import '../../transactions/transactions_screen.dart';
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
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final summary = data.summary;
    final isDark = theme.brightness == Brightness.dark;
    const foreground = Colors.white;
    // The brand gradient in light mode; a deeper teal in dark so the card
    // does not glare against the dark scaffold.
    final gradient = isDark ? const [Color(0xFF115E59), Color(0xFF0F3D3A)] : kBrandGradient.colors;
    final amountText = formatMinor(summary.expense, format: moneyFormat, showDecimals: false);
    return Semantics(
      button: true,
      label: '${l10n.spentInMonth(formatMonthName(data.range, locale: locale))} $amountText',
      child: Card(
        key: kHeroCardKey,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: InkWell(
            onTap: () => context.go('/transactions'),
            onLongPress: () => _copyAmount(context, summary.expense),
            child: Stack(
              children: [
                const Positioned(right: -40, top: -50, child: _Halo(size: 160)),
                const Positioned(right: 40, bottom: -70, child: _Halo(size: 120)),
                Padding(
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
                      Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: _AnimatedAmount(minor: summary.expense, moneyFormat: moneyFormat, style: theme.textTheme.displaySmall?.copyWith(color: foreground, fontWeight: FontWeight.w700).tabular),
                            ),
                          ),
                          if (data.todayMinor != null) ...[
                            const SizedBox(width: 8),
                            _TodayPill(minor: data.todayMinor!, moneyFormat: moneyFormat, foreground: foreground),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (summary.isEmpty) const _EmptyRow(foreground: foreground) else _StatsRow(summary: summary, moneyFormat: moneyFormat, foreground: foreground),
                    ],
                  ),
                ),
              ],
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

/// "Today ₹X": what was spent since midnight. Tapping opens Entries narrowed
/// to today.
class _TodayPill extends StatelessWidget {
  const _TodayPill({required this.minor, required this.moneyFormat, required this.foreground});
  final int minor;
  final MoneyFormat moneyFormat;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final amount = formatMinor(minor, format: moneyFormat, showDecimals: false);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(999));
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: l10n.heroTodaySemantics(amount),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: kHeroTodayKey,
          customBorder: shape,
          onTap: () => context.go(entriesForDayLocation(DateTime.now())),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: ShapeDecoration(shape: shape, color: foreground.withValues(alpha: 0.16)),
            child: Text(
              l10n.heroToday(amount),
              maxLines: 1,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground, fontWeight: FontWeight.w600).tabular,
            ),
          ),
        ),
      ),
    );
  }
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
    // A plain fact, not a verdict: the pill is never tinted good or bad.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: foreground.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatTile(
          label: l10n.income,
          value: formatMinor(summary.income, format: moneyFormat, showDecimals: false),
          icon: Icons.south_west,
          accent: kIncomeColor,
          foreground: foreground,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '${l10n.dailyAverage} · ${l10n.perDay(formatMinor(summary.dailyAverageMinor, format: moneyFormat, showDecimals: false))}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(color: foreground.withValues(alpha: 0.85)).tabular,
              ),
            ),
            _MonthProgressRing(fraction: summary.elapsedFraction, elapsed: summary.daysElapsed, total: summary.daysInMonth, foreground: foreground),
          ],
        ),
      ],
    );
  }
}

/// A faint circle that gives the gradient some depth.
class _Halo extends StatelessWidget {
  const _Halo({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)),
    ),
  );
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon, required this.accent, required this.foreground});
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: foreground.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(color: foreground.withValues(alpha: 0.85)),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: theme.textTheme.titleMedium?.copyWith(color: foreground, fontWeight: FontWeight.w700).tabular,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../domain/launcher/spend_widget_figures.dart';
import '../../l10n/l10n.dart';
import '../dashboard/widgets/hero_card.dart';

/// This month's and last month's spend for the Home-screen widget, from one
/// ledger query over both months. The window is fixed when it is built;
/// LauncherSync rebuilds it when the app comes back, so a new month starts.
final spendWidgetFiguresProvider = StreamProvider<SpendWidgetFigures>((ref) {
  final monthStartDay = ref.watch(settingsProvider.select((settings) => settings.monthStartDay));
  final now = DateTime.now();
  final ranges = spendWidgetRanges(now, monthStartDay: monthStartDay);
  return ref
      .watch(entriesRepositoryProvider)
      .watchLedgerLines(DateRange(ranges.first.start, ranges.last.end))
      .map((lines) => spendWidgetFigures(lines: lines, now: now, monthStartDay: monthStartDay));
});

/// The widget's text, ready to show: native code only lays it out.
class SpendWidgetData {
  const SpendWidgetData({
    required this.title,
    required this.amount,
    required this.comparison,
    required this.previous,
    required this.validUntil,
    required this.opacity,
  });

  /// "Spent in October".
  final String title;
  final String amount;

  /// "▲ 12% vs Sep"; empty when last month had no spend.
  final String comparison;

  /// "Sep: ₹7,540".
  final String previous;

  /// End of the month shown; after it the widget asks to open Hisab.
  final DateTime validUntil;

  /// Background opacity, 0..100 percent.
  final int opacity;

  Map<String, Object> toMap() => {
        'title': title,
        'amount': amount,
        'comparison': comparison,
        'previous': previous,
        'validUntil': validUntil.millisecondsSinceEpoch,
        'opacity': opacity,
      };
}

SpendWidgetData spendWidgetData(
  SpendWidgetFigures figures, {
  required AppLocalizations l10n,
  required MoneyFormat moneyFormat,
  required String locale,
  required int opacity,
}) {
  final previousMonth = formatMonthName(figures.previousRange, locale: locale, short: true);
  final percent = figures.percentVsPrevious;
  return SpendWidgetData(
    title: l10n.spentInMonth(formatMonthName(figures.range, locale: locale)),
    amount: formatMinor(figures.spentMinor, format: moneyFormat, showDecimals: false),
    comparison: percent == null ? '' : vsLastMonthText(l10n, percent, previousMonth),
    previous: l10n.widgetLastMonth(previousMonth, formatMinor(figures.previousSpentMinor, format: moneyFormat, showDecimals: false)),
    validUntil: figures.range.end,
    opacity: opacity,
  );
}

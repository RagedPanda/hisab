import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/repositories/entries_repository.dart';
import '../../domain/ledger/spending_calendar.dart';
import '../../l10n/l10n.dart';
import '../dashboard/widgets/dashboard_card.dart' show captionStyle;
import '../shell/widgets/calendar_month.dart';
import '../shell/widgets/common.dart';

/// Route of the spending calendar screen.
const String kSpendingCalendarRoute = '/transactions/calendar';

/// Today, for the spending calendar; overridden in tests.
final spendingCalendarTodayProvider = Provider<DateTime>((ref) => startOfDay(DateTime.now()));

/// How strongly each heat level tints a day, lightest first.
const List<double> kSpendHeatAlphas = [0.10, 0.22, 0.36, 0.52];

/// A month where each day is shaded by what I spent on it, with the amount
/// under the date; tapping a day lists its entries below.
class SpendingCalendarScreen extends ConsumerStatefulWidget {
  const SpendingCalendarScreen({super.key});

  @override
  ConsumerState<SpendingCalendarScreen> createState() => _SpendingCalendarScreenState();
}

class _SpendingCalendarScreenState extends ConsumerState<SpendingCalendarScreen> {
  late DateTime _month;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = ref.read(spendingCalendarTodayProvider);
    final shown = ref.read(selectedMonthProvider);
    _month = DateTime(shown.year, shown.month);
    _selectedDay = _defaultDay(today);
  }

  /// Today when it is in the shown month, else the month's first day.
  DateTime _defaultDay(DateTime today) => today.year == _month.year && today.month == _month.month ? today : _month;

  void _shiftMonth(int months) => setState(() {
    _month = DateTime(_month.year, _month.month + months);
    _selectedDay = _defaultDay(ref.read(spendingCalendarTodayProvider));
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final today = ref.watch(spendingCalendarTodayProvider);
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final spendByDay = ref.watch(dailyExpenseProvider((start: _month, end: DateTime(_month.year, _month.month + 1)))).value ?? const <DateTime, int>{};
    final levels = spendHeatLevels(spendByDay);
    final monthTotal = spendByDay.values.fold(0, (sum, amount) => sum + amount);
    final selected = startOfDay(_selectedDay);
    final selectedSpend = spendByDay[selected] ?? 0;
    final dayEntries = ref.watch(windowEntriesProvider((start: selected, end: DateTime(selected.year, selected.month, selected.day + 1))));
    final dayList = dayEntries.value ?? const <EntryDetails>[];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.spendingCalendar)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          CalendarMonthHeader(month: _month, onShift: _shiftMonth, titleKey: const ValueKey('spending.calendar.month')),
          Text(
            l10n.spendingCalendarSpent(formatMinor(monthTotal, format: moneyFormat, showDecimals: false)),
            key: const ValueKey('spending.calendar.total'),
            textAlign: TextAlign.center,
            style: captionStyle(context),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CalendarMonthGrid(
              month: _month,
              dayCell: (day) => _SpendDayCell(
                day: day,
                spentMinor: spendByDay[day] ?? 0,
                level: levels[day] ?? 0,
                isToday: isSameDay(day, today),
                isSelected: isSameDay(day, _selectedDay),
                onTap: () => setState(() => _selectedDay = day),
              ),
            ),
          ),
          SectionHeader(
            formatDayLabel(_selectedDay, now: today, locale: locale, today: l10n.today, yesterday: l10n.yesterday),
            trailing: selectedSpend > 0 ? Text(formatMinor(selectedSpend, format: moneyFormat), key: const ValueKey('spending.calendar.dayTotal')) : null,
          ),
          if (dayEntries.isLoading && !dayEntries.hasValue)
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: LoadingPlaceholder(height: 72))
          else if (dayList.isEmpty)
            Padding(
              key: const ValueKey('spending.calendar.dayEmpty'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                l10n.spendingCalendarDayEmpty,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            )
          else
            for (final details in dayList) EntryTile(details: details, onTap: () => context.push('/entry?id=${details.entry.id}')),
        ],
      ),
    );
  }
}

class _SpendDayCell extends ConsumerWidget {
  const _SpendDayCell({
    required this.day,
    required this.spentMinor,
    required this.level,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });
  final DateTime day;
  final int spentMinor;
  final int level;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final dayLabel = DateFormat.MMMMd(Localizations.localeOf(context).toString()).format(day);
    return CalendarDayCell(
      key: ValueKey('spending.calendar.day.${day.day}'),
      day: day,
      isToday: isToday,
      isSelected: isSelected,
      semanticLabel: spentMinor > 0 ? '$dayLabel, ${l10n.spendingCalendarSpent(formatMinor(spentMinor, format: moneyFormat))}' : dayLabel,
      onTap: onTap,
      fill: level == 0 ? null : kExpenseColor.withValues(alpha: kSpendHeatAlphas[level - 1]),
      below: Text(
        spentMinor > 0 ? calendarAmountLabel(spentMinor, moneyFormat) : '',
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/upcoming/calendar_grid.dart';
import '../../domain/upcoming/upcoming_items.dart';
import '../../l10n/l10n.dart';
import '../dashboard/widgets/dashboard_card.dart' show captionStyle;
import '../shell/widgets/common.dart';
import 'upcoming_actions.dart';
import 'upcoming_providers.dart';
import 'widgets/upcoming_item_tile.dart';

/// Most dots drawn under one day; more items still count in the label.
const int kMaxCalendarDots = 3;

/// Month calendar with a dot per due item and the selected day's items below.
class UpcomingCalendarScreen extends ConsumerStatefulWidget {
  const UpcomingCalendarScreen({super.key});

  @override
  ConsumerState<UpcomingCalendarScreen> createState() => _UpcomingCalendarScreenState();
}

class _UpcomingCalendarScreenState extends ConsumerState<UpcomingCalendarScreen> {
  late DateTime _month;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = ref.read(upcomingTodayProvider);
    _month = DateTime(today.year, today.month);
    _selectedDay = today;
  }

  void _shiftMonth(int months) => setState(() {
    _month = DateTime(_month.year, _month.month + months);
    final today = ref.read(upcomingTodayProvider);
    _selectedDay = today.year == _month.year && today.month == _month.month ? today : _month;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final today = ref.watch(upcomingTodayProvider);
    final items = ref.watch(upcomingMonthProvider(_month));
    final byDay = upcomingByDay(items.value ?? const []);
    final dayItems = byDay[startOfDay(_selectedDay)] ?? const <UpcomingItem>[];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.upcomingCalendar)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(tooltip: l10n.upcomingCalendarPreviousMonth, onPressed: () => _shiftMonth(-1), icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Text(
                    formatMonthYear(_month, locale: locale),
                    key: const ValueKey('upcoming.calendar.month'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(tooltip: l10n.upcomingCalendarNextMonth, onPressed: () => _shiftMonth(1), icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _MonthGrid(month: _month, today: today, selectedDay: _selectedDay, byDay: byDay, onSelect: (day) => setState(() => _selectedDay = day)),
          ),
          SectionHeader(formatDayLabel(_selectedDay, now: today, locale: locale, today: l10n.today, yesterday: l10n.yesterday)),
          if (items.isLoading && !items.hasValue)
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: LoadingPlaceholder(height: 72))
          else if (dayItems.isEmpty)
            Padding(
              key: const ValueKey('upcoming.calendar.dayEmpty'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                l10n.upcomingCalendarDayEmpty,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            )
          else
            for (final item in dayItems) UpcomingItemTile(item: item, onTap: () => openUpcomingItem(context, ref, item)),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.today, required this.selectedDay, required this.byDay, required this.onSelect});
  final DateTime month;
  final DateTime today;
  final DateTime selectedDay;
  final Map<DateTime, List<UpcomingItem>> byDay;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final materialFirstDay = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final firstWeekday = materialFirstDay == 0 ? DateTime.sunday : materialFirstDay;
    final locale = Localizations.localeOf(context).toString();
    final weekdayFormat = DateFormat.E(locale);
    // 2024-01-01 was a Monday, so day N of that week has ISO weekday N.
    String weekdayName(int isoWeekday) => weekdayFormat.format(DateTime(2024, 1, isoWeekday));
    final cells = calendarMonthCells(month, firstWeekday: firstWeekday);
    return Column(
      children: [
        Row(
          children: [
            for (final weekday in calendarWeekdays(firstWeekday: firstWeekday))
              Expanded(
                child: ExcludeSemantics(
                  child: Text(weekdayName(weekday), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.clip, style: captionStyle(context)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var row = 0; row < cells.length ~/ 7; row++)
          Row(
            children: [
              for (final day in cells.sublist(row * 7, row * 7 + 7))
                Expanded(
                  child: day == null
                      ? const SizedBox(height: 52)
                      : _DayCell(
                          day: day,
                          items: byDay[day] ?? const [],
                          isToday: isSameDay(day, today),
                          isSelected: isSameDay(day, selectedDay),
                          onTap: () => onSelect(day),
                        ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.items, required this.isToday, required this.isSelected, required this.onTap});
  final DateTime day;
  final List<UpcomingItem> items;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final dayLabel = DateFormat.MMMMd(locale).format(day);
    return Semantics(
      key: ValueKey('upcoming.calendar.day.${day.day}'),
      button: true,
      selected: isSelected,
      label: items.isEmpty ? dayLabel : '$dayLabel, ${l10n.upcomingCalendarDueCount(items.length)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primaryContainer : null,
            borderRadius: BorderRadius.circular(12),
            border: isToday && !isSelected ? Border.all(color: scheme.primary) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: isSelected ? scheme.onPrimaryContainer : null, fontWeight: isToday ? FontWeight.w700 : null),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final item in items.take(kMaxCalendarDots))
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: _dotColor(scheme, item)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _dotColor(ColorScheme scheme, UpcomingItem item) {
    if (item.isOverdue) return scheme.error;
    if (item.isIncome) return kIncomeColor;
    return scheme.primary;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/upcoming/upcoming_items.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/calendar_month.dart';
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
          CalendarMonthHeader(month: _month, onShift: _shiftMonth, titleKey: const ValueKey('upcoming.calendar.month')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CalendarMonthGrid(
              month: _month,
              dayCell: (day) => _DayCell(
                day: day,
                items: byDay[day] ?? const [],
                isToday: isSameDay(day, today),
                isSelected: isSameDay(day, _selectedDay),
                onTap: () => setState(() => _selectedDay = day),
              ),
            ),
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
    final dayLabel = DateFormat.MMMMd(Localizations.localeOf(context).toString()).format(day);
    return CalendarDayCell(
      key: ValueKey('upcoming.calendar.day.${day.day}'),
      day: day,
      isToday: isToday,
      isSelected: isSelected,
      semanticLabel: items.isEmpty ? dayLabel : '$dayLabel, ${l10n.upcomingCalendarDueCount(items.length)}',
      onTap: onTap,
      below: SizedBox(
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
    );
  }

  Color _dotColor(ColorScheme scheme, UpcomingItem item) {
    if (item.isOverdue) return scheme.error;
    if (item.isIncome) return kIncomeColor;
    return scheme.primary;
  }
}

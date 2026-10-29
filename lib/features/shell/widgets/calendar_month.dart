import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/format.dart';
import '../../../domain/upcoming/calendar_grid.dart';
import '../../../l10n/l10n.dart';
import '../../dashboard/widgets/dashboard_card.dart' show captionStyle;

/// Height of one day cell in a month calendar.
const double kCalendarCellHeight = 52;

/// "‹ October 2026 ›": the month a calendar shows, with buttons to step it.
class CalendarMonthHeader extends StatelessWidget {
  const CalendarMonthHeader({super.key, required this.month, required this.onShift, this.titleKey});
  final DateTime month;
  final ValueChanged<int> onShift;
  final Key? titleKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(tooltip: l10n.upcomingCalendarPreviousMonth, onPressed: () => onShift(-1), icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: Text(
              formatMonthYear(month, locale: Localizations.localeOf(context).toString()),
              key: titleKey,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(tooltip: l10n.upcomingCalendarNextMonth, onPressed: () => onShift(1), icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

/// The weeks of [month] under weekday names, in the user's week order, with
/// [dayCell] drawing each day.
class CalendarMonthGrid extends StatelessWidget {
  const CalendarMonthGrid({super.key, required this.month, required this.dayCell});
  final DateTime month;
  final Widget Function(DateTime day) dayCell;

  @override
  Widget build(BuildContext context) {
    final appLocale = Localizations.localeOf(context);
    final firstWeekday = calendarFirstWeekday(
      appLanguage: appLocale.languageCode,
      deviceLocaleTags: [appLocale.toLanguageTag(), for (final deviceLocale in View.of(context).platformDispatcher.locales) deviceLocale.toLanguageTag()],
    );
    final weekdayFormat = DateFormat.E(appLocale.toString());
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
                Expanded(child: day == null ? const SizedBox(height: kCalendarCellHeight) : dayCell(day)),
            ],
          ),
      ],
    );
  }
}

/// One tappable day: its number, then [below]. Selected fills it unless it
/// has its own [fill] (then a thicker outline marks it); today is outlined.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.semanticLabel,
    required this.onTap,
    this.fill,
    this.below,
  });
  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final String semanticLabel;
  final VoidCallback onTap;
  final Color? fill;
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedFill = isSelected && fill == null;
    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: kCalendarCellHeight,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: selectedFill ? scheme.primaryContainer : fill,
            borderRadius: BorderRadius.circular(12),
            border: isSelected && fill != null
                ? Border.all(color: scheme.primary, width: 2)
                : isToday && !isSelected
                    ? Border.all(color: scheme.primary)
                    : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: selectedFill ? scheme.onPrimaryContainer : null, fontWeight: isToday ? FontWeight.w700 : null),
              ),
              if (below != null) ...[const SizedBox(height: 4), below!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Pure month-grid layout for the due calendar.
library;

/// The cells of a month view in rows of seven: leading nulls pad the first
/// week so day 1 lands under its weekday, trailing nulls fill the last row.
/// [firstWeekday] is the ISO weekday the rows start on (1 = Monday).
List<DateTime?> calendarMonthCells(DateTime month, {int firstWeekday = DateTime.monday}) {
  final first = DateTime(month.year, month.month);
  final length = DateTime(month.year, month.month + 1, 0).day;
  final leading = (first.weekday - firstWeekday) % 7;
  final cells = <DateTime?>[for (var pad = 0; pad < leading; pad++) null, for (var day = 1; day <= length; day++) DateTime(month.year, month.month, day)];
  final trailing = (7 - cells.length % 7) % 7;
  return [...cells, for (var pad = 0; pad < trailing; pad++) null];
}

/// The seven weekdays (ISO numbers) in display order.
List<int> calendarWeekdays({int firstWeekday = DateTime.monday}) => [for (var offset = 0; offset < 7; offset++) (firstWeekday - 1 + offset) % 7 + 1];

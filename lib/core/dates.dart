/// Pure date helpers shared by budgets, dashboard and reports.
library;

/// A closed-open range [start, end).
class DateRange {
  const DateRange(this.start, this.end);
  final DateTime start;
  final DateTime end;

  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(end);
}

DateTime startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Returns the "month" containing [anchor] when months start on [startDay]
/// (1 = calendar month; 25 = salary month running 25th to 24th).
DateRange monthRange(DateTime anchor, {int startDay = 1}) {
  final day = startDay.clamp(1, 28);
  var start = DateTime(anchor.year, anchor.month, day);
  if (anchor.isBefore(start)) {
    start = DateTime(anchor.year, anchor.month - 1, day);
  }
  final end = DateTime(start.year, start.month + 1, day);
  return DateRange(start, end);
}

DateRange weekRange(DateTime anchor) {
  final day = startOfDay(anchor);
  final start = day.subtract(Duration(days: day.weekday - 1));
  return DateRange(start, start.add(const Duration(days: 7)));
}

DateRange yearRange(DateTime anchor) =>
    DateRange(DateTime(anchor.year), DateTime(anchor.year + 1));

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

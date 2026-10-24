import 'package:intl/intl.dart';

import 'dates.dart';

/// Relative day label. [today] and [yesterday] are the localised words for
/// those two days; pass [locale] so month/weekday names follow the app locale.
String formatDayLabel(DateTime day, {required String today, required String yesterday, DateTime? now, String? locale}) {
  final todayStart = startOfDay(now ?? DateTime.now());
  final target = startOfDay(day);
  if (target == todayStart) return today;
  if (target == todayStart.subtract(const Duration(days: 1))) return yesterday;
  if (target.year == todayStart.year) return DateFormat('EEE, d MMM', locale).format(day);
  return DateFormat('d MMM yyyy', locale).format(day);
}

String formatMonthLabel(DateRange range, {String? locale}) {
  if (range.start.day == 1) return DateFormat('MMMM yyyy', locale).format(range.start);
  final end = range.end.subtract(const Duration(days: 1));
  return '${DateFormat('d MMM', locale).format(range.start)} – ${DateFormat('d MMM', locale).format(end)}';
}

/// Month name for headings ("October", short "Oct"); a month that starts on a
/// custom day keeps the explicit range label instead.
String formatMonthName(DateRange range, {String? locale, bool short = false}) {
  if (range.start.day != 1) return formatMonthLabel(range, locale: locale);
  return DateFormat(short ? 'MMM' : 'MMMM', locale).format(range.start);
}

String formatShortDate(DateTime value, {String? locale}) => DateFormat('d MMM yyyy', locale).format(value);

/// Compact date for list rows: "21 Oct" (this year) or "21 Oct 2025".
String formatRowDate(DateTime value, {DateTime? now, String? locale}) {
  final sameYear = value.year == (now ?? DateTime.now()).year;
  return DateFormat(sameYear ? 'd MMM' : 'd MMM yyyy', locale).format(value);
}

/// Full weekday name: "Monday".
String formatWeekday(DateTime value, {String? locale}) => DateFormat('EEEE', locale).format(value);

/// Day and month without the year: "5 Jul".
String formatDayMonth(DateTime value, {String? locale}) => DateFormat('d MMM', locale).format(value);

String formatTime(DateTime value, {String? locale}) => DateFormat('h:mm a', locale).format(value);

String formatQuantity(double quantity, String? unit) {
  final text = quantity == quantity.roundToDouble() ? quantity.toInt().toString() : quantity.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  return unit == null || unit.isEmpty ? text : '$text $unit';
}

/// Joins the first [max] names with ", " and appends [overflow] for the rest:
/// ["a","b","c","d"] with max 3 becomes "a, b, c, +1".
String joinWithOverflow(Iterable<String> names, {required int max, required String Function(int remaining) overflow}) {
  final list = names.toList();
  if (list.length <= max) return list.join(', ');
  return '${list.take(max).join(', ')}, ${overflow(list.length - max)}';
}

/// Month heading with the year: "October 2026".
String formatMonthYear(DateTime month, {String? locale}) => DateFormat('MMMM yyyy', locale).format(month);

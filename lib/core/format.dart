import 'package:intl/intl.dart';

import 'dates.dart';

/// Relative day label. [today] and [yesterday] are the localised words for
/// those two days; pass [locale] so month/weekday names follow the app locale.
String formatDayLabel(
  DateTime day, {
  required String today,
  required String yesterday,
  DateTime? now,
  String? locale,
}) {
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

String formatShortDate(DateTime value, {String? locale}) => DateFormat('d MMM yyyy', locale).format(value);
String formatTime(DateTime value, {String? locale}) => DateFormat('h:mm a', locale).format(value);

String formatQuantity(double quantity, String? unit) {
  final text = quantity == quantity.roundToDouble() ? quantity.toInt().toString() : quantity.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  return unit == null || unit.isEmpty ? text : '$text $unit';
}

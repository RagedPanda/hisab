import 'package:intl/intl.dart';

import 'dates.dart';

String formatDayLabel(DateTime day, {DateTime? now}) {
  final today = startOfDay(now ?? DateTime.now());
  final target = startOfDay(day);
  if (target == today) return 'Today';
  if (target == today.subtract(const Duration(days: 1))) return 'Yesterday';
  if (target.year == today.year) return DateFormat('EEE, d MMM').format(day);
  return DateFormat('d MMM yyyy').format(day);
}

String formatMonthLabel(DateRange range) {
  if (range.start.day == 1) return DateFormat('MMMM yyyy').format(range.start);
  final end = range.end.subtract(const Duration(days: 1));
  return '${DateFormat('d MMM').format(range.start)} – ${DateFormat('d MMM').format(end)}';
}

String formatShortDate(DateTime value) => DateFormat('d MMM yyyy').format(value);
String formatTime(DateTime value) => DateFormat('h:mm a').format(value);

String formatQuantity(double quantity, String? unit) {
  final text = quantity == quantity.roundToDouble() ? quantity.toInt().toString() : quantity.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  return unit == null || unit.isEmpty ? text : '$text $unit';
}

/// Pure helpers for the spending calendar: how dark each day is and the
/// short amount written in its cell.
library;

import '../../core/money.dart';

/// Shades a day can take; 0 is a day with no spend.
const int kSpendHeatLevels = 4;

/// Each spending day's shade, 1 (lightest) to [kSpendHeatLevels] (darkest),
/// by its rank among the month's spending days rather than by amount, so one
/// rent day does not wash every other day out to the lightest shade. Equal
/// amounts share a shade; days with no spend are left out.
Map<DateTime, int> spendHeatLevels(Map<DateTime, int> spendByDay) {
  final amounts = [for (final amount in spendByDay.values) if (amount > 0) amount]..sort();
  if (amounts.isEmpty) return const {};
  int levelOf(int amount) {
    final below = amounts.indexOf(amount);
    return (below * kSpendHeatLevels ~/ amounts.length) + 1;
  }

  return {
    for (final MapEntry(key: day, value: amount) in spendByDay.entries)
      if (amount > 0) day: levelOf(amount),
  };
}

/// [minor] as few characters as fit a calendar cell, without the symbol:
/// 375, 1.6K, 12K, 1.2L. Rounds to whole units.
String calendarAmountLabel(int minor, MoneyFormat format) {
  final whole = roundMinorToWhole(minor.abs());
  final (divisor, suffix) = compactUnit(whole.toDouble(), format.grouping);
  if (divisor == 1) return '$whole';
  final scaled = whole / divisor;
  final text = scaled >= 10 ? scaled.round().toString() : scaled.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  return '${text.replaceFirst('.', format.decimalSeparator)}$suffix';
}

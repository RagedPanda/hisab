import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/domain/ledger/personal_totals.dart';
import 'package:hisab/domain/stats/spend_series.dart';
import 'package:hisab/domain/stats/trend.dart';

LedgerLine _expense(DateTime at, int minor) => LedgerLine(kind: 'expense', amountMinor: minor, occurredAt: at);

void main() {
  final march = DateRange(DateTime(2026, 3, 1), DateTime(2026, 4, 1));
  final ranges = trailingMonthRanges(march, count: 6, startDay: 1);

  test('current series stops at today and February overlays flat across 31 days', () {
    final trend = buildTrend(
      lines: [
        _expense(DateTime(2026, 3, 1), 100),
        _expense(DateTime(2026, 3, 4), 200),
        _expense(DateTime(2026, 2, 28), 500),
        _expense(DateTime(2026, 2, 2), 50),
      ],
      monthRanges: ranges,
      now: DateTime(2026, 3, 5, 10),
    );
    expect(trend.daysInMonth, 31);
    expect(trend.daysElapsed, 5);
    expect(trend.current, [100, 100, 100, 300, 300]);
    expect(trend.previous.length, 31);
    expect(trend.previous[27], 550);
    expect(trend.previous.last, 550, reason: 'February holds its final total through day 31');
    expect(trend.hasPrevious, isTrue);
    expect(trend.currentTotal, 300);
    expect(trend.maxValue, 550);
    expect(trend.months.length, 6);
    expect(trend.months.last.expense, 300);
    expect(trend.months[4].expense, 550);
    expect(trend.hasEnoughData, isTrue);
  });

  test('fewer than three expenses in the window hides the card', () {
    final trend = buildTrend(lines: [_expense(DateTime(2026, 3, 1), 100)], monthRanges: ranges, now: DateTime(2026, 3, 5));
    expect(trend.hasEnoughData, isFalse);
    expect(trend.hasPrevious, isFalse);
  });
}

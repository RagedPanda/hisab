import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/domain/ledger/personal_totals.dart';
import 'package:hisab/domain/stats/month_summary.dart';

LedgerLine _line(String kind, int minor, DateTime at) => LedgerLine(kind: kind, amountMinor: minor, occurredAt: at);

void main() {
  final october = DateRange(DateTime(2026, 10, 1), DateTime(2026, 11, 1));

  test('hero figures: spend, income, saved, daily average and comparison', () {
    final summary = summariseMonth(
      current: [_line('expense', 210000, DateTime(2026, 10, 3)), _line('income', 500000, DateTime(2026, 10, 1)), _line('transfer', 99, DateTime(2026, 10, 2))],
      previous: [_line('expense', 200000, DateTime(2026, 9, 3))],
      range: october,
      now: DateTime(2026, 10, 21, 12),
    );
    expect(summary.expense, 210000);
    expect(summary.income, 500000);
    expect(summary.net, 290000);
    expect(summary.previousExpense, 200000);
    expect(summary.percentVsPrevious, 5);
    expect(summary.daysElapsed, 21);
    expect(summary.daysInMonth, 31);
    expect(summary.dailyAverageMinor, 10000);
    expect(summary.elapsedFraction, closeTo(0.66, 0.01));
    expect(summary.isEmpty, isFalse);
  });

  test('an empty month hides the comparison when last month had nothing', () {
    final summary = summariseMonth(current: const [], previous: const [], range: october, now: DateTime(2026, 10, 1));
    expect(summary.isEmpty, isTrue);
    expect(summary.percentVsPrevious, isNull);
    expect(summary.dailyAverageMinor, 0);
  });
}

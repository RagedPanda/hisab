import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/domain/ledger/personal_totals.dart';
import 'package:hisab/domain/stats/today_spend.dart';

LedgerLine _line(String kind, int minor, DateTime at) => LedgerLine(kind: kind, amountMinor: minor, occurredAt: at);

void main() {
  final october = DateRange(DateTime(2026, 10, 1), DateTime(2026, 11, 1));
  final now = DateTime(2026, 10, 24, 15, 30);

  test('sums only today\'s expenses; income and transfers do not count', () {
    final lines = [
      _line('expense', 12000, DateTime(2026, 10, 24, 9)),
      _line('expense', 3000, DateTime(2026, 10, 24, 14)),
      _line('income', 500000, DateTime(2026, 10, 24, 10)),
      _line('transfer', 70000, DateTime(2026, 10, 24, 11)),
      _line('expense', 99900, DateTime(2026, 10, 23, 18)),
    ];
    expect(todaySpendMinor(lines: lines, shownRange: october, now: now), 15000);
  });

  test('midnight boundary: 23:59:59 yesterday is out, 00:00 today and 23:59:59 today are in, 00:00 tomorrow is out', () {
    final lines = [
      _line('expense', 1, DateTime(2026, 10, 23, 23, 59, 59)),
      _line('expense', 10, DateTime(2026, 10, 24)),
      _line('expense', 100, DateTime(2026, 10, 24, 23, 59, 59)),
      _line('expense', 1000, DateTime(2026, 10, 25)),
    ];
    expect(todaySpendMinor(lines: lines, shownRange: october, now: now), 110);
    expect(todaySpendMinor(lines: lines, shownRange: october, now: DateTime(2026, 10, 24)), 110);
    expect(todaySpendMinor(lines: lines, shownRange: october, now: DateTime(2026, 10, 25)), 1000);
  });

  test('nothing spent today is zero, not null', () {
    expect(todaySpendMinor(lines: [_line('expense', 500, DateTime(2026, 10, 2))], shownRange: october, now: now), 0);
  });

  test('a month that does not contain today shows no Today figure', () {
    final september = DateRange(DateTime(2026, 9, 1), DateTime(2026, 10, 1));
    expect(todaySpendMinor(lines: [_line('expense', 500, now)], shownRange: september, now: now), isNull);
  });

  test('a salary month (25th to 24th) still counts only the calendar day', () {
    final salaryMonth = DateRange(DateTime(2026, 9, 25), DateTime(2026, 10, 25));
    final lines = [_line('expense', 400, DateTime(2026, 10, 24, 8)), _line('expense', 9, DateTime(2026, 10, 25, 8))];
    expect(todaySpendMinor(lines: lines, shownRange: salaryMonth, now: now), 400);
  });

  test('dayRange spans local midnight to the next midnight', () {
    final day = dayRange(DateTime(2026, 12, 31, 18));
    expect(day.start, DateTime(2026, 12, 31));
    expect(day.end, DateTime(2027));
  });
}

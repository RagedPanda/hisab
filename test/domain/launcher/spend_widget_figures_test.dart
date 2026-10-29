import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/launcher/spend_widget_figures.dart';
import 'package:hisab/domain/ledger/personal_totals.dart';

LedgerLine _line(String kind, int amountMinor, DateTime at) => LedgerLine(kind: kind, amountMinor: amountMinor, occurredAt: at);

void main() {
  group('spendWidgetFigures', () {
    final now = DateTime(2026, 10, 20, 10);

    test('compares this month spend with last month', () {
      final figures = spendWidgetFigures(
        lines: [
          _line('expense', 6000, DateTime(2026, 10, 3)),
          _line('expense', 5000, DateTime(2026, 10, 19)),
          _line('expense', 10000, DateTime(2026, 9, 12)),
          _line('income', 50000, DateTime(2026, 10, 1)),
        ],
        now: now,
        monthStartDay: 1,
      );
      expect(figures.range.start, DateTime(2026, 10, 1));
      expect(figures.previousRange.start, DateTime(2026, 9, 1));
      expect(figures.spentMinor, 11000);
      expect(figures.previousSpentMinor, 10000);
      expect(figures.percentVsPrevious, 10);
    });

    test('ignores lines outside the two months', () {
      final figures = spendWidgetFigures(
        lines: [_line('expense', 999, DateTime(2026, 8, 31)), _line('expense', 999, DateTime(2026, 11, 1))],
        now: now,
        monthStartDay: 1,
      );
      expect(figures.spentMinor, 0);
      expect(figures.previousSpentMinor, 0);
    });

    test('has no comparison when last month had no spend', () {
      final figures = spendWidgetFigures(lines: [_line('expense', 500, DateTime(2026, 10, 2))], now: now, monthStartDay: 1);
      expect(figures.percentVsPrevious, isNull);
    });

    test('follows a custom month start day', () {
      final figures = spendWidgetFigures(
        lines: [_line('expense', 700, DateTime(2026, 10, 24)), _line('expense', 300, DateTime(2026, 10, 25))],
        now: DateTime(2026, 10, 28),
        monthStartDay: 25,
      );
      expect(figures.range.start, DateTime(2026, 10, 25));
      expect(figures.range.end, DateTime(2026, 11, 25));
      expect(figures.spentMinor, 300);
      expect(figures.previousSpentMinor, 700);
      expect(spendWidgetRanges(DateTime(2026, 10, 28), monthStartDay: 25).first.start, DateTime(2026, 9, 25));
    });
  });
}

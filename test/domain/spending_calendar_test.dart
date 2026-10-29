import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/ledger/spending_calendar.dart';
import 'package:hisab/domain/money/money_format.dart';

void main() {
  group('spendHeatLevels', () {
    test('is empty when nothing was spent', () {
      expect(spendHeatLevels(const {}), isEmpty);
      expect(spendHeatLevels({DateTime(2026, 10, 1): 0}), isEmpty);
    });

    test('ranks days into four shades, lightest for the smallest spend', () {
      final levels = spendHeatLevels({
        DateTime(2026, 10, 1): 10000,
        DateTime(2026, 10, 2): 20000,
        DateTime(2026, 10, 3): 30000,
        DateTime(2026, 10, 4): 4000000,
      });
      expect(levels, {DateTime(2026, 10, 1): 1, DateTime(2026, 10, 2): 2, DateTime(2026, 10, 3): 3, DateTime(2026, 10, 4): 4});
    });

    test('one large day does not wash the others out', () {
      final levels = spendHeatLevels({DateTime(2026, 10, 1): 5000, DateTime(2026, 10, 2): 6000, DateTime(2026, 10, 3): 2500000});
      expect(levels[DateTime(2026, 10, 2)], greaterThan(levels[DateTime(2026, 10, 1)]!));
      expect(levels[DateTime(2026, 10, 3)], 3);
    });

    test('equal amounts share a shade and zero days are left out', () {
      final levels = spendHeatLevels({DateTime(2026, 10, 1): 5000, DateTime(2026, 10, 2): 5000, DateTime(2026, 10, 3): 0});
      expect(levels, {DateTime(2026, 10, 1): 1, DateTime(2026, 10, 2): 1});
    });

    test('a single spending day gets the lightest shade', () {
      expect(spendHeatLevels({DateTime(2026, 10, 9): 99900}), {DateTime(2026, 10, 9): 1});
    });
  });

  group('calendarAmountLabel', () {
    test('writes small amounts whole and large ones compact', () {
      expect(calendarAmountLabel(37500, MoneyFormat.inr), '375');
      expect(calendarAmountLabel(37550, MoneyFormat.inr), '376');
      expect(calendarAmountLabel(160000, MoneyFormat.inr), '1.6K');
      expect(calendarAmountLabel(200000, MoneyFormat.inr), '2K');
      expect(calendarAmountLabel(1240000, MoneyFormat.inr), '12K');
      expect(calendarAmountLabel(12000000, MoneyFormat.inr), '1.2L');
    });

    test('uses western units and the decimal separator of the format', () {
      const euro = MoneyFormat(grouping: DigitGrouping.western, groupSeparator: '.', decimalSeparator: ',', fractionDigits: 2, symbol: '€', symbolAfter: true);
      expect(calendarAmountLabel(150000000, euro), '1,5M');
      expect(calendarAmountLabel(250000, euro), '2,5K');
    });
  });
}

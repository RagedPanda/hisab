import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/format.dart';
import 'package:hisab/domain/accounts/account_label.dart';
import 'package:hisab/domain/categories/category_filter.dart';
import 'package:hisab/domain/stats/category_shares.dart';
import 'package:hisab/domain/stats/spend_series.dart';
import 'package:hisab/features/dashboard/widgets/category_donut.dart';

void main() {
  group('startDegreeForShare', () {
    const shares = [
      CategoryShare(categoryId: 'a', minor: 50, fraction: 0.5),
      CategoryShare(categoryId: 'b', minor: 25, fraction: 0.25),
      CategoryShare(categoryId: null, minor: 25, fraction: 0.25),
    ];

    test('is zero without a selection or for an index out of range', () {
      expect(startDegreeForShare(shares, null), 0);
      expect(startDegreeForShare(shares, 3), 0);
      expect(startDegreeForShare(shares, -1), 0);
    });

    test('centres the selected slice at twelve o clock', () {
      // Slice 0 spans 180 degrees: its middle sits 90 degrees after the offset.
      expect(startDegreeForShare(shares, 0), -180);
      // Slice 1 starts 180 degrees in and spans 90: middle at 225.
      expect(startDegreeForShare(shares, 1), -315);
    });
  });

  group('niceCeiling', () {
    test('rounds up to 1, 2 or 5 times a power of ten', () {
      expect(niceCeiling(0), 1);
      expect(niceCeiling(7), 10);
      expect(niceCeiling(10), 10);
      expect(niceCeiling(1200), 2000);
      expect(niceCeiling(41356), 50000);
      expect(niceCeiling(60000), 100000);
    });
  });

  group('matchesCategoryFilter', () {
    test('empty selection matches only uncategorised entries', () {
      expect(matchesCategoryFilter(selectedId: '', categoryId: null), isTrue);
      expect(matchesCategoryFilter(selectedId: '', categoryId: 'food'), isFalse);
    });

    test('a parent matches itself and its sub-categories', () {
      expect(matchesCategoryFilter(selectedId: 'food', categoryId: 'food'), isTrue);
      expect(matchesCategoryFilter(selectedId: 'food', categoryId: 'coffee', parentId: 'food'), isTrue);
      expect(matchesCategoryFilter(selectedId: 'food', categoryId: 'fuel', parentId: 'transport'), isFalse);
    });
  });

  group('formatMonthName', () {
    test('names a calendar month and keeps the range label for custom starts', () {
      expect(formatMonthName(DateRange(DateTime(2026, 10), DateTime(2026, 11))), 'October');
      expect(formatMonthName(DateRange(DateTime(2026, 10), DateTime(2026, 11)), short: true), 'Oct');
      expect(formatMonthName(DateRange(DateTime(2026, 9, 25), DateTime(2026, 10, 25))), '25 Sep – 24 Oct');
    });
  });

  group('accounts', () {
    test('icon per type with a cash fallback', () {
      expect(accountIconFor('bank'), 'account_balance');
      expect(accountIconFor('card'), 'credit_card');
      expect(accountIconFor('mystery'), 'payments');
    });

    test('total only counts accounts included in the total', () {
      expect(includedBalanceTotal([(includeInTotal: true, balanceMinor: 1000), (includeInTotal: false, balanceMinor: 500), (includeInTotal: true, balanceMinor: -200)]), 800);
    });
  });

  group('axisAmountLabel', () {
    test('uses K, L and Cr suffixes without trailing zeros', () {
      expect(axisAmountLabel(0), '0');
      expect(axisAmountLabel(800), '800');
      expect(axisAmountLabel(2500, symbol: '\u20b9'), '\u20b92.5K');
      expect(axisAmountLabel(50000), '50K');
      expect(axisAmountLabel(100000), '1L');
      expect(axisAmountLabel(150000), '1.5L');
      expect(axisAmountLabel(25000000), '2.5Cr');
      expect(axisAmountLabel(-1000), '-1K');
    });
  });

  group('donutSideBySide', () {
    test('stacks on phone widths and sits side by side when the legend has room', () {
      expect(donutSideBySide(347), isFalse);
      expect(donutSideBySide(356), isTrue);
      expect(donutSideBySide(600), isTrue);
    });
  });
}

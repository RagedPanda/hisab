import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/stats/category_shares.dart';

void main() {
  test('sub-categories roll up into their parent; unknown ids are uncategorised', () {
    final rolled = rollUpToParents(
      {'groceries': 300, 'milk': 200, 'food': 100, 'fuel': 50, 'ghost': 25, '': 5},
      {'groceries': 'food', 'milk': 'food', 'food': null, 'fuel': 'transport', 'transport': null, '': null},
    );
    expect(rolled, {'food': 600, 'transport': 50, '': 30});
  });

  test('top five shares, descending, with the rest bucketed as Others', () {
    final shares = categoryShares({'a': 50, 'b': 10, 'c': 20, 'd': 5, 'e': 8, 'f': 4, 'g': 3, 'zero': 0});
    expect(shares.map((s) => s.categoryId), ['a', 'c', 'b', 'e', 'd', null]);
    expect(shares.last.isOthers, isTrue);
    expect(shares.last.minor, 7);
    expect(shares.first.fraction, closeTo(0.5, 0.001));
    expect(sharePercents(shares).fold<int>(0, (sum, p) => sum + p), 100);
  });

  test('no spend gives no shares', () {
    expect(categoryShares({'a': 0}), isEmpty);
    expect(categoryShares({}), isEmpty);
  });

  group('largestRemainderPercents', () {
    int sum(List<int> values) => values.fold(0, (total, value) => total + value);

    test('two shares that round up separately to 101 total 100', () {
      // 62.5% and 37.5% round to 63 + 38 = 101 one at a time.
      expect(largestRemainderPercents([625, 375]), [63, 37]);
    });

    test('three equal thirds total 100, the extra point going to the first', () {
      expect(largestRemainderPercents([1, 1, 1]), [34, 33, 33]);
    });

    test('shares that would round down to 99 total 100', () {
      // 33.4 + 33.3 + 33.3 rounds to 33 + 33 + 33 = 99.
      expect(largestRemainderPercents([334, 333, 333]), [34, 33, 33]);
    });

    test('the point goes to the largest remainder, not the largest share', () {
      expect(largestRemainderPercents([7050, 1980, 970]), [70, 20, 10]);
      expect(sum(largestRemainderPercents([7050, 1980, 970])), 100);
    });

    test('exact shares are untouched', () {
      expect(largestRemainderPercents([50, 25, 25]), [50, 25, 25]);
    });

    test('a single share is 100 and empty or zero input gives zeros', () {
      expect(largestRemainderPercents([42]), [100]);
      expect(largestRemainderPercents([0, 0]), [0, 0]);
      expect(largestRemainderPercents([]), isEmpty);
    });

    test('any mix of amounts totals exactly 100', () {
      const samples = [
        [1, 2, 3, 4, 5, 6],
        [999, 1, 1],
        [12345, 6789, 1011, 1213, 1415, 1617],
        [3, 3, 3, 3, 3, 3, 3],
      ];
      for (final amounts in samples) {
        expect(sum(largestRemainderPercents(amounts)), 100, reason: '$amounts');
      }
    });

    test('sharePercents follows the shares in order', () {
      final shares = categoryShares({'food': 625, 'fuel': 375});
      expect(sharePercents(shares), [63, 37]);
    });
  });
}

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
    expect(shares.map(sharePercent).fold<int>(0, (sum, p) => sum + p), inInclusiveRange(99, 101));
  });

  test('no spend gives no shares', () {
    expect(categoryShares({'a': 0}), isEmpty);
    expect(categoryShares({}), isEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/format.dart';

void main() {
  test('joinWithOverflow shows the first names and a +N tail', () {
    String more(int remaining) => '+$remaining';
    expect(joinWithOverflow(const ['Groceries', 'Restaurants'], max: 3, overflow: more), 'Groceries, Restaurants');
    expect(joinWithOverflow(const ['a', 'b', 'c'], max: 3, overflow: more), 'a, b, c');
    expect(joinWithOverflow(const ['a', 'b', 'c', 'd', 'e'], max: 3, overflow: more), 'a, b, c, +2');
    expect(joinWithOverflow(const <String>[], max: 3, overflow: more), '');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/split/payers.dart';
import 'package:hisab/domain/split/split_calculator.dart';

void main() {
  test('payersFrom keeps members who paid something, in order', () {
    expect(payersFrom({'me': 60000, 'rahul': 0, 'priya': 30000}), const [SplitShare('me', 60000), SplitShare('priya', 30000)]);
    expect(payersFrom({}), isEmpty);
  });

  test('unassignedMinor is what is left to cover, negative when over', () {
    expect(unassignedMinor(90000, const [SplitShare('me', 60000)]), 30000);
    expect(unassignedMinor(90000, const [SplitShare('me', 60000), SplitShare('rahul', 30000)]), 0);
    expect(unassignedMinor(90000, const [SplitShare('me', 100000)]), -10000);
  });

  test('primaryPayerId picks the biggest payer, first on a tie', () {
    expect(primaryPayerId(const [SplitShare('me', 300), SplitShare('rahul', 600)]), 'rahul');
    expect(primaryPayerId(const [SplitShare('me', 500), SplitShare('rahul', 500)]), 'me');
    expect(primaryPayerId(const []), isNull);
  });
}

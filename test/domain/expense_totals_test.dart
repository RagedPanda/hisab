import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/split/expense_totals.dart';

void main() {
  group('sumExpenses', () {
    test('nothing to add gives zero totals', () {
      final totals = sumExpenses(const []);
      expect(totals.totalMinor, 0);
      expect(totals.paidByMember, isEmpty);
      expect(totals.shareByMember, isEmpty);
    });

    test('adds every bill into the total and each member into their own paid and share', () {
      final totals = sumExpenses(const [
        (billMinor: 1000, paidMinor: {'me': 600, 'rahul': 400}, shareMinor: {'me': 500, 'rahul': 300, 'priya': 200}),
        (billMinor: 300, paidMinor: {'priya': 300}, shareMinor: {'me': 100, 'rahul': 100, 'priya': 100}),
      ]);
      expect(totals.totalMinor, 1300);
      expect(totals.paidByMember, {'me': 600, 'rahul': 400, 'priya': 300});
      expect(totals.shareByMember, {'me': 600, 'rahul': 400, 'priya': 300});
    });
  });
}

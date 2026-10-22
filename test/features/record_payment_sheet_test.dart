import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/repositories/groups_repository.dart';
import 'package:hisab/domain/split/debt_simplifier.dart';
import 'package:hisab/features/groups/record_payment_sheet.dart';

void main() {
  // Rahul owes me 2,200 and Priya 700; Priya owes me 500. Simplified, Rahul
  // pays me 2,700 and Priya 200.
  const balances = GroupBalances(
    net: {'me': 2700, 'priya': 200, 'rahul': -2900},
    pairwise: [Transfer('rahul', 'me', 2200), Transfer('rahul', 'priya', 700), Transfer('priya', 'me', 500)],
    suggested: [Transfer('rahul', 'me', 2700), Transfer('rahul', 'priya', 200)],
  );

  test('a simplified suggestion larger than the direct debt is what is owed', () {
    expect(owedBetween(balances, 'rahul', 'me'), 2700);
  });

  test('a direct debt larger than the suggestion is still owed in full', () {
    expect(owedBetween(balances, 'rahul', 'priya'), 700);
    expect(owedBetween(balances, 'priya', 'me'), 500);
  });

  test('nothing is owed in the reverse direction', () {
    expect(owedBetween(balances, 'me', 'rahul'), 0);
  });
}

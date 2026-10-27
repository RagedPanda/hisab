import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/accounts/balance_input.dart';

void main() {
  test('a new card starts as money owed, other accounts as money held', () {
    expect(defaultBalanceNegative('card'), isTrue);
    expect(defaultBalanceNegative('bank'), isFalse);
    expect(defaultBalanceNegative('cash'), isFalse);
  });

  test('the field shows the plain amount and the direction gives the sign', () {
    expect(balanceInputMinor(-124000), 124000);
    expect(balanceInputMinor(50000), 50000);
    expect(signedBalanceFromInput(enteredMinor: 124000, negative: true), -124000);
    expect(signedBalanceFromInput(enteredMinor: 50000, negative: false), 50000);
    expect(signedBalanceFromInput(enteredMinor: 0, negative: true), 0);
  });

  test('editing a card in credit without touching the amount keeps the credit (#98)', () {
    const stored = 50000;
    final negative = stored < 0;
    expect(signedBalanceFromInput(enteredMinor: balanceInputMinor(stored), negative: negative), stored);
  });

  test('a card to bank change keeps money owed as a negative bank balance', () {
    const owedOnCard = -50000;
    final negative = balanceNegativeAfterTypeChange(negative: owedOnCard < 0, enteredMinor: balanceInputMinor(owedOnCard), toType: 'bank');
    expect(signedBalanceFromInput(enteredMinor: balanceInputMinor(owedOnCard), negative: negative), -50000);
  });

  test('a bank to card change keeps money held as card credit', () {
    final negative = balanceNegativeAfterTypeChange(negative: false, enteredMinor: 100000, toType: 'card');
    expect(signedBalanceFromInput(enteredMinor: 100000, negative: negative), 100000);
  });

  test('with nothing entered yet the new type sets the direction', () {
    expect(balanceNegativeAfterTypeChange(negative: false, enteredMinor: 0, toType: 'card'), isTrue);
    expect(balanceNegativeAfterTypeChange(negative: true, enteredMinor: 0, toType: 'bank'), isFalse);
  });
}

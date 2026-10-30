import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/accounts/card_last4.dart';

void main() {
  test('isValidLast4Input takes four digits or nothing', () {
    expect(isValidLast4Input(''), isTrue);
    expect(isValidLast4Input(' 4521 '), isTrue);
    expect(isValidLast4Input('452'), isFalse);
    expect(isValidLast4Input('45210'), isFalse);
    expect(isValidLast4Input('45a1'), isFalse);
  });

  test('last4FromInput stores null for an empty field', () {
    expect(last4FromInput('  '), isNull);
    expect(last4FromInput('4521'), '4521');
  });

  test('smsKeyAfterLast4Edit drops the key once the digits change', () {
    expect(smsKeyAfterLast4Edit(smsKey: 'HDFC Bank:cc:4521', previousLast4: '4521', newLast4: '4521'), 'HDFC Bank:cc:4521');
    expect(smsKeyAfterLast4Edit(smsKey: 'HDFC Bank:cc:4521', previousLast4: '4521', newLast4: '9999'), isNull);
    expect(smsKeyAfterLast4Edit(previousLast4: null, newLast4: '4521'), isNull);
  });
}

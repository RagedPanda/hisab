import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/entries/calculator.dart';

String typeKeys(String keys) {
  var expression = '';
  for (final key in keys.split('')) {
    if (RegExp(r'\d').hasMatch(key)) {
      expression = appendDigit(expression, key);
    } else if (key == '.') {
      expression = appendDot(expression);
    } else if (key == '<') {
      expression = backspace(expression);
    } else {
      expression = appendOperator(expression, key);
    }
  }
  return expression;
}

void main() {
  group('evaluateExpression', () {
    test('a plain number is that amount in minor units', () {
      expect(evaluateExpression('450').minor, 45000);
      expect(evaluateExpression('12.5').minor, 1250);
      expect(evaluateExpression('12.').minor, 1200);
    });

    test('times and divide bind tighter than plus and minus', () {
      expect(evaluateExpression('100+20×3').minor, 16000);
      expect(evaluateExpression('100−20÷4').minor, 9500);
      expect(evaluateExpression('2×3+4×5').minor, 2600);
    });

    test('same-precedence operators run left to right', () {
      expect(evaluateExpression('100−30−20').minor, 5000);
      expect(evaluateExpression('100÷4÷5').minor, 500);
    });

    test('division is exact until the final rounding', () {
      expect(evaluateExpression('100÷3×3').minor, 10000);
      expect(evaluateExpression('100÷3').minor, 3333);
      expect(evaluateExpression('200÷3').minor, 6667);
    });

    test('rounds half up to paise', () {
      expect(evaluateExpression('0.05÷2').minor, 3);
      expect(evaluateExpression('0.01÷3').minor, 0);
    });

    test('rejects empty, malformed, divide by zero, negative and too large', () {
      expect(evaluateExpression('').error, CalcError.empty);
      expect(evaluateExpression('12+').error, CalcError.malformed);
      expect(evaluateExpression('×3').error, CalcError.malformed);
      expect(evaluateExpression('1.234').error, CalcError.malformed);
      expect(evaluateExpression('5÷0').error, CalcError.divideByZero);
      expect(evaluateExpression('5÷0.00').error, CalcError.divideByZero);
      expect(evaluateExpression('10−20').error, CalcError.negative);
      expect(evaluateExpression('999999999999×10').error, CalcError.tooLarge);
      expect(evaluateExpression('999999999999.99').minor, 99999999999999);
    });
  });

  group('previewExpression', () {
    test('ignores a trailing operator or dot', () {
      expect(previewExpression('12+').minor, 1200);
      expect(previewExpression('12+3.').minor, 1500);
      expect(previewExpression('').error, CalcError.empty);
    });
  });

  group('keypad input', () {
    test('builds an expression key by key', () {
      expect(typeKeys('12+3×4'), '12+3×4');
      expect(evaluateExpression(typeKeys('12+3×4')).minor, 2400);
    });

    test('a later operator replaces a trailing one', () {
      expect(typeKeys('12+×'), '12×');
      expect(typeKeys('12.+'), '12+');
    });

    test('an expression cannot start with an operator', () {
      expect(typeKeys('−5'), '5');
    });

    test('keeps at most two decimals and one dot per number', () {
      expect(typeKeys('1.234'), '1.23');
      expect(typeKeys('1..5'), '1.5');
      expect(typeKeys('1.5+2.25'), '1.5+2.25');
    });

    test('a dot with no digits starts at zero', () {
      expect(typeKeys('.5'), '0.5');
      expect(typeKeys('3+.5'), '3+0.5');
    });

    test('a lone leading zero is replaced', () {
      expect(typeKeys('05'), '5');
      expect(typeKeys('0.05'), '0.05');
      expect(typeKeys('3+07'), '3+7');
    });

    test('caps whole digits so the amount cannot overflow', () {
      expect(typeKeys('1234567890123'), '123456789012');
    });

    test('backspace removes the last character', () {
      expect(typeKeys('12+3<'), '12+');
      expect(typeKeys('<'), '');
    });

    test('currentNumber is the text after the last operator', () {
      expect(currentNumber('12+3.4'), '3.4');
      expect(currentNumber('12×'), '');
      expect(currentNumber(''), '');
    });
  });

  group('calcSeed', () {
    test('starts from a valid non-zero amount without separators', () {
      expect(calcSeed('1,250'), '1250');
      expect(calcSeed('12.50'), '12.50');
      expect(calcSeed('0'), '');
      expect(calcSeed('abc'), '');
      expect(calcSeed(''), '');
    });
  });
}

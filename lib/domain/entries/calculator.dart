/// Pure rules for the amount calculator keypad: building an expression one
/// key at a time and evaluating it exactly to minor units.
///
/// Expressions hold non-negative decimal numbers joined by `+`, `−`, `×` and
/// `÷`, the same characters the keypad shows. Arithmetic is done on exact
/// fractions, so `100 ÷ 3 × 3` is exactly 100, and only the final result is
/// rounded (half up) to two decimals.
library;

import '../../core/money.dart';

const String calcPlus = '+';
const String calcMinus = '−';
const String calcTimes = '×';
const String calcDivide = '÷';
const Set<String> calcOperators = {calcPlus, calcMinus, calcTimes, calcDivide};

/// Why an expression has no amount.
enum CalcError { empty, malformed, divideByZero, negative, tooLarge }

/// Outcome of [evaluateExpression]: exactly one of [minor] and [error] is set.
class CalcResult {
  const CalcResult.value(int this.minor) : error = null;
  const CalcResult.failure(CalcError this.error) : minor = null;
  final int? minor;
  final CalcError? error;
  bool get isValue => minor != null;
}

bool _isOperator(String char) => calcOperators.contains(char);

String _lastChar(String expression) => expression.isEmpty ? '' : expression[expression.length - 1];

/// The number currently being typed: everything after the last operator.
String currentNumber(String expression) {
  final lastOperator = expression.split('').lastIndexWhere(_isOperator);
  return expression.substring(lastOperator + 1);
}

/// Appends a digit, keeping at most two decimals and [kMaxAmountWholeDigits]
/// whole digits, and replacing a lone leading `0`.
String appendDigit(String expression, String digit) {
  assert(RegExp(r'^\d$').hasMatch(digit));
  final number = currentNumber(expression);
  final dot = number.indexOf('.');
  if (dot >= 0 && number.length - dot - 1 >= 2) return expression;
  if (dot < 0 && number.length >= kMaxAmountWholeDigits) return expression;
  if (number == '0') return expression.substring(0, expression.length - 1) + digit;
  return expression + digit;
}

/// Starts the decimal part of the current number; `.` alone becomes `0.`.
String appendDot(String expression) {
  final number = currentNumber(expression);
  if (number.contains('.')) return expression;
  return number.isEmpty ? '${expression}0.' : '$expression.';
}

/// Appends an operator, replacing a trailing one. An expression cannot start
/// with an operator, so amounts never go negative by a leading minus.
String appendOperator(String expression, String operator) {
  assert(_isOperator(operator));
  if (expression.isEmpty) return expression;
  final withoutDot = _lastChar(expression) == '.' ? expression.substring(0, expression.length - 1) : expression;
  final trimmed = _isOperator(_lastChar(withoutDot)) ? withoutDot.substring(0, withoutDot.length - 1) : withoutDot;
  return trimmed + operator;
}

String backspace(String expression) => expression.isEmpty ? expression : expression.substring(0, expression.length - 1);

/// Expression to open the keypad with, from the amount field's text: a valid
/// amount without separators, or empty.
String calcSeed(String amountText, {MoneyFormat format = MoneyFormat.inr}) {
  final minor = parseAmountToMinor(amountText, format: format);
  return minor == null || minor == 0 ? '' : amountInputText(minor);
}

/// Exact fraction with a positive denominator.
class _Fraction {
  _Fraction(BigInt numerator, BigInt denominator)
      : numerator = denominator.isNegative ? -numerator : numerator,
        denominator = denominator.abs();
  final BigInt numerator;
  final BigInt denominator;

  _Fraction operator +(_Fraction other) => _Fraction(numerator * other.denominator + other.numerator * denominator, denominator * other.denominator);
  _Fraction operator -(_Fraction other) => _Fraction(numerator * other.denominator - other.numerator * denominator, denominator * other.denominator);
  _Fraction operator *(_Fraction other) => _Fraction(numerator * other.numerator, denominator * other.denominator);
  _Fraction operator /(_Fraction other) => _Fraction(numerator * other.denominator, denominator * other.numerator);

  /// Rounds half up to hundredths.
  BigInt toMinor() {
    final scaled = numerator * BigInt.from(100);
    final twice = scaled * BigInt.two + denominator;
    return twice ~/ (denominator * BigInt.two);
  }
}

final RegExp _numberPattern = RegExp(r'^\d+(?:\.\d{0,2})?$');

_Fraction? _parseNumber(String text) {
  if (!_numberPattern.hasMatch(text)) return null;
  final parts = text.split('.');
  final fraction = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
  return _Fraction(BigInt.parse(parts[0] + fraction), BigInt.from(100));
}

/// Splits an expression into alternating numbers and operators.
List<String> _tokens(String expression) {
  final tokens = <String>[];
  var number = StringBuffer();
  for (final char in expression.split('')) {
    if (_isOperator(char)) {
      tokens
        ..add(number.toString())
        ..add(char);
      number = StringBuffer();
    } else {
      number.write(char);
    }
  }
  tokens.add(number.toString());
  return tokens;
}

/// Evaluates [expression] with `×`/`÷` before `+`/`−`, left to right.
CalcResult evaluateExpression(String expression) {
  final trimmed = expression.replaceAll(' ', '');
  if (trimmed.isEmpty) return const CalcResult.failure(CalcError.empty);
  final tokens = _tokens(trimmed);
  final terms = <_Fraction>[];
  final signs = <String>[];
  var term = _parseNumber(tokens.first);
  if (term == null) return const CalcResult.failure(CalcError.malformed);
  for (var index = 1; index < tokens.length; index += 2) {
    final operator = tokens[index];
    final operand = _parseNumber(tokens[index + 1]);
    if (operand == null) return const CalcResult.failure(CalcError.malformed);
    if (operator == calcTimes) {
      term = term! * operand;
    } else if (operator == calcDivide) {
      if (operand.numerator == BigInt.zero) return const CalcResult.failure(CalcError.divideByZero);
      term = term! / operand;
    } else {
      terms.add(term!);
      signs.add(operator);
      term = operand;
    }
  }
  terms.add(term!);
  var total = terms.first;
  for (var index = 0; index < signs.length; index++) {
    total = signs[index] == calcPlus ? total + terms[index + 1] : total - terms[index + 1];
  }
  final minor = total.toMinor();
  if (minor.isNegative) return const CalcResult.failure(CalcError.negative);
  if (minor > BigInt.from(10).pow(kMaxAmountWholeDigits + 2) - BigInt.one) return const CalcResult.failure(CalcError.tooLarge);
  return CalcResult.value(minor.toInt());
}

/// Value to preview while typing: a trailing operator or dot is ignored, so
/// `12 + ` previews 12.
CalcResult previewExpression(String expression) {
  var trimmed = expression;
  while (trimmed.isNotEmpty && (_isOperator(_lastChar(trimmed)) || _lastChar(trimmed) == '.')) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }
  return evaluateExpression(trimmed);
}

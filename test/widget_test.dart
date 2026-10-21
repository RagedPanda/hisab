import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/money.dart';

void main() {
  test('formatMinor groups Indian style', () {
    expect(formatMinor(123456789), '₹12,34,567.89');
  });
}

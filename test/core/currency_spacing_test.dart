import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/money.dart';
import 'package:hisab/domain/stats/spend_series.dart';

/// Owner decision 21: a symbol of two or more letters gets a space before the
/// amount; a single glyph stays attached. The minus always leads.
void main() {
  group('formatMinor symbol spacing', () {
    const cases = <(String, int, String)>[
      ('₹', 100000, '₹1,000'),
      (r'$', 100000, r'$1,000'),
      ('€', 100000, '€1,000'),
      ('CHF', 100000, 'CHF 1,000'),
      ('Rs', 100000, 'Rs 1,000'),
      ('AED', 100000, 'AED 1,000'),
      ('', 100000, '1,000'),
      ('₹', -100000, '-₹1,000'),
      ('CHF', -100000, '-CHF 1,000'),
      ('Rs', -25050, '-Rs 250.50'),
      ('', -100000, '-1,000'),
      ('AED', 123456789, 'AED 12,34,567.89'),
    ];
    for (final (symbol, minor, expected) in cases) {
      test('${symbol.isEmpty ? 'empty' : symbol} $minor', () => expect(formatMinor(minor, symbol: symbol), expected));
    }
    test('stray spaces around a typed symbol are ignored', () {
      expect(formatMinor(100000, symbol: ' CHF '), 'CHF 1,000');
      expect(formatMinor(100000, symbol: '₹ '), '₹1,000');
    });
    test('compact and whole-unit forms follow the same rule', () {
      expect(formatMinor(25000000, symbol: 'CHF', compact: true), 'CHF 2.50L');
      expect(formatMinor(25000000, symbol: '₹', compact: true), '₹2.50L');
      expect(formatMinor(987667, symbol: 'Rs', showDecimals: false), 'Rs 9,877');
    });
    test('digits are ASCII whatever the app language (en and hi)', () {
      expect(formatMinor(123456789, symbol: '₹'), matches(RegExp(r'^₹[0-9,.]+$')));
    });
  });

  group('withCurrencySymbol', () {
    test('attaches a single glyph', () => expect(withCurrencySymbol('10', symbol: r'$'), r'$10'));
    test('spaces a multi-letter symbol', () => expect(withCurrencySymbol('10', symbol: 'AED'), 'AED 10'));
    test('minus leads the symbol', () => expect(withCurrencySymbol('10', symbol: 'AED', negative: true), '-AED 10'));
  });

  group('axisAmountLabel symbol spacing', () {
    test('single glyph', () => expect(axisAmountLabel(2500, symbol: '₹'), '₹2.5K'));
    test('multi-letter symbol', () => expect(axisAmountLabel(2500, symbol: 'CHF'), 'CHF 2.5K'));
    test('negative multi-letter symbol', () => expect(axisAmountLabel(-100000, symbol: 'Rs'), '-Rs 1L'));
    test('no symbol', () => expect(axisAmountLabel(800), '800'));
  });
}

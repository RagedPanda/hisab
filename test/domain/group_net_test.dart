import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/split/group_net.dart';

void main() {
  test('group nets split into owed-to-me and I-owe totals', () {
    expect(groupNetTotals([1380, -600, 0, 20]), (owedToMe: 1400, iOwe: 600));
    expect(groupNetTotals(const []), (owedToMe: 0, iOwe: 0));
  });

  group('groupNetTotalsByCurrency', () {
    test('keeps each currency apart and puts the app currency first', () {
      final totals = groupNetTotalsByCurrency([
        (symbol: 'AED', net: 140000),
        (symbol: '₹', net: -50000),
        (symbol: r'$', net: 3000),
        (symbol: 'AED', net: -20000),
        (symbol: '₹', net: 10000),
      ], appSymbol: '₹');
      expect(totals, [
        (symbol: '₹', owedToMe: 10000, iOwe: 50000),
        (symbol: r'$', owedToMe: 3000, iOwe: 0),
        (symbol: 'AED', owedToMe: 140000, iOwe: 20000),
      ]);
    });

    test('has an app currency total of zero when no group uses it', () {
      expect(groupNetTotalsByCurrency([(symbol: 'AED', net: 140000)], appSymbol: '₹'), [
        (symbol: '₹', owedToMe: 0, iOwe: 0),
        (symbol: 'AED', owedToMe: 140000, iOwe: 0),
      ]);
      expect(groupNetTotalsByCurrency(const [], appSymbol: '₹'), [(symbol: '₹', owedToMe: 0, iOwe: 0)]);
    });
  });

  group('summarySideAmounts', () {
    const totals = [
      (symbol: '₹', owedToMe: 0, iOwe: 50000),
      (symbol: 'AED', owedToMe: 140000, iOwe: 0),
      (symbol: r'$', owedToMe: 0, iOwe: 0),
    ];

    test('always shows the app currency and only non-zero others', () {
      expect(summarySideAmounts(totals, owedToMe: true), [(symbol: '₹', minor: 0), (symbol: 'AED', minor: 140000)]);
      expect(summarySideAmounts(totals, owedToMe: false), [(symbol: '₹', minor: 50000)]);
    });

    test('a single currency shows exactly one amount per side', () {
      const single = [(symbol: '₹', owedToMe: 0, iOwe: 0)];
      expect(summarySideAmounts(single, owedToMe: true), [(symbol: '₹', minor: 0)]);
      expect(summarySideAmounts(single, owedToMe: false), [(symbol: '₹', minor: 0)]);
    });
  });
}

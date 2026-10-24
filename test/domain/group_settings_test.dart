import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/split/group_settings.dart';
import 'package:hisab/domain/split/split_calculator.dart';

void main() {
  group('GroupType', () {
    test('parses stored names and falls back to other', () {
      expect(GroupType.parse('trip'), GroupType.trip);
      expect(GroupType.parse('couple'), GroupType.couple);
      expect(GroupType.parse(null), GroupType.other);
      expect(GroupType.parse('office'), GroupType.other);
    });

    test('each type has its own default icon', () {
      expect(GroupType.values.map((type) => type.defaultIcon).toSet(), hasLength(GroupType.values.length));
    });
  });

  group('iconAfterTypeChange', () {
    test('follows the new type while the icon is the old default or generic', () {
      expect(iconAfterTypeChange(currentIcon: 'groups', previous: GroupType.other, next: GroupType.trip), 'flight');
      expect(iconAfterTypeChange(currentIcon: 'group', previous: GroupType.other, next: GroupType.home), 'home');
      expect(iconAfterTypeChange(currentIcon: 'flight', previous: GroupType.trip, next: GroupType.couple), 'favorite');
    });

    test('keeps an icon the user picked', () {
      expect(iconAfterTypeChange(currentIcon: 'sports_cricket', previous: GroupType.other, next: GroupType.trip), 'sports_cricket');
      expect(iconAfterTypeChange(currentIcon: 'home', previous: GroupType.trip, next: GroupType.couple), 'home');
    });
  });

  test('default split reads equal, shares and percent, anything else as equal', () {
    expect(parseDefaultSplitMethod('shares'), SplitMethod.shares);
    expect(parseDefaultSplitMethod('percent'), SplitMethod.percent);
    expect(parseDefaultSplitMethod('exact'), SplitMethod.equal);
    expect(parseDefaultSplitMethod(null), SplitMethod.equal);
  });

  test('steppedWeight moves by half a share inside the range', () {
    expect(steppedWeight(1, 1), 1.5);
    expect(steppedWeight(1, -1), 0.5);
    expect(steppedWeight(0.5, -1), minMemberWeight);
    expect(steppedWeight(maxMemberWeight, 1), maxMemberWeight);
  });

  group('currency label', () {
    test('a group without a label follows the app symbol', () {
      expect(groupSymbol(currencyLabel: null, appSymbol: '₹'), '₹');
      expect(groupSymbol(currencyLabel: '  ', appSymbol: '₹'), '₹');
      expect(groupSymbol(currencyLabel: '€', appSymbol: '₹'), '€');
    });

    test('only groups shown in the app symbol count toward app totals', () {
      expect(sharesAppCurrency(currencyLabel: null, appSymbol: '₹'), isTrue);
      expect(sharesAppCurrency(currencyLabel: '₹', appSymbol: '₹'), isTrue);
      expect(sharesAppCurrency(currencyLabel: r'$', appSymbol: '₹'), isFalse);
    });

    test('known symbols store their ISO code, typed ones keep the old code', () {
      expect(currencyCodeFor('€', fallbackCode: 'INR'), 'EUR');
      expect(currencyCodeFor('Rs', fallbackCode: 'INR'), 'INR');
      expect(currencyCodeFor(null, fallbackCode: 'USD'), 'USD');
    });
  });
}

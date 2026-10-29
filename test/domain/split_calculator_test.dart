import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/split/split_calculator.dart';

void main() {
  const asha = 'asha';
  const ravi = 'ravi';

  SplitOutcome split(SplitMethod method, List<SplitInput> inputs, {int totalMinor = 1000, List<ItemSplitInput> items = const []}) =>
      computeSplit(totalMinor: totalMinor, method: method, inputs: inputs, items: items);

  group('exact', () {
    test('amounts above the total report how much is over', () {
      final outcome = split(SplitMethod.exact, const [SplitInput(memberId: asha, amountMinor: 700), SplitInput(memberId: ravi, amountMinor: 500)]);
      expect(outcome.isValid, isFalse);
      expect(outcome.error, const SplitError(SplitErrorCode.amountOver, amountMinor: 200));
    });

    test('a member with zero gets no share line', () {
      final outcome = split(SplitMethod.exact, const [SplitInput(memberId: asha, amountMinor: 1000), SplitInput(memberId: ravi)]);
      expect(outcome.asMap(), {asha: 1000});
    });
  });

  group('percent and shares', () {
    test('a negative weight is rejected', () {
      final outcome = split(SplitMethod.shares, const [SplitInput(memberId: asha, weight: 2), SplitInput(memberId: ravi, weight: -1)]);
      expect(outcome.error, const SplitError(SplitErrorCode.negativeValues));
    });

    test('shares with nobody holding one ask for shares', () {
      final outcome = split(SplitMethod.shares, const [SplitInput(memberId: asha), SplitInput(memberId: ravi)]);
      expect(outcome.error, const SplitError(SplitErrorCode.noShares));
    });

    test('percent with nobody holding one asks for a 100% total', () {
      final outcome = split(SplitMethod.percent, const [SplitInput(memberId: asha)]);
      expect(outcome.error, const SplitError(SplitErrorCode.percentMustTotal));
    });

    test('percentages over 100 report the excess', () {
      final outcome = split(SplitMethod.percent, const [SplitInput(memberId: asha, weight: 70), SplitInput(memberId: ravi, weight: 50)]);
      expect(outcome.error?.code, SplitErrorCode.percentOver);
      expect(outcome.error?.percent, closeTo(20, 0.001));
    });

    test('percentages under 100 report what is left', () {
      final outcome = split(SplitMethod.percent, const [SplitInput(memberId: asha, weight: 60), SplitInput(memberId: ravi, weight: 30)]);
      expect(outcome.error?.code, SplitErrorCode.percentLeft);
    });
  });

  group('adjustment', () {
    test('adjustments larger than the total report the excess', () {
      final outcome = split(SplitMethod.adjustment, const [SplitInput(memberId: asha, amountMinor: 800), SplitInput(memberId: ravi, amountMinor: 400)]);
      expect(outcome.error, const SplitError(SplitErrorCode.adjustmentsExceed, amountMinor: 200));
    });

    test('nobody included is rejected', () {
      final outcome = split(SplitMethod.adjustment, const [SplitInput(memberId: asha, included: false)]);
      expect(outcome.error, const SplitError(SplitErrorCode.nobodyIncluded));
    });
  });

  test('items built at runtime split like const ones', () {
    final members = [asha, ravi];
    final outcome = split(
      SplitMethod.byItem,
      [for (final member in members) SplitInput(memberId: member)],
      totalMinor: 600,
      items: [ItemSplitInput(amountMinor: 400, memberIds: members, label: 'Pizza'), ItemSplitInput(amountMinor: 200, memberIds: [asha])],
    );
    expect(outcome.isValid, isTrue);
    expect(outcome.totalMinor, 600);
    expect(outcome.asMap(), {asha: 400, ravi: 200});
  });
}

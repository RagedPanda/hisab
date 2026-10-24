import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/money.dart';
import 'package:hisab/domain/split/debt_simplifier.dart';
import 'package:hisab/domain/split/split_calculator.dart';

void main() {
  group('money', () {
    test('indian grouping', () {
      expect(groupIndian(0), '0');
      expect(groupIndian(999), '999');
      expect(groupIndian(1000), '1,000');
      expect(groupIndian(123456), '1,23,456');
      expect(groupIndian(12345678), '1,23,45,678');
    });
    test('format and parse', () {
      expect(formatMinor(123456789), '₹12,34,567.89');
      expect(formatMinor(-5000), '-₹50');
      expect(formatMinor(-5000, showDecimals: true), '-₹50.00');
      expect(formatMinor(0), '₹0');
      expect(formatMinor(7050, showDecimals: false), '₹71');
      expect(formatMinor(987667, showDecimals: false), '₹9,877');
      expect(formatMinor(7049, showDecimals: false), '₹70');
      expect(formatMinor(25000000, compact: true), '₹2.50L');
      expect(parseAmountToMinor('1,234.5'), 123450);
      expect(parseAmountToMinor('70'), 7000);
      expect(parseAmountToMinor('abc'), isNull);
      expect(parseAmountToMinor('1.234'), isNull);
    });
    test('oversized input is rejected instead of overflowing (AND-02)', () {
      expect(parseAmountToMinor('9' * 12), 999999999999 * 100);
      expect(parseAmountToMinor('9' * 13), isNull);
      expect(parseAmountToMinor('99999999999999999999'), isNull);
    });
    test('amount fields are seeded without a trailing .00', () {
      expect(amountInputText(124000), '1240');
      expect(amountInputText(124050), '1240.50');
    });
    test('proportional allocation sums exactly', () {
      expect(allocateProportionally(10000, [1, 1, 1]), [3334, 3333, 3333]);
      expect(allocateProportionally(100, [1, 1, 1]), [34, 33, 33]);
      expect(allocateProportionally(1, [1, 1]), [1, 0]);
      expect(allocateProportionally(1000, [0, 0]), [500, 500]);
      final out = allocateProportionally(99999, [3, 7, 11, 0.5]);
      expect(out.fold<int>(0, (a, b) => a + b), 99999);
    });
  });

  group('computeSplit', () {
    const a = 'a', b = 'b', c = 'c';
    test('equal with remainder', () {
      final out = computeSplit(
        totalMinor: 10000,
        method: SplitMethod.equal,
        inputs: const [SplitInput(memberId: a), SplitInput(memberId: b), SplitInput(memberId: c)],
      );
      expect(out.isValid, isTrue);
      expect(out.shares, const [SplitShare(a, 3334), SplitShare(b, 3333), SplitShare(c, 3333)]);
    });
    test('equal excludes unchecked members', () {
      final out = computeSplit(
        totalMinor: 9000,
        method: SplitMethod.equal,
        inputs: const [SplitInput(memberId: a), SplitInput(memberId: b, included: false)],
      );
      expect(out.asMap(), {a: 9000});
      expect(
        computeSplit(totalMinor: 1, method: SplitMethod.equal, inputs: const [SplitInput(memberId: a, included: false)]).error,
        isNotNull,
      );
    });
    test('exact must match total', () {
      final bad = computeSplit(
        totalMinor: 10000,
        method: SplitMethod.exact,
        inputs: const [SplitInput(memberId: a, amountMinor: 4000), SplitInput(memberId: b, amountMinor: 4000)],
      );
      expect(bad.error, const SplitError(SplitErrorCode.amountLeft, amountMinor: 2000));
      final good = computeSplit(
        totalMinor: 10000,
        method: SplitMethod.exact,
        inputs: const [SplitInput(memberId: a, amountMinor: 6000), SplitInput(memberId: b, amountMinor: 4000), SplitInput(memberId: c)],
      );
      expect(good.asMap(), {a: 6000, b: 4000});
    });
    test('percent', () {
      expect(
        computeSplit(totalMinor: 10000, method: SplitMethod.percent, inputs: const [SplitInput(memberId: a, weight: 70), SplitInput(memberId: b, weight: 20)]).error,
        const SplitError(SplitErrorCode.percentLeft, percent: 10),
      );
      final out = computeSplit(
        totalMinor: 10001,
        method: SplitMethod.percent,
        inputs: const [SplitInput(memberId: a, weight: 33.33), SplitInput(memberId: b, weight: 66.67)],
      );
      expect(out.totalMinor, 10001);
      expect(out.asMap()[a], 3333);
    });
    test('shares ratio', () {
      final out = computeSplit(
        totalMinor: 30000,
        method: SplitMethod.shares,
        inputs: const [SplitInput(memberId: a, weight: 2), SplitInput(memberId: b, weight: 1), SplitInput(memberId: c, weight: 0)],
      );
      expect(out.asMap(), {a: 20000, b: 10000});
    });
    test('adjustment: extras then equal remainder', () {
      final out = computeSplit(
        totalMinor: 10000,
        method: SplitMethod.adjustment,
        inputs: const [SplitInput(memberId: a, amountMinor: 1000), SplitInput(memberId: b), SplitInput(memberId: c)],
      );
      expect(out.asMap(), {a: 4000, b: 3000, c: 3000});
    });
    test('by item with shared tax', () {
      final out = computeSplit(
        totalMinor: 11000,
        method: SplitMethod.byItem,
        inputs: const [],
        items: const [
          ItemSplitInput(amountMinor: 6000, memberIds: [a], label: 'Biryani'),
          ItemSplitInput(amountMinor: 4000, memberIds: [a, b], label: 'Naan'),
        ],
      );
      // a: 6000+2000 = 8000 of 10000 -> 80% of 1000 tax = 800
      expect(out.asMap(), {a: 8800, b: 2200});
      expect(out.totalMinor, 11000);
    });
  });

  group('member removal', () {
    test('AND-08: net zero but caught between pairwise debts is not settled', () {
      final transfers = [const Transfer('bina', 'me', 15000), const Transfer('chetan', 'bina', 15000)];
      final net = {'me': 15000, 'bina': 0, 'chetan': -15000};
      expect(isMemberSettled(memberId: 'bina', net: net, transfers: transfers), isFalse);
      expect(isMemberSettled(memberId: 'me', net: net, transfers: transfers), isFalse);
    });
    test('fully settled member can be removed', () {
      expect(isMemberSettled(memberId: 'bina', net: {'bina': 0, 'me': 0}, transfers: const []), isTrue);
      expect(isMemberSettled(memberId: 'bina', net: {'me': 500, 'chetan': -500}, transfers: [const Transfer('chetan', 'me', 500)]), isTrue);
    });
  });

  group('debts', () {
    test('net balances and simplification', () {
      final net = computeNetBalances(
        memberIds: ['a', 'b', 'c'],
        expenses: [
          LedgerExpense(paidByMemberId: 'a', shares: const [SplitShare('a', 1000), SplitShare('b', 1000), SplitShare('c', 1000)]),
          LedgerExpense(paidByMemberId: 'b', shares: const [SplitShare('a', 500), SplitShare('b', 500)]),
        ],
        settlements: const [LedgerSettlement(fromMemberId: 'c', toMemberId: 'a', amountMinor: 400)],
      );
      expect(net, {'a': 1100, 'b': -500, 'c': -600});
      expect(net.values.fold<int>(0, (s, v) => s + v), 0);
      final transfers = simplifyDebts(net);
      expect(transfers, const [Transfer('c', 'a', 600), Transfer('b', 'a', 500)]);
    });
    test('simplification removes chains', () {
      // b owes a 100, c owes b 100 -> c pays a 100 directly
      final transfers = simplifyDebts({'a': 100, 'b': 0, 'c': -100});
      expect(transfers, const [Transfer('c', 'a', 100)]);
    });
    test('pairwise keeps direct debts', () {
      final debts = pairwiseDebts(
        expenses: [
          LedgerExpense(paidByMemberId: 'a', shares: const [SplitShare('b', 100)]),
          LedgerExpense(paidByMemberId: 'b', shares: const [SplitShare('c', 100)]),
        ],
        settlements: const [LedgerSettlement(fromMemberId: 'b', toMemberId: 'a', amountMinor: 30)],
      );
      expect(debts, const [Transfer('c', 'b', 100), Transfer('b', 'a', 70)]);
    });
    test('two payers: each sharer owes the payers what they are down', () {
      // 900 dinner, a paid 600 and b paid 300, split three ways (300 each).
      const dinner = LedgerExpense.multi(
        payers: [SplitShare('a', 600), SplitShare('b', 300)],
        shares: [SplitShare('a', 300), SplitShare('b', 300), SplitShare('c', 300)],
      );
      expect(dinner.netByMember, {'a': 300, 'b': 0, 'c': -300});
      expect(computeNetBalances(memberIds: ['a', 'b', 'c'], expenses: const [dinner], settlements: const []), {'a': 300, 'b': 0, 'c': -300});
      expect(pairwiseDebts(expenses: const [dinner], settlements: const []), const [Transfer('c', 'a', 300)]);
    });
    test('a single payer matches the multi form with one payer', () {
      final single = LedgerExpense(paidByMemberId: 'a', shares: const [SplitShare('a', 250), SplitShare('b', 750)]);
      expect(single.payers, const [SplitShare('a', 1000)]);
      const multi = LedgerExpense.multi(payers: [SplitShare('a', 1000)], shares: [SplitShare('a', 250), SplitShare('b', 750)]);
      expect(pairwiseDebts(expenses: [single], settlements: const []), pairwiseDebts(expenses: const [multi], settlements: const []));
    });
    test('two payers who both owe a third and each other net out per expense', () {
      // 1000 paid 700 by a and 300 by b, split equally four ways (250 each).
      const taxi = LedgerExpense.multi(
        payers: [SplitShare('a', 700), SplitShare('b', 300)],
        shares: [SplitShare('a', 250), SplitShare('b', 250), SplitShare('c', 250), SplitShare('d', 250)],
      );
      final debts = pairwiseDebts(expenses: const [taxi], settlements: const []);
      expect(debts.fold<int>(0, (sum, debt) => sum + debt.amountMinor), 500, reason: 'a is up 450 and b up 50; c and d are down 250 each');
      expect(debts.every((debt) => debt.to == 'a' || debt.to == 'b'), isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/split/group_recurring.dart';
import 'package:hisab/domain/split/split_calculator.dart';

void main() {
  const everyone = {'me', 'ravi', 'priya'};
  const equalRent = GroupExpenseTemplate(
    method: SplitMethod.equal,
    paidByMemberId: 'me',
    inputs: [SplitInput(memberId: 'me'), SplitInput(memberId: 'ravi'), SplitInput(memberId: 'priya')],
  );

  group('groupOccurrence', () {
    test('repeats an equal split with the same payer', () {
      final occurrence = groupOccurrence(equalRent, amountMinor: 1500000, activeMemberIds: everyone);
      expect(occurrence.canPost, isTrue);
      expect(occurrence.paidByMemberId, 'me');
      expect(occurrence.payers, isEmpty);
      expect(occurrence.splits.map((split) => split.amountMinor).reduce((a, b) => a + b), 1500000);
      expect(occurrence.splits.map((split) => split.memberId), ['me', 'ravi', 'priya']);
    });

    test('a member who left drops out and the rest share the bill', () {
      final occurrence = groupOccurrence(equalRent, amountMinor: 1000000, activeMemberIds: {'me', 'ravi'});
      expect(occurrence.splits, const [OccurrenceSplit(memberId: 'me', amountMinor: 500000, shareValue: 0), OccurrenceSplit(memberId: 'ravi', amountMinor: 500000, shareValue: 0)]);
    });

    test('a payer who left blocks the occurrence', () {
      final occurrence = groupOccurrence(equalRent, amountMinor: 1000000, activeMemberIds: {'ravi', 'priya'});
      expect(occurrence.problem, GroupOccurrenceProblem.payerLeft);
      expect(occurrence.canPost, isFalse);
    });

    test('exact amounts keep their typed shares as share values', () {
      const wifi = GroupExpenseTemplate(
        method: SplitMethod.exact,
        paidByMemberId: 'ravi',
        inputs: [SplitInput(memberId: 'me', amountMinor: 30000), SplitInput(memberId: 'ravi', amountMinor: 70000)],
      );
      final occurrence = groupOccurrence(wifi, amountMinor: 100000, activeMemberIds: everyone);
      expect(occurrence.splits, const [OccurrenceSplit(memberId: 'me', amountMinor: 30000, shareValue: 30000), OccurrenceSplit(memberId: 'ravi', amountMinor: 70000, shareValue: 70000)]);
    });

    test('an exact split no longer adding up is blocked, not guessed', () {
      const wifi = GroupExpenseTemplate(
        method: SplitMethod.exact,
        paidByMemberId: 'me',
        inputs: [SplitInput(memberId: 'me', amountMinor: 30000), SplitInput(memberId: 'priya', amountMinor: 70000)],
      );
      expect(groupOccurrence(wifi, amountMinor: 100000, activeMemberIds: {'me', 'ravi'}).problem, GroupOccurrenceProblem.splitInvalid);
    });

    test('shares are respread over remaining members by weight', () {
      const maid = GroupExpenseTemplate(
        method: SplitMethod.shares,
        paidByMemberId: 'me',
        inputs: [SplitInput(memberId: 'me', weight: 2), SplitInput(memberId: 'ravi', weight: 1), SplitInput(memberId: 'priya', weight: 1)],
      );
      final occurrence = groupOccurrence(maid, amountMinor: 300000, activeMemberIds: {'me', 'ravi'});
      expect(occurrence.splits.map((split) => split.amountMinor), [200000, 100000]);
      expect(occurrence.splits.first.shareValue, 2);
    });

    test('several payers are carried over with the biggest as main payer', () {
      const shared = GroupExpenseTemplate(
        method: SplitMethod.equal,
        paidByMemberId: 'ravi',
        inputs: [SplitInput(memberId: 'me'), SplitInput(memberId: 'ravi')],
        payers: [SplitShare('me', 40000), SplitShare('ravi', 60000)],
      );
      final occurrence = groupOccurrence(shared, amountMinor: 100000, activeMemberIds: everyone);
      expect(occurrence.payers, const [SplitShare('me', 40000), SplitShare('ravi', 60000)]);
      expect(occurrence.paidByMemberId, 'ravi');
    });

    test('payers that no longer cover the amount block the occurrence', () {
      const shared = GroupExpenseTemplate(
        method: SplitMethod.equal,
        paidByMemberId: 'ravi',
        inputs: [SplitInput(memberId: 'me'), SplitInput(memberId: 'ravi')],
        payers: [SplitShare('me', 40000), SplitShare('ravi', 60000)],
      );
      expect(groupOccurrence(shared, amountMinor: 120000, activeMemberIds: everyone).problem, GroupOccurrenceProblem.splitInvalid);
    });

    test('a lone payer row is treated as a single payer', () {
      const single = GroupExpenseTemplate(method: SplitMethod.equal, paidByMemberId: 'me', inputs: [SplitInput(memberId: 'me')], payers: [SplitShare('me', 100)]);
      expect(groupOccurrence(single, amountMinor: 100, activeMemberIds: everyone).payers, isEmpty);
    });
  });

  group('GroupExpenseTemplate encoding', () {
    test('round-trips through its stored text', () {
      const template = GroupExpenseTemplate(
        method: SplitMethod.percent,
        paidByMemberId: 'ravi',
        inputs: [SplitInput(memberId: 'me', weight: 40), SplitInput(memberId: 'ravi', included: false, amountMinor: 5, weight: 60)],
        payers: [SplitShare('me', 10), SplitShare('ravi', 90)],
      );
      final decoded = GroupExpenseTemplate.decode(template.encode())!;
      expect(decoded.toJson(), template.toJson());
    });

    test('missing or broken text decodes to null', () {
      expect(GroupExpenseTemplate.decode(null), isNull);
      expect(GroupExpenseTemplate.decode(''), isNull);
      expect(GroupExpenseTemplate.decode('{not json'), isNull);
      expect(GroupExpenseTemplate.decode('{"method":"nope","paidBy":"me"}'), isNull);
    });
  });

  test('shareValueFor keeps the amount for exact and adjustment, the weight otherwise', () {
    const input = SplitInput(memberId: 'me', amountMinor: 250, weight: 3);
    expect(shareValueFor(SplitMethod.exact, input), 250);
    expect(shareValueFor(SplitMethod.adjustment, input), 250);
    expect(shareValueFor(SplitMethod.shares, input), 3);
    expect(shareValueFor(SplitMethod.equal, null), isNull);
  });
}

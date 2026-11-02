import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/split/debt_simplifier.dart';
import 'package:hisab/domain/split/settle_with_person.dart';

/// A group as the sheet sees it, with Amit's email in it by default.
PersonSettleGroup ledger(String id, List<Transfer> suggested, {String symbol = '₹', String? me = 'me', Map<String, String?>? emails}) => (
      groupId: id,
      symbol: symbol,
      myMemberId: me,
      emailByMemberId: emails ?? {'me': 'me@x.com', '$id-amit': 'amit@x.com', '$id-priya': null},
      suggested: suggested,
    );

/// The group's Settle up list after recording [payments], as the repository
/// would recompute it: simplified from the net balances.
List<Transfer> simplifiedAfter(Map<String, int> net, List<Transfer> payments) {
  final after = Map.of(net);
  for (final payment in payments) {
    after.update(payment.from, (value) => value + payment.amountMinor, ifAbsent: () => payment.amountMinor);
    after.update(payment.to, (value) => value - payment.amountMinor, ifAbsent: () => -payment.amountMinor);
  }
  return simplifyDebts(after);
}

void main() {
  group('pairNet', () {
    test('they owe me is positive, I owe them is negative, others are ignored', () {
      const transfers = [Transfer('amit', 'me', 500), Transfer('me', 'amit', 200), Transfer('priya', 'me', 900), Transfer('amit', 'priya', 50)];
      expect(pairNet(transfers, me: 'me', them: 'amit'), 300);
      expect(pairNet(transfers, me: 'me', them: 'priya'), 900);
      expect(pairNet(const [Transfer('me', 'amit', 700)], me: 'me', them: 'amit'), -700);
      expect(pairNet(const [], me: 'me', them: 'amit'), 0);
    });
  });

  group('personShares', () {
    final goa = ledger('goa', const [Transfer('goa-amit', 'me', 1500), Transfer('me', 'goa-priya', 400)]);
    final flat = ledger('flat', const [Transfer('me', 'flat-amit', 600)]);
    final office = ledger('office', const [Transfer('office-priya', 'me', 100)]);

    test('this group only: the one balance with that member, signed', () {
      expect(personShares([goa, flat], groupId: 'goa', memberId: 'goa-amit'), [
        const PersonGroupShare(groupId: 'goa', symbol: '₹', myMemberId: 'me', theirMemberId: 'goa-amit', netMinor: 1500),
      ]);
      expect(personShares([goa, flat], groupId: 'goa', memberId: 'goa-priya').single.netMinor, -400);
    });

    test('all groups: the same email in other groups, opening group first', () {
      final shares = personShares([flat, goa, office], groupId: 'goa', memberId: 'goa-amit', allGroups: true);
      expect([for (final share in shares) (share.groupId, share.theirMemberId, share.netMinor)], [('goa', 'goa-amit', 1500), ('flat', 'flat-amit', -600)]);
    });

    test('the email matches ignoring case and spaces', () {
      final shouty = ledger('trip', const [Transfer('me', 'trip-amit', 100)], emails: {'me': null, 'trip-amit': '  AMIT@X.com '});
      expect(personShares([goa, shouty], groupId: 'goa', memberId: 'goa-amit', allGroups: true).map((share) => share.groupId), ['goa', 'trip']);
    });

    test('a member without an email is only themselves, even in all groups', () {
      final otherPriya = ledger('trip', const [Transfer('trip-priya', 'me', 100)], emails: {'me': null, 'trip-priya': null});
      expect(personShares([goa, otherPriya], groupId: 'goa', memberId: 'goa-priya', allGroups: true).map((share) => share.groupId), ['goa']);
    });

    test('square groups are left out, and a square opening group still finds the others', () {
      final square = ledger('goa', const [Transfer('goa-priya', 'me', 100)]);
      expect(personShares([square, flat], groupId: 'goa', memberId: 'goa-amit'), isEmpty);
      expect(personShares([square, flat], groupId: 'goa', memberId: 'goa-amit', allGroups: true).single.groupId, 'flat');
    });

    test('groups I am not in, and my own row, are never settled', () {
      final notMine = ledger('club', const [Transfer('club-amit', 'club-priya', 100)], me: null);
      expect(personShares([goa, notMine], groupId: 'goa', memberId: 'goa-amit', allGroups: true).map((share) => share.groupId), ['goa']);
      expect(personShares([goa], groupId: 'goa', memberId: 'me'), isEmpty);
      // My own email on another group's member never makes them "Amit".
      final meAgain = ledger('trip', const [Transfer('me', 'trip-x', 100)], emails: {'me': 'amit@x.com', 'trip-x': 'other@x.com'});
      expect(personShares([goa, meAgain], groupId: 'goa', memberId: 'goa-amit', allGroups: true).map((share) => share.groupId), ['goa']);
    });

    test('an unknown group gives nothing', () {
      expect(personShares([goa], groupId: 'nope', memberId: 'goa-amit', allGroups: true), isEmpty);
    });

    test('hasBalancesInOtherGroups only when another group is not square', () {
      expect(hasBalancesInOtherGroups([goa, flat], groupId: 'goa', memberId: 'goa-amit'), isTrue);
      expect(hasBalancesInOtherGroups([goa, office], groupId: 'goa', memberId: 'goa-amit'), isFalse);
      expect(hasBalancesInOtherGroups([goa, flat], groupId: 'goa', memberId: 'goa-priya'), isFalse);
    });
  });

  group('settlesWithOthersIn', () {
    test('true when they are in this group\'s Settle up list, even if not with me', () {
      final routed = ledger('sq', const [Transfer('sq-asha', 'sq-ben', 100)], emails: {'me': null, 'sq-asha': null, 'sq-ben': null, 'sq-chetan': null});
      expect(settlesWithOthersIn([routed], groupId: 'sq', memberId: 'sq-asha'), isTrue);
      expect(settlesWithOthersIn([routed], groupId: 'sq', memberId: 'sq-ben'), isTrue);
      expect(settlesWithOthersIn([routed], groupId: 'sq', memberId: 'sq-chetan'), isFalse);
      expect(settlesWithOthersIn([routed], groupId: 'other', memberId: 'sq-asha'), isFalse);
    });
  });

  group('settlement', () {
    test('they owe me: they pay me; I owe them: I pay them', () {
      const owedToMe = PersonGroupShare(groupId: 'g', symbol: '₹', myMemberId: 'me', theirMemberId: 'amit', netMinor: 1500);
      const iOwe = PersonGroupShare(groupId: 'g', symbol: '₹', myMemberId: 'me', theirMemberId: 'amit', netMinor: -600);
      expect(owedToMe.settlement, const Transfer('amit', 'me', 1500));
      expect(iOwe.settlement, const Transfer('me', 'amit', 600));
    });

    test('recording each group\'s settlement leaves nothing between us there', () {
      // Simplified group: Amit owes me 1,500 and Priya 300; I owe Ravi 200.
      const net = {'me': 1300, 'amit': -1800, 'priya': 300, 'ravi': 200};
      final settle = ledger('g', simplifyDebts(net), emails: {'me': null, 'amit': 'amit@x.com', 'priya': null, 'ravi': null});
      final share = personShares([settle], groupId: 'g', memberId: 'amit').single;
      final after = simplifiedAfter(net, [share.settlement]);
      expect(pairNet(after, me: 'me', them: 'amit'), 0);
      expect(after.fold(0, (sum, transfer) => sum + transfer.amountMinor), greaterThan(0), reason: 'other debts stay');
    });
  });

  group('personTotals', () {
    PersonGroupShare share(String symbol, int net) => PersonGroupShare(groupId: 'g$net', symbol: symbol, myMemberId: 'me', theirMemberId: 'amit', netMinor: net);

    test('nets groups in the same currency and keeps currencies apart, in first-seen order', () {
      expect(personTotals([share('₹', 1500), share(r'$', -20), share('₹', -600)]), [(symbol: '₹', netMinor: 900), (symbol: r'$', netMinor: -20)]);
    });

    test('groups that cancel out total zero', () {
      expect(personTotals([share('₹', 500), share('₹', -500)]), [(symbol: '₹', netMinor: 0)]);
      expect(personTotals(const []), isEmpty);
    });

    test('a UPI amount only when one currency and I owe overall', () {
      expect(singleCurrencyAmountIOwe([share('₹', 500), share('₹', -800)]), 300);
      expect(singleCurrencyAmountIOwe([share('₹', 500), share('₹', -200)]), isNull);
      expect(singleCurrencyAmountIOwe([share('₹', -500), share(r'$', -200)]), isNull);
      expect(singleCurrencyAmountIOwe([share('₹', 500), share('₹', -500)]), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/udhaar/udhaar.dart';

UdhaarLine line(String personId, UdhaarKind kind, int amountMinor, {int day = 1}) =>
    (personId: personId, kind: kind, amountMinor: amountMinor, occurredAt: DateTime(2026, 10, day));

void main() {
  group('UdhaarKind', () {
    test('round-trips its stored key and ignores other values', () {
      for (final kind in UdhaarKind.values) {
        expect(UdhaarKind.parse(kind.storageKey), kind);
      }
      expect(UdhaarKind.parse(null), isNull);
      expect(UdhaarKind.parse('gift'), isNull);
    });

    test('lent and paid back are money out; borrowed and got back are money in', () {
      expect(UdhaarKind.lent.isMoneyOut, isTrue);
      expect(UdhaarKind.repaidByMe.isMoneyOut, isTrue);
      expect(UdhaarKind.borrowed.isMoneyOut, isFalse);
      expect(UdhaarKind.repaidToMe.isMoneyOut, isFalse);
    });

    test('money out raises what they owe me, money in lowers it', () {
      expect(UdhaarKind.lent.balanceEffect(500), 500);
      expect(UdhaarKind.repaidByMe.balanceEffect(500), 500);
      expect(UdhaarKind.borrowed.balanceEffect(500), -500);
      expect(UdhaarKind.repaidToMe.balanceEffect(500), -500);
    });
  });

  group('udhaarAccounts', () {
    test('money out leaves the account, money in arrives in it', () {
      expect(udhaarAccounts(UdhaarKind.lent, 'cash'), (from: 'cash', to: null));
      expect(udhaarAccounts(UdhaarKind.repaidToMe, 'cash'), (from: null, to: 'cash'));
    });

    test('udhaarAccountOf reads back the one account either way', () {
      for (final kind in UdhaarKind.values) {
        final accounts = udhaarAccounts(kind, 'bank');
        expect(udhaarAccountOf(from: accounts.from, to: accounts.to), 'bank');
      }
    });
  });

  group('balances', () {
    final lines = [
      line('rahul', UdhaarKind.lent, 300000),
      line('rahul', UdhaarKind.repaidToMe, 50000),
      line('priya', UdhaarKind.borrowed, 80000),
      line('amit', UdhaarKind.lent, 10000),
      line('amit', UdhaarKind.repaidToMe, 10000),
    ];

    test('udhaarBalance nets one person', () {
      expect(udhaarBalance(lines, 'rahul'), 250000);
      expect(udhaarBalance(lines, 'priya'), -80000);
      expect(udhaarBalance(lines, 'nobody'), 0);
    });

    test('udhaarBalances covers everyone with an entry, settled ones at zero', () {
      expect(udhaarBalances(lines), {'rahul': 250000, 'priya': -80000, 'amit': 0});
      expect(udhaarBalances(const []), isEmpty);
    });

    test('outstandingPeople drops settled people and sorts by size either way', () {
      expect(outstandingPeople({'a': 100, 'b': -500, 'c': 0, 'd': 300}), ['b', 'd', 'a']);
      expect(outstandingPeople({'z': 100, 'y': -100}), ['y', 'z']);
    });

    test('udhaarTotals splits owed to me from what I owe', () {
      expect(udhaarTotals({'a': 100, 'b': -500, 'c': 0, 'd': 300}), (owedToMe: 400, iOwe: 500));
      expect(udhaarTotals(const {}), (owedToMe: 0, iOwe: 0));
    });
  });

  group('outstandingSince', () {
    test('is the entry that started the current balance', () {
      final lines = [
        line('rahul', UdhaarKind.lent, 1000, day: 1),
        line('rahul', UdhaarKind.repaidToMe, 1000, day: 3),
        line('rahul', UdhaarKind.lent, 2500, day: 12),
        line('rahul', UdhaarKind.lent, 500, day: 20),
      ];
      expect(outstandingSince(lines), DateTime(2026, 10, 12));
    });

    test('follows a balance that flips sides, whatever the input order', () {
      final lines = [
        line('rahul', UdhaarKind.repaidByMe, 1500, day: 9),
        line('rahul', UdhaarKind.borrowed, 1000, day: 2),
      ];
      expect(outstandingSince(lines), DateTime(2026, 10, 9));
    });

    test('is null when settled or empty', () {
      expect(outstandingSince([line('a', UdhaarKind.lent, 100), line('a', UdhaarKind.repaidToMe, 100, day: 2)]), isNull);
      expect(outstandingSince(const []), isNull);
    });
  });

  test('repaymentKindFor settles the balance from the right side', () {
    expect(repaymentKindFor(100), UdhaarKind.repaidToMe);
    expect(repaymentKindFor(-100), UdhaarKind.repaidByMe);
    expect(repaymentKindFor(0), isNull);
  });

  test('balancesAfter walks a newest-first timeline back to zero', () {
    final newestFirst = [
      line('rahul', UdhaarKind.repaidToMe, 500, day: 3),
      line('rahul', UdhaarKind.borrowed, 200, day: 2),
      line('rahul', UdhaarKind.lent, 3000, day: 1),
    ];
    expect(balancesAfter(newestFirst), [2300, 2800, 3000]);
    expect(balancesAfter(const []), isEmpty);
  });
}

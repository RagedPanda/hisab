import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/split/debt_simplifier.dart';
import 'package:hisab/domain/split/group_timeline.dart';
import 'package:hisab/domain/split/split_calculator.dart';

TimelineExpense _expense(DateTime when, String payer, Map<String, int> shares) =>
    TimelineExpense(occurredAt: when, paidMinor: {payer: shares.values.fold(0, (sum, amount) => sum + amount)}, shareMinor: shares);

TimelinePayment _payment(DateTime when, String from, String to, int amount) =>
    TimelinePayment(occurredAt: when, fromMemberId: from, toMemberId: to, amountMinor: amount);

void main() {
  group('settledUpPoint', () {
    test('a group that never squared up has no settled point', () {
      final expenses = [_expense(DateTime(2026, 10, 1), 'me', {'me': 500, 'rahul': 500})];
      expect(settledUpPoint(expenses: expenses, payments: const []), isNull);
      expect(settledUpPoint(expenses: const [], payments: const []), isNull);
    });

    test('the day a payment clears every balance is the settled point', () {
      final expenses = [
        _expense(DateTime(2026, 10, 1, 20), 'me', {'me': 500, 'rahul': 500}),
        _expense(DateTime(2026, 10, 20), 'rahul', {'me': 300, 'rahul': 300}),
      ];
      final payments = [_payment(DateTime(2026, 10, 14), 'rahul', 'me', 500)];
      expect(settledUpPoint(expenses: expenses, payments: payments), DateTime(2026, 10, 14));
    });

    test('the latest square day wins when the group squares up twice', () {
      final expenses = [
        _expense(DateTime(2026, 9, 1), 'me', {'me': 500, 'rahul': 500}),
        _expense(DateTime(2026, 9, 10), 'me', {'me': 200, 'priya': 200}),
      ];
      final payments = [
        _payment(DateTime(2026, 9, 5), 'rahul', 'me', 500),
        _payment(DateTime(2026, 9, 12), 'priya', 'me', 200),
      ];
      expect(settledUpPoint(expenses: expenses, payments: payments), DateTime(2026, 9, 12));
    });

    test('a payment earlier on the same day as its expense still settles that day', () {
      final expenses = [_expense(DateTime(2026, 10, 3, 21), 'me', {'me': 500, 'rahul': 500})];
      final payments = [_payment(DateTime(2026, 10, 3), 'rahul', 'me', 500)];
      expect(settledUpPoint(expenses: expenses, payments: payments), DateTime(2026, 10, 3));
    });

    test('a partial payment is not a settled point', () {
      final expenses = [_expense(DateTime(2026, 10, 1), 'me', {'me': 500, 'rahul': 500})];
      final payments = [_payment(DateTime(2026, 10, 2), 'rahul', 'me', 499)];
      expect(settledUpPoint(expenses: expenses, payments: payments), isNull);
    });

    test('an expense someone paid only for themselves leaves the group square', () {
      final expenses = [_expense(DateTime(2026, 10, 5), 'me', {'me': 800})];
      expect(settledUpPoint(expenses: expenses, payments: const []), DateTime(2026, 10, 5));
    });
  });

  group('expenseEffectFor', () {
    final dinner = _expense(DateTime(2026, 10, 1), 'me', {'me': 300, 'rahul': 300, 'priya': 300});

    test('the payer lent everyone else their shares', () {
      expect(expenseEffectFor('me', dinner), (kind: ExpenseEffectKind.lent, amountMinor: 600));
    });

    test('a member with a share borrowed it', () {
      expect(expenseEffectFor('rahul', dinner), (kind: ExpenseEffectKind.borrowed, amountMinor: 300));
    });

    test('a member outside the split is not involved', () {
      expect(expenseEffectFor('bina', dinner), (kind: ExpenseEffectKind.notInvolved, amountMinor: 0));
      expect(expenseEffectFor(null, dinner), (kind: ExpenseEffectKind.notInvolved, amountMinor: 0));
    });

    test('paying only for yourself reads as paid, not lent', () {
      final solo = _expense(DateTime(2026, 10, 1), 'me', {'me': 800});
      expect(expenseEffectFor('me', solo), (kind: ExpenseEffectKind.paidOwnShare, amountMinor: 800));
    });

    test('with several payers each sees their own difference', () {
      final shared = TimelineExpense(
        occurredAt: DateTime(2026, 10, 1),
        paidMinor: {'me': 600, 'rahul': 300},
        shareMinor: {'me': 300, 'rahul': 300, 'priya': 300},
      );
      expect(expenseEffectFor('me', shared), (kind: ExpenseEffectKind.lent, amountMinor: 300));
      expect(expenseEffectFor('rahul', shared), (kind: ExpenseEffectKind.paidOwnShare, amountMinor: 300));
      expect(expenseEffectFor('priya', shared), (kind: ExpenseEffectKind.borrowed, amountMinor: 300));
    });
  });

  test('involvement covers payers, sharers and both sides of a payment', () {
    final dinner = _expense(DateTime(2026, 10, 1), 'rahul', {'rahul': 300, 'priya': 300});
    expect(expenseInvolves('rahul', dinner), isTrue);
    expect(expenseInvolves('priya', dinner), isTrue);
    expect(expenseInvolves('me', dinner), isFalse);
    final payment = _payment(DateTime(2026, 10, 2), 'priya', 'rahul', 300);
    expect(paymentInvolves('priya', payment), isTrue);
    expect(paymentInvolves('rahul', payment), isTrue);
    expect(paymentInvolves('me', payment), isFalse);
    expect(paymentInvolves(null, payment), isFalse);
  });

  test('a ledger expense becomes one payer of the summed shares', () {
    final timeline = timelineExpenseOf(
      DateTime(2026, 10, 1),
      const LedgerExpense(paidByMemberId: 'me', shares: [SplitShare('me', 250), SplitShare('rahul', 250), SplitShare('rahul', 100)]),
    );
    expect(timeline.paidMinor, {'me': 600});
    expect(timeline.shareMinor, {'me': 250, 'rahul': 350});
  });
}

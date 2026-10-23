import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/domain/split/debt_simplifier.dart';
import 'package:hisab/domain/split/group_timeline.dart';
import 'package:hisab/domain/split/group_totals.dart';
import 'package:hisab/domain/split/split_calculator.dart';

GroupTotalsExpense _expense(DateTime when, {required Map<String, int> paid, required Map<String, int> shares, String? category}) => GroupTotalsExpense(
  expense: TimelineExpense(occurredAt: when, paidMinor: paid, shareMinor: shares),
  categoryId: category,
);

void main() {
  group('computeGroupTotals', () {
    test('no expenses gives zero totals', () {
      final totals = computeGroupTotals(expenses: const [], myMemberId: 'me');
      expect(totals.totalSpentMinor, 0);
      expect(totals.myPaidMinor, 0);
      expect(totals.myShareMinor, 0);
      expect(totals.byMember, isEmpty);
      expect(totals.byCategory, isEmpty);
      expect(totals.expenseCount, 0);
    });

    test('one payer, equal split: total, my paid, my share and net change', () {
      final totals = computeGroupTotals(
        myMemberId: 'me',
        expenses: [
          _expense(DateTime(2026, 10, 1), paid: {'me': 900}, shares: {'me': 300, 'rahul': 300, 'priya': 300}, category: 'food'),
        ],
      );
      expect(totals.totalSpentMinor, 900);
      expect(totals.myPaidMinor, 900);
      expect(totals.myShareMinor, 300);
      expect(totals.myNetChangeMinor, 600);
      expect(totals.byCategory, {'food': 900});
    });

    test('several payers and an unequal split credit each payer their own amount', () {
      // Rahul and I paid 1000 together (600 + 400); shares by percent 50/30/20.
      final split = computeSplit(
        totalMinor: 1000,
        method: SplitMethod.percent,
        inputs: const [
          SplitInput(memberId: 'me', weight: 50),
          SplitInput(memberId: 'rahul', weight: 30),
          SplitInput(memberId: 'priya', weight: 20),
        ],
      );
      final ledger = LedgerExpense.multi(payers: const [SplitShare('me', 600), SplitShare('rahul', 400)], shares: split.shares);
      final expenses = [GroupTotalsExpense(expense: timelineExpenseOf(DateTime(2026, 10, 3), ledger), categoryId: 'travel')];

      final totals = computeGroupTotals(expenses: expenses, myMemberId: 'me');

      expect(totals.totalSpentMinor, 1000);
      expect(totals.myPaidMinor, 600);
      expect(totals.myShareMinor, 500);
      expect(totals.myNetChangeMinor, 100);
      expect(totals.byMember, const [
        MemberSpend(memberId: 'me', paidMinor: 600, shareMinor: 500),
        MemberSpend(memberId: 'rahul', paidMinor: 400, shareMinor: 300),
        MemberSpend(memberId: 'priya', paidMinor: 0, shareMinor: 200),
      ]);
      final paidSum = totals.byMember.fold(0, (sum, row) => sum + row.paidMinor);
      final shareSum = totals.byMember.fold(0, (sum, row) => sum + row.shareMinor);
      expect(paidSum, totals.totalSpentMinor);
      expect(shareSum, totals.totalSpentMinor);
    });

    test('exact amounts and an expense I am not part of', () {
      final totals = computeGroupTotals(
        myMemberId: 'me',
        expenses: [
          _expense(DateTime(2026, 10, 1), paid: {'rahul': 700}, shares: {'me': 250, 'rahul': 450}, category: 'food'),
          _expense(DateTime(2026, 10, 2), paid: {'priya': 400}, shares: {'rahul': 100, 'priya': 300}, category: 'fuel'),
        ],
      );
      expect(totals.totalSpentMinor, 1100);
      expect(totals.myPaidMinor, 0);
      expect(totals.myShareMinor, 250);
      expect(totals.myNetChangeMinor, -250);
      expect(totals.byCategory, {'food': 700, 'fuel': 400});
      expect(totals.byMember.map((row) => row.memberId), ['rahul', 'priya', 'me']);
    });

    test('payments I made or received in the period move my balance but not the spending', () {
      final ledger = [
        LedgerExpense.multi(payers: const [SplitShare('rahul', 900)], shares: const [SplitShare('me', 300), SplitShare('rahul', 300), SplitShare('priya', 300)]),
      ];
      final expenses = [GroupTotalsExpense(expense: timelineExpenseOf(DateTime(2026, 10, 3), ledger.single))];
      final payments = [
        TimelinePayment(occurredAt: DateTime(2026, 10, 5), fromMemberId: 'me', toMemberId: 'rahul', amountMinor: 300),
        TimelinePayment(occurredAt: DateTime(2026, 10, 6), fromMemberId: 'priya', toMemberId: 'me', amountMinor: 50),
        TimelinePayment(occurredAt: DateTime(2026, 10, 7), fromMemberId: 'priya', toMemberId: 'rahul', amountMinor: 250),
      ];

      final totals = computeGroupTotals(expenses: expenses, payments: payments, myMemberId: 'me');

      expect(totals.totalSpentMinor, 900);
      expect(totals.myShareMinor, 300);
      expect(totals.myPaymentsSentMinor, 300);
      expect(totals.myPaymentsReceivedMinor, 50);
      // Share 300 owed, then 300 paid back and 50 received: down 50 overall.
      expect(totals.myNetChangeMinor, -50);
      final balances = computeNetBalances(
        memberIds: const ['me', 'rahul', 'priya'],
        expenses: ledger,
        settlements: [for (final payment in payments) LedgerSettlement(fromMemberId: payment.fromMemberId, toMemberId: payment.toMemberId, amountMinor: payment.amountMinor)],
      );
      expect(totals.myNetChangeMinor, balances['me']);
    });

    test("owner's example: a 3,00,000 trip where my share is 50,000, payments not counted as spending", () {
      final expenses = [
        // Flights for all four, I paid: 1,60,000 split equally.
        GroupTotalsExpense(
          amountMinor: 16000000,
          expense: TimelineExpense(occurredAt: DateTime(2026, 10, 1), paidMinor: const {'me': 16000000}, shareMinor: const {'me': 4000000, 'rahul': 4000000, 'priya': 4000000, 'asha': 4000000}),
        ),
        // Villa: 1,00,000, Rahul and Priya paid; I owe 10,000 of it.
        GroupTotalsExpense(
          amountMinor: 10000000,
          expense: TimelineExpense(occurredAt: DateTime(2026, 10, 2), paidMinor: const {'rahul': 6000000, 'priya': 4000000}, shareMinor: const {'me': 1000000, 'rahul': 3000000, 'priya': 3000000, 'asha': 3000000}),
        ),
        // Scuba trip I was not on: 40,000.
        GroupTotalsExpense(
          amountMinor: 4000000,
          expense: TimelineExpense(occurredAt: DateTime(2026, 10, 3), paidMinor: const {'asha': 4000000}, shareMinor: const {'rahul': 2000000, 'asha': 2000000}),
        ),
      ];
      final payments = [TimelinePayment(occurredAt: DateTime(2026, 10, 4), fromMemberId: 'asha', toMemberId: 'me', amountMinor: 3000000)];

      final totals = computeGroupTotals(expenses: expenses, payments: payments, myMemberId: 'me');

      expect(totals.totalSpentMinor, 30000000);
      expect(totals.myShareMinor, 5000000);
      expect(totals.byMember.fold(0, (sum, row) => sum + row.shareMinor), totals.totalSpentMinor);
      expect(totals.myPaymentsReceivedMinor, 3000000);
    });

    test("the entry's recorded amount is the bill, as the group export sums it", () {
      final expense = GroupTotalsExpense(amountMinor: 1000, expense: TimelineExpense(occurredAt: DateTime(2026, 10, 1), paidMinor: const {'me': 1000}, shareMinor: const {'me': 500, 'rahul': 500}));
      expect(expense.billMinor, 1000);
      expect(computeGroupTotals(expenses: [expense]).totalSpentMinor, 1000);
      expect(GroupTotalsExpense(expense: expense.expense).billMinor, 1000);
    });

    test('a month range keeps only the payments made in that month', () {
      final payments = [
        TimelinePayment(occurredAt: DateTime(2026, 9, 30, 23, 59), fromMemberId: 'me', toMemberId: 'rahul', amountMinor: 100),
        TimelinePayment(occurredAt: DateTime(2026, 10, 1), fromMemberId: 'me', toMemberId: 'rahul', amountMinor: 200),
        TimelinePayment(occurredAt: DateTime(2026, 11, 1), fromMemberId: 'rahul', toMemberId: 'me', amountMinor: 400),
      ];

      final october = computeGroupTotals(expenses: const [], payments: payments, myMemberId: 'me', range: monthRange(DateTime(2026, 10, 15)));
      final allTime = computeGroupTotals(expenses: const [], payments: payments, myMemberId: 'me');
      final nobody = computeGroupTotals(expenses: const [], payments: payments);

      expect(october.myPaymentsSentMinor, 200);
      expect(october.myPaymentsReceivedMinor, 0);
      expect(october.myNetChangeMinor, 200);
      expect(october.totalSpentMinor, 0);
      expect(allTime.myNetChangeMinor, 300 - 400);
      expect(nobody.myNetChangeMinor, 0);
    });

    test('a month range keeps only that month; boundaries are closed-open', () {
      final expenses = [
        _expense(DateTime(2026, 9, 30, 23, 59), paid: {'me': 100}, shares: {'me': 100}),
        _expense(DateTime(2026, 10, 1), paid: {'me': 200}, shares: {'me': 100, 'rahul': 100}),
        _expense(DateTime(2026, 10, 31, 22), paid: {'rahul': 300}, shares: {'me': 150, 'rahul': 150}),
        _expense(DateTime(2026, 11, 1), paid: {'me': 400}, shares: {'me': 400}),
      ];
      final october = computeGroupTotals(expenses: expenses, myMemberId: 'me', range: monthRange(DateTime(2026, 10, 15)));
      expect(october.expenseCount, 2);
      expect(october.totalSpentMinor, 500);
      expect(october.myPaidMinor, 200);
      expect(october.myShareMinor, 250);

      final allTime = computeGroupTotals(expenses: expenses, myMemberId: 'me');
      expect(allTime.expenseCount, 4);
      expect(allTime.totalSpentMinor, 1000);
    });

    test('expenses without a category roll into the empty id', () {
      final totals = computeGroupTotals(
        expenses: [
          _expense(DateTime(2026, 10, 1), paid: {'me': 100}, shares: {'me': 100}),
          _expense(DateTime(2026, 10, 2), paid: {'me': 50}, shares: {'me': 50}, category: 'food'),
        ],
      );
      expect(totals.byCategory, {'': 100, 'food': 50});
    });

    test('without a me member my figures are zero but the group totals still add up', () {
      final totals = computeGroupTotals(
        expenses: [
          _expense(DateTime(2026, 10, 1), paid: {'rahul': 100}, shares: {'rahul': 100}),
        ],
      );
      expect(totals.totalSpentMinor, 100);
      expect(totals.myPaidMinor, 0);
      expect(totals.myShareMinor, 0);
    });
  });

  group('expenseTotalMinor', () {
    test('uses the shares, falling back to the payers when there are none', () {
      expect(expenseTotalMinor(TimelineExpense(occurredAt: DateTime(2026), paidMinor: const {'me': 300}, shareMinor: const {'me': 100, 'rahul': 200})), 300);
      expect(expenseTotalMinor(TimelineExpense(occurredAt: DateTime(2026), paidMinor: const {'me': 300}, shareMinor: const {})), 300);
    });
  });

  group('memberSpendOf', () {
    test('drops members with nothing and orders by share, then paid, then id', () {
      final rows = memberSpendOf({'a': 0, 'b': 500, 'c': 100}, {'a': 0, 'b': 200, 'c': 200, 'd': 300});
      expect(rows.map((row) => row.memberId), ['d', 'b', 'c']);
      expect(rows[1].netMinor, 300);
    });
  });

  group('monthsWithExpenses', () {
    test('lists each month once, newest first', () {
      final months = monthsWithExpenses([
        _expense(DateTime(2026, 9, 3), paid: const {}, shares: const {}),
        _expense(DateTime(2026, 10, 12), paid: const {}, shares: const {}),
        _expense(DateTime(2026, 10, 1), paid: const {}, shares: const {}),
        _expense(DateTime(2025, 12, 31), paid: const {}, shares: const {}),
      ]);
      expect(months, [DateTime(2026, 10), DateTime(2026, 9), DateTime(2025, 12)]);
    });
  });
}

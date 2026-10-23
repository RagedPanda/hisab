import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/domain/budget/budget_math.dart';
import 'package:hisab/domain/cards/card_summary.dart';

const card = 'card';
const bank = 'bank';

CardMovement move(String kind, int amount, DateTime at, {String? from, String? to}) =>
    CardMovement(kind: kind, amountMinor: amount, occurredAt: at, accountId: from, toAccountId: to);

void main() {
  final cycle = DateRange(DateTime(2026, 10, 16), DateTime(2026, 11, 16));

  group('cycleSpendMinor', () {
    test('counts purchases and transfers out, nets refunds, ignores payments and other accounts', () {
      final movements = [
        move('expense', 50000, DateTime(2026, 10, 16), from: card),
        move('expense', 12000, DateTime(2026, 11, 15, 23), from: card),
        move('transfer', 3000, DateTime(2026, 10, 20), from: card, to: bank),
        move('income', 2000, DateTime(2026, 10, 21), from: card),
        move('transfer', 40000, DateTime(2026, 10, 25), from: bank, to: card),
        move('expense', 9999, DateTime(2026, 10, 20), from: bank),
        move('expense', 7777, DateTime(2026, 10, 15, 23, 59), from: card),
        move('expense', 8888, DateTime(2026, 11, 16), from: card),
      ];
      expect(cycleSpendMinor(movements, cardId: card, range: cycle), 50000 + 12000 + 3000 - 2000);
    });

    test('is zero with no movements', () {
      expect(cycleSpendMinor(const [], cardId: card, range: cycle), 0);
    });
  });

  group('paymentsSinceMinor', () {
    test('sums transfers into the card on or after the statement date', () {
      final movements = [
        move('transfer', 10000, DateTime(2026, 10, 15), from: bank, to: card),
        move('transfer', 20000, DateTime(2026, 10, 14, 23), from: bank, to: card),
        move('transfer', 5000, DateTime(2026, 10, 20), from: card, to: bank),
        move('income', 3000, DateTime(2026, 10, 20), from: card),
      ];
      expect(paymentsSinceMinor(movements, cardId: card, since: DateTime(2026, 10, 15)), 10000);
    });
  });

  group('limit maths', () {
    test('outstanding is the positive amount owed', () {
      expect(outstandingMinor(-25000), 25000);
      expect(outstandingMinor(0), 0);
      expect(outstandingMinor(500), 0, reason: 'overpaid card owes nothing');
    });

    test('credit is the positive balance of an overpaid card', () {
      expect(cardCreditMinor(50000), 50000);
      expect(cardCreditMinor(0), 0);
      expect(cardCreditMinor(-25000), 0);
    });

    CardOverview overview(int limit, int balance) =>
        buildCardOverview(cardId: card, today: DateTime(2026, 10, 22), balanceMinor: balance, movements: const [], creditLimitMinor: limit);

    test('available limit and utilisation', () {
      expect(overview(100000, -25000).availableMinor, 75000);
      expect(overview(100000, -120000).availableMinor, -20000);
      expect(overview(100000, 1000).availableMinor, 100000);
      expect(overview(100000, -25000).utilisation, 0.25);
      expect(overview(100000, -25000).utilisationPercent, 25);
      expect(overview(100000, -120000).utilisation, 1.2);
      expect(overview(100000, -120000).utilisationPercent, 120);
    });

    test('utilisation bands: up to 30% fine, above that high, from 100% over', () {
      expect(utilisationBand(0), BudgetBand.onTrack);
      expect(utilisationBand(0.3), BudgetBand.onTrack);
      expect(utilisationBand(0.31), BudgetBand.nearLimit);
      expect(utilisationBand(0.99), BudgetBand.nearLimit);
      expect(utilisationBand(1), BudgetBand.over);
      expect(utilisationBand(1.4), BudgetBand.over);
    });

    test('no limit means no available figure and zero utilisation', () {
      expect(overview(0, -120000).hasLimit, isFalse);
      expect(overview(0, -120000).availableMinor, isNull);
      expect(overview(0, -120000).utilisation, 0);
    });
  });

  group('movementsSince', () {
    test('cycle start, or the last statement when earlier', () {
      final today = DateTime(2026, 10, 22, 15);
      expect(movementsSince(today: today, statementDay: 15), DateTime(2026, 10, 16));
      expect(movementsSince(today: today, statementDay: 15, lastStatementAt: DateTime(2026, 9, 15)), DateTime(2026, 9, 15));
      expect(movementsSince(today: today, statementDay: 15, lastStatementAt: DateTime(2026, 10, 20)), DateTime(2026, 10, 16));
      expect(movementsSince(today: today), DateTime(2026, 10, 22));
    });
  });

  group('buildCardOverview', () {
    test('combines cycle spend, payments against the statement and the due date', () {
      final movements = [
        move('expense', 30000, DateTime(2026, 10, 10), from: card),
        move('expense', 12000, DateTime(2026, 10, 18), from: card),
        move('transfer', 20000, DateTime(2026, 10, 19), from: bank, to: card),
      ];
      final result = buildCardOverview(
        cardId: card,
        today: DateTime(2026, 10, 22),
        balanceMinor: -62000,
        movements: movements,
        statementDay: 15,
        dueDay: 3,
        creditLimitMinor: 200000,
        lastStatementMinor: 70000,
        lastStatementAt: DateTime(2026, 10, 15),
      );
      expect(result.cycle!.start, DateTime(2026, 10, 16));
      expect(result.cycleSpendMinor, 12000);
      expect(result.outstandingMinor, 62000);
      expect(result.availableMinor, 138000);
      expect(result.due!.amountDueMinor, 50000);
      expect(result.due!.dueDate, DateTime(2026, 11, 3));
      expect(result.due!.daysLeft, 12);
    });

    test('without card details only the outstanding amount is known', () {
      final result = buildCardOverview(cardId: card, today: DateTime(2026, 10, 22), balanceMinor: -5000, movements: const []);
      expect(result.cycle, isNull);
      expect(result.cycleSpendMinor, isNull);
      expect(result.due, isNull);
      expect(result.outstandingMinor, 5000);
    });
  });

  group('statementDateForEntry', () {
    test('uses the most recent statement date when known, else today', () {
      expect(statementDateForEntry(DateTime(2026, 10, 22, 14), 15), DateTime(2026, 10, 15));
      expect(statementDateForEntry(DateTime(2026, 3, 2), 31), DateTime(2026, 2, 28));
      expect(statementDateForEntry(DateTime(2026, 10, 22, 14), null), DateTime(2026, 10, 22));
    });
  });

  group('lastStatementDateAfterEdit', () {
    final today = DateTime(2026, 10, 22);

    test('clearing the amount clears the date', () {
      expect(lastStatementDateAfterEdit(today: today, statementDay: 15, newAmountMinor: null, previousAmountMinor: 100, previousAt: DateTime(2026, 9, 15)), isNull);
    });

    test('an unchanged amount keeps its date', () {
      expect(lastStatementDateAfterEdit(today: today, statementDay: 15, newAmountMinor: 100, previousAmountMinor: 100, previousAt: DateTime(2026, 9, 15)), DateTime(2026, 9, 15));
    });

    test('a new or changed amount is stamped with the latest statement date', () {
      expect(lastStatementDateAfterEdit(today: today, statementDay: 15, newAmountMinor: 200, previousAmountMinor: 100, previousAt: DateTime(2026, 9, 15)), DateTime(2026, 10, 15));
      expect(lastStatementDateAfterEdit(today: today, statementDay: 31, newAmountMinor: 200), DateTime(2026, 9, 30));
      expect(lastStatementDateAfterEdit(today: today, statementDay: null, newAmountMinor: 200), DateTime(2026, 10, 22));
    });
  });

  group('cardDue', () {
    final today = DateTime(2026, 10, 22, 9);

    test('null without a due day, or without statement information', () {
      expect(cardDue(today: today, statementDay: 15, dueDay: null), isNull);
      expect(cardDue(today: today, statementDay: null, dueDay: 3), isNull);
    });

    test('without a recorded statement shows the next due date and no amount', () {
      final due = cardDue(today: today, statementDay: 15, dueDay: 3)!;
      expect(due.dueDate, DateTime(2026, 11, 3));
      expect(due.daysLeft, 12);
      expect(due.state, CardDueState.upcoming);
      expect(due.amountDueMinor, isNull);
    });

    test('unpaid statement counts down to its due date', () {
      final due = cardDue(today: today, statementDay: 15, dueDay: 3, lastStatementMinor: 80000, lastStatementAt: DateTime(2026, 10, 15), paidSinceStatementMinor: 30000)!;
      expect(due.dueDate, DateTime(2026, 11, 3));
      expect(due.daysLeft, 12);
      expect(due.amountDueMinor, 50000);
      expect(due.state, CardDueState.upcoming);
    });

    test('due today and overdue', () {
      final dueToday = cardDue(today: DateTime(2026, 11, 3, 20), statementDay: 15, dueDay: 3, lastStatementMinor: 80000, lastStatementAt: DateTime(2026, 10, 15))!;
      expect(dueToday.state, CardDueState.dueToday);
      expect(dueToday.daysLeft, 0);
      final overdue = cardDue(today: DateTime(2026, 11, 6), statementDay: 15, dueDay: 3, lastStatementMinor: 80000, lastStatementAt: DateTime(2026, 10, 15))!;
      expect(overdue.state, CardDueState.overdue);
      expect(overdue.daysLeft, -3);
      expect(overdue.amountDueMinor, 80000);
    });

    test('a paid statement shows the paid bill date, with the next bill due date alongside', () {
      final due = cardDue(today: today, statementDay: 15, dueDay: 3, lastStatementMinor: 80000, lastStatementAt: DateTime(2026, 10, 15), paidSinceStatementMinor: 80000)!;
      expect(due.state, CardDueState.paid);
      expect(due.amountDueMinor, 0);
      expect(due.dueDate, DateTime(2026, 11, 3), reason: 'the bill that was paid');
      expect(due.daysLeft, 12);
      expect(due.nextDueDate, DateTime(2026, 12, 3));
      expect(due.reminderDate, DateTime(2026, 12, 3), reason: 'reminders move on to the next bill');
    });

    test('an unpaid bill has no next due date and reminds on its own due date', () {
      final due = cardDue(today: today, statementDay: 15, dueDay: 3, lastStatementMinor: 80000, lastStatementAt: DateTime(2026, 10, 15))!;
      expect(due.nextDueDate, isNull);
      expect(due.reminderDate, DateTime(2026, 11, 3));
    });

    test('paid on statement day itself moves the next due date past that statement', () {
      final due = cardDue(today: DateTime(2026, 10, 15, 18), statementDay: 15, dueDay: 3, lastStatementMinor: 1000, lastStatementAt: DateTime(2026, 10, 15), paidSinceStatementMinor: 1000)!;
      expect(due.dueDate, DateTime(2026, 11, 3));
      expect(due.nextDueDate, DateTime(2026, 12, 3));
    });

    test('statement day 31 in a leap year', () {
      final due = cardDue(today: DateTime(2028, 3, 1), statementDay: 31, dueDay: 18, lastStatementMinor: 5000, lastStatementAt: DateTime(2028, 2, 29))!;
      expect(due.dueDate, DateTime(2028, 3, 18));
      expect(due.daysLeft, 17);
    });

    test('a zero statement is paid', () {
      final due = cardDue(today: today, statementDay: 15, dueDay: 3, lastStatementMinor: 0, lastStatementAt: DateTime(2026, 10, 15))!;
      expect(due.state, CardDueState.paid);
    });

    test('without a statement day a paid statement keeps its own due date', () {
      final due = cardDue(today: today, statementDay: null, dueDay: 3, lastStatementMinor: 100, lastStatementAt: DateTime(2026, 10, 15), paidSinceStatementMinor: 100)!;
      expect(due.state, CardDueState.paid);
      expect(due.dueDate, DateTime(2026, 11, 3));
      expect(due.nextDueDate, isNull);
      expect(due.reminderDate, isNull);
    });
  });

  group('lastStatementExceedsAmountDue', () {
    test('flags a statement above the amount due', () {
      expect(lastStatementExceedsAmountDue(lastStatementMinor: 500000, amountDueMinor: 200000), isTrue);
    });

    test('accepts a statement up to the amount due, or none', () {
      expect(lastStatementExceedsAmountDue(lastStatementMinor: 200000, amountDueMinor: 200000), isFalse);
      expect(lastStatementExceedsAmountDue(lastStatementMinor: 100000, amountDueMinor: 200000), isFalse);
      expect(lastStatementExceedsAmountDue(lastStatementMinor: null, amountDueMinor: 0), isFalse);
    });
  });
}

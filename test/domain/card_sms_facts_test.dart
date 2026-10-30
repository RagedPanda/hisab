import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/domain/cards/card_sms_facts.dart';
import 'package:hisab/domain/sms/card_sms.dart';

CardStatementSms statement({DateTime? due, DateTime? statementDate, DateTime? receivedAt, int total = 2345678, int? minimum = 118000}) => CardStatementSms(
      totalDueMinor: total,
      minimumDueMinor: minimum,
      dueDate: due ?? DateTime(2026, 11, 1),
      statementDate: statementDate,
      receivedAt: receivedAt ?? DateTime(2026, 10, 13, 10),
      bank: 'HDFC Bank',
      cardLast4: '4521',
    );

Account card(String id, {String? bank, String? last4, String type = 'card'}) => Account(
      updatedAt: DateTime(2026),
      id: id,
      name: id,
      type: type,
      balanceMinor: 0,
      includeInTotal: false,
      color: 0,
      sortOrder: 0,
      bankName: bank,
      last4: last4,
    );

void main() {
  group('statementDateForSms', () {
    test('uses the date the SMS states', () {
      expect(statementDateForSms(statement(statementDate: DateTime(2026, 10, 12))), DateTime(2026, 10, 12));
    });

    test('keeps the stored date for a repeat of the same bill', () {
      final date = statementDateForSms(statement(receivedAt: DateTime(2026, 10, 28)), statementDay: 12, dueDay: 1, lastStatementAt: DateTime(2026, 10, 12));
      expect(date, DateTime(2026, 10, 12));
    });

    test('falls back to the card statement day before the due date', () {
      expect(statementDateForSms(statement(), statementDay: 12), DateTime(2026, 10, 12));
    });

    test('otherwise the day the SMS arrived', () {
      expect(statementDateForSms(statement()), DateTime(2026, 10, 13));
    });

    test('is always before the due date', () {
      final late = statement(receivedAt: DateTime(2026, 11, 2), due: DateTime(2026, 11, 1));
      expect(statementDateForSms(late), DateTime(2026, 10, 31));
    });
  });

  group('cardStatementFromSms', () {
    test('fills the statement, minimum due and days', () {
      final fields = cardStatementFromSms(statement(statementDate: DateTime(2026, 10, 12)))!;
      expect(fields.lastStatementMinor, 2345678);
      expect(fields.lastStatementAt, DateTime(2026, 10, 12));
      expect(fields.minimumDueMinor, 118000);
      expect(fields.statementFromSmsAt, DateTime(2026, 10, 13, 10));
      expect(fields.dueDay, 1);
      expect(fields.statementDay, 12);
    });

    test('keeps a statement day the user set', () {
      final fields = cardStatementFromSms(statement(statementDate: DateTime(2026, 10, 12)), statementDay: 11, dueDay: 30)!;
      expect(fields.statementDay, 11);
      expect(fields.dueDay, 1);
    });

    test('an older statement read late changes nothing', () {
      final old = statement(statementDate: DateTime(2026, 9, 12), due: DateTime(2026, 10, 1), receivedAt: DateTime(2026, 9, 13));
      expect(cardStatementFromSms(old, statementDay: 12, dueDay: 1, lastStatementAt: DateTime(2026, 10, 12)), isNull);
    });
  });

  group('takesReportedLimit', () {
    test('only a report at least as new replaces the stored one', () {
      final stored = DateTime(2026, 10, 20);
      expect(takesReportedLimit(reportedAt: DateTime(2026, 10, 21), storedAt: stored), isTrue);
      expect(takesReportedLimit(reportedAt: DateTime(2026, 10, 19), storedAt: stored), isFalse);
      expect(takesReportedLimit(reportedAt: DateTime(2026, 10, 19)), isTrue);
    });
  });

  group('keepsSmsStatement', () {
    final at = DateTime(2026, 10, 12);

    test('holds while the amount and date are unchanged', () {
      expect(keepsSmsStatement(previousMinor: 500, previousAt: at, newMinor: 500, newAt: at), isTrue);
    });

    test('goes once either is edited or cleared', () {
      expect(keepsSmsStatement(previousMinor: 500, previousAt: at, newMinor: 600, newAt: at), isFalse);
      expect(keepsSmsStatement(previousMinor: 500, previousAt: at, newMinor: 500, newAt: DateTime(2026, 10, 11)), isFalse);
      expect(keepsSmsStatement(previousMinor: 500, previousAt: at), isFalse);
    });
  });

  group('matchingCardId', () {
    final cards = [card('hdfc', bank: 'HDFC Bank', last4: '4521'), card('sbi', bank: 'SBI Card', last4: '5512'), card('bank', bank: 'HDFC Bank', last4: '7781', type: 'bank')];

    test('matches the card by its digits', () {
      expect(matchingCardId(cards, bank: null, last4: '4521'), 'hdfc');
    });

    test('without digits, the single card of that bank', () {
      expect(matchingCardId(cards, bank: 'SBI Card', last4: null), 'sbi');
    });

    test('never a bank account, and nothing when unsure', () {
      expect(matchingCardId(cards, bank: null, last4: '7781'), isNull);
      expect(matchingCardId([...cards, card('hdfc2', bank: 'HDFC Bank', last4: '4521')], bank: null, last4: '4521'), isNull);
      expect(matchingCardId(cards, bank: null, last4: null), isNull);
    });
  });

  group('takesSmsStatementBalance', () {
    final received = DateTime(2026, 10, 13, 10);

    test('sets the balance of a card with none on record', () {
      expect(takesSmsStatementBalance(balanceMinor: 0, receivedAt: received), isTrue);
    });

    test('replaces an older balance but not a newer one', () {
      expect(takesSmsStatementBalance(balanceMinor: -50000, balanceAsOf: DateTime(2026, 10, 1), receivedAt: received), isTrue);
      expect(takesSmsStatementBalance(balanceMinor: -50000, balanceAsOf: DateTime(2026, 10, 20), receivedAt: received), isFalse);
    });

    test('leaves a balance moved by entries alone', () {
      expect(takesSmsStatementBalance(balanceMinor: -50000, receivedAt: received), isFalse);
    });
  });

  group('balanceFollowsSmsStatement', () {
    final received = DateTime(2026, 10, 13, 10);
    Account withStatement({DateTime? balanceAsOf, DateTime? fromSmsAt}) => card('c').copyWith(
          lastStatementMinor: const Value(2345678),
          lastStatementAt: Value(DateTime(2026, 10, 12)),
          statementFromSmsAt: Value(fromSmsAt),
          balanceAsOf: Value(balanceAsOf),
        );

    test('while the balance carries the statement arrival', () {
      expect(balanceFollowsSmsStatement(withStatement(balanceAsOf: received, fromSmsAt: received)), isTrue);
    });

    test('not once the balance or the statement was edited by hand', () {
      expect(balanceFollowsSmsStatement(withStatement(balanceAsOf: DateTime(2026, 10, 14), fromSmsAt: received)), isFalse);
      expect(balanceFollowsSmsStatement(withStatement(balanceAsOf: received)), isFalse);
      expect(balanceFollowsSmsStatement(card('c')), isFalse);
    });
  });
}

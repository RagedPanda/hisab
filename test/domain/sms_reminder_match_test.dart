import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/reminders/sms_reminder_match.dart';
import 'package:hisab/domain/sms/parsed_transaction.dart';

ParsedTransaction debitSms({
  required int amountMinor,
  required DateTime occurredAt,
  String? counterparty,
  String? bank = 'HDFC Bank',
  String? last4 = '1234',
  TxnDirection direction = TxnDirection.debit,
  String raw = 'Rs debited from a/c',
}) =>
    ParsedTransaction(
      direction: direction,
      amountMinor: amountMinor,
      instrument: Instrument.upi,
      occurredAt: occurredAt,
      raw: raw,
      bank: bank,
      accountLast4: last4,
      counterparty: counterparty,
    );

ReminderMatchCandidate reminder({
  String id = 'r1',
  String kind = 'bill',
  String title = 'Electricity',
  required DateTime dueAt,
  int? amountMinor = 150000,
  String? payee,
  String? bankName,
  String? last4,
}) =>
    ReminderMatchCandidate(
      id: id,
      kind: kind,
      title: title,
      dueAt: dueAt,
      amountMinor: amountMinor,
      payee: payee,
      bankName: bankName,
      accountLast4: last4,
    );

void main() {
  final due = DateTime(2026, 11, 5, 9);

  group('amount tolerance', () {
    test('EMI matches only the exact amount', () {
      final emi = reminder(kind: 'emi', title: 'Car loan', amountMinor: 1234500, bankName: 'HDFC Bank', dueAt: due);
      expect(matchSmsToReminder(debitSms(amountMinor: 1234500, occurredAt: due), [emi])?.reminderId, 'r1');
      expect(matchSmsToReminder(debitSms(amountMinor: 1234501, occurredAt: due), [emi]), isNull);
      expect(matchSmsToReminder(debitSms(amountMinor: 1234400, occurredAt: due), [emi]), isNull);
    });

    test('utility bill accepts up to the percentage either way', () {
      final bill = reminder(payee: 'BESCOM', amountMinor: 150000, dueAt: due);
      ParsedTransaction paid(int amount) => debitSms(amountMinor: amount, occurredAt: due, counterparty: 'bescom.bill@okicici');
      expect(matchSmsToReminder(paid(165000), [bill])?.amountDifferenceMinor, 15000);
      expect(matchSmsToReminder(paid(135000), [bill]), isNotNull);
      expect(matchSmsToReminder(paid(165001), [bill]), isNull);
      expect(matchSmsToReminder(paid(134999), [bill]), isNull);
    });

    test('the percentage is a policy setting', () {
      final bill = reminder(payee: 'BESCOM', amountMinor: 100000, dueAt: due);
      final sms = debitSms(amountMinor: 104000, occurredAt: due, counterparty: 'BESCOM');
      expect(matchSmsToReminder(sms, [bill], policy: const SmsMatchPolicy(billTolerancePercent: 3)), isNull);
      expect(matchSmsToReminder(sms, [bill], policy: const SmsMatchPolicy(billTolerancePercent: 5)), isNotNull);
    });

    test('subscriptions and insurance are exact, cards and custom use the percentage', () {
      expect(toleranceForKind('emi'), AmountTolerance.exact);
      expect(toleranceForKind('subscription'), AmountTolerance.exact);
      expect(toleranceForKind('insurance'), AmountTolerance.exact);
      expect(toleranceForKind('bill'), AmountTolerance.percentage);
      expect(toleranceForKind('card'), AmountTolerance.percentage);
      expect(toleranceForKind('custom'), AmountTolerance.percentage);
    });

    test('a reminder without an amount never auto-matches', () {
      final document = reminder(kind: 'document', title: 'PUC', amountMinor: null, bankName: 'HDFC Bank', dueAt: due);
      expect(matchSmsToReminder(debitSms(amountMinor: 10000, occurredAt: due), [document]), isNull);
    });
  });

  group('payee or bank', () {
    test('payee words match the counterparty, generic words do not', () {
      expect(payeeMatches(counterparty: 'ola.cabs@axisbank', reminderPayee: 'Ola', reminderTitle: 'x'), isTrue);
      expect(payeeMatches(counterparty: 'jiomart@ybl', reminderPayee: 'Jio', reminderTitle: 'x'), isFalse,
          reason: 'a short name only matches a whole word');
      expect(payeeMatches(counterparty: 'AIRTEL PAYMENTS', reminderPayee: null, reminderTitle: 'Airtel postpaid'), isTrue);
      expect(payeeMatches(counterparty: 'netflixupi@hdfcbank', reminderPayee: 'Netflix', reminderTitle: 'OTT'), isTrue);
      expect(payeeMatches(counterparty: 'Amazon Pay bill', reminderPayee: 'Tata Power bill', reminderTitle: 'x'), isFalse);
      expect(payeeMatches(counterparty: null, reminderPayee: 'BESCOM', reminderTitle: 'x'), isFalse);
    });

    test('bank must agree, and so must the last digits when both are known', () {
      expect(bankMatches(smsBank: 'HDFC Bank', smsLast4: '1234', reminderBank: 'HDFC', reminderLast4: null), isTrue);
      expect(bankMatches(smsBank: 'HDFC Bank', smsLast4: '1234', reminderBank: 'HDFC Bank', reminderLast4: '1234'), isTrue);
      expect(bankMatches(smsBank: 'HDFC Bank', smsLast4: '1234', reminderBank: 'HDFC Bank', reminderLast4: '9999'), isFalse);
      expect(bankMatches(smsBank: 'ICICI Bank', smsLast4: '1234', reminderBank: 'HDFC Bank', reminderLast4: null), isFalse);
      expect(bankMatches(smsBank: null, smsLast4: null, reminderBank: 'HDFC Bank', reminderLast4: null), isFalse);
    });

    test('right amount and date but neither payee nor bank is not a match', () {
      final bill = reminder(payee: 'BESCOM', bankName: 'SBI', dueAt: due);
      expect(matchSmsToReminder(debitSms(amountMinor: 150000, occurredAt: due, counterparty: 'Swiggy'), [bill]), isNull);
    });
  });

  group('due window', () {
    final bill = reminder(payee: 'BESCOM', dueAt: due);
    ParsedTransaction paidOn(DateTime when) => debitSms(amountMinor: 150000, occurredAt: when, counterparty: 'BESCOM');

    test('an early payment inside the window matches with a negative offset', () {
      final match = matchSmsToReminder(paidOn(DateTime(2026, 10, 27, 22)), [bill]);
      expect(match?.dayOffset, -9);
    });

    test('a payment earlier than the window does not match', () {
      expect(matchSmsToReminder(paidOn(DateTime(2026, 10, 25, 23, 59)), [bill]), isNull);
    });

    test('a late payment inside the window matches with a positive offset', () {
      expect(matchSmsToReminder(paidOn(DateTime(2026, 11, 12, 23, 30)), [bill])?.dayOffset, 7);
    });

    test('a payment after the window does not match', () {
      expect(matchSmsToReminder(paidOn(DateTime(2026, 11, 13, 0, 5)), [bill]), isNull);
    });

    test('offsets count calendar days, not 24-hour blocks', () {
      expect(calendarDayOffset(dueAt: DateTime(2026, 11, 5, 23), paidAt: DateTime(2026, 11, 6, 1)), 1);
      expect(calendarDayOffset(dueAt: DateTime(2026, 11, 5, 1), paidAt: DateTime(2026, 11, 5, 23)), 0);
    });
  });

  group('ambiguity', () {
    test('two matching reminders: the closest due date wins', () {
      final october = reminder(id: 'oct', payee: 'BESCOM', dueAt: DateTime(2026, 10, 30));
      final november = reminder(id: 'nov', payee: 'BESCOM', dueAt: DateTime(2026, 11, 5));
      final sms = debitSms(amountMinor: 150000, occurredAt: DateTime(2026, 11, 3), counterparty: 'BESCOM');
      expect(matchSmsToReminder(sms, [october, november])?.reminderId, 'nov');
      expect(matchSmsToReminder(sms, [november, october])?.reminderId, 'nov');
    });

    test('equal distance: the closer amount wins, then the overdue one', () {
      final electricity = reminder(id: 'a', payee: 'HDFC', amountMinor: 160000, bankName: 'HDFC Bank', dueAt: DateTime(2026, 11, 3));
      final water = reminder(id: 'b', payee: 'HDFC', amountMinor: 150000, bankName: 'HDFC Bank', dueAt: DateTime(2026, 11, 7));
      final sms = debitSms(amountMinor: 150000, occurredAt: DateTime(2026, 11, 5));
      expect(matchSmsToReminder(sms, [electricity, water])?.reminderId, 'b');

      final overdue = reminder(id: 'z', bankName: 'HDFC Bank', dueAt: DateTime(2026, 11, 3));
      final upcoming = reminder(id: 'y', bankName: 'HDFC Bank', dueAt: DateTime(2026, 11, 7));
      expect(matchSmsToReminder(sms, [upcoming, overdue])?.reminderId, 'z');
    });

    test('a reminder already paid by another SMS is never matched twice', () {
      final october = reminder(id: 'oct', payee: 'BESCOM', dueAt: DateTime(2026, 10, 30));
      final november = reminder(id: 'nov', payee: 'BESCOM', dueAt: DateTime(2026, 11, 5));
      final sms = debitSms(amountMinor: 150000, occurredAt: DateTime(2026, 11, 3), counterparty: 'BESCOM');
      expect(matchSmsToReminder(sms, [october, november], alreadyMatchedReminderIds: {'nov'})?.reminderId, 'oct');
      expect(matchSmsToReminder(sms, [october, november], alreadyMatchedReminderIds: {'nov', 'oct'}), isNull);
    });
  });

  group('refunds', () {
    final bill = reminder(payee: 'BESCOM', bankName: 'HDFC Bank', dueAt: due);

    test('a credit for the same amount does not match', () {
      final refund = debitSms(amountMinor: 150000, occurredAt: due, counterparty: 'BESCOM', direction: TxnDirection.credit, raw: 'Rs 1500 credited');
      expect(matchSmsToReminder(refund, [bill]), isNull);
    });

    test('refund or reversal wording never matches, whatever the direction', () {
      for (final raw in ['Refund of Rs 1500 from BESCOM', 'Txn REVERSED Rs 1500', 'Cashback Rs 1500']) {
        final sms = debitSms(amountMinor: 150000, occurredAt: due, counterparty: 'BESCOM', raw: raw);
        expect(matchSmsToReminder(sms, [bill]), isNull, reason: raw);
      }
    });
  });
}

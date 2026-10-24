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
  int toleranceMinor = 0,
  String? bankName,
  String? last4,
}) =>
    ReminderMatchCandidate(
      id: id,
      kind: kind,
      title: title,
      dueAt: dueAt,
      amountMinor: amountMinor,
      toleranceMinor: toleranceMinor,
      matchKeywords: payee == null ? const [] : parseMatchKeywords(payee),
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

    test('a tolerance the user set wins over the kind default', () {
      final emi = reminder(kind: 'emi', title: 'Car loan', amountMinor: 1234500, toleranceMinor: 100, bankName: 'HDFC Bank', dueAt: due);
      expect(matchSmsToReminder(debitSms(amountMinor: 1234600, occurredAt: due), [emi]), isNotNull);
      expect(matchSmsToReminder(debitSms(amountMinor: 1234601, occurredAt: due), [emi]), isNull);
      final bill = reminder(payee: 'bescom', amountMinor: 150000, toleranceMinor: 5000, dueAt: due);
      expect(matchSmsToReminder(debitSms(amountMinor: 160000, occurredAt: due, counterparty: 'BESCOM'), [bill]), isNull,
          reason: 'Rs 50 set by the user, not the 10% default');
    });

    test('a reminder without an amount never auto-matches', () {
      final document = reminder(kind: 'document', title: 'PUC', amountMinor: null, bankName: 'HDFC Bank', dueAt: due);
      expect(matchSmsToReminder(debitSms(amountMinor: 10000, occurredAt: due), [document]), isNull);
    });
  });

  group('payee or bank', () {
    test('keywords match anywhere in the counterparty, short ones only as a whole word', () {
      expect(payeeMatches(counterparty: 'ola.cabs@axisbank', keywords: ['ola'], reminderTitle: 'x'), isTrue);
      expect(payeeMatches(counterparty: 'jiomart@ybl', keywords: ['jio'], reminderTitle: 'x'), isFalse);
      expect(payeeMatches(counterparty: 'TATAPOWER DDL', keywords: ['tata power', 'tpddl'], reminderTitle: 'Power'), isTrue);
      expect(payeeMatches(counterparty: 'tpddl.bill@okhdfc', keywords: ['tata power', 'tpddl'], reminderTitle: 'Power'), isTrue);
      expect(payeeMatches(counterparty: 'netflixupi@hdfcbank', keywords: ['netflix'], reminderTitle: 'OTT'), isTrue);
      expect(payeeMatches(counterparty: 'Amazon Pay', keywords: ['tata power'], reminderTitle: 'Amazon'), isFalse,
          reason: 'keywords, when set, replace the title');
      expect(payeeMatches(counterparty: null, keywords: ['bescom'], reminderTitle: 'x'), isFalse);
    });

    test('without keywords a distinctive title word must appear', () {
      expect(payeeMatches(counterparty: 'AIRTEL PAYMENTS', keywords: const [], reminderTitle: 'Airtel postpaid'), isTrue);
      expect(payeeMatches(counterparty: 'Amazon Pay bill', keywords: const [], reminderTitle: 'Electricity bill'), isFalse);
    });

    test('stored keywords split on the bar, trimmed and lower-cased', () {
      expect(parseMatchKeywords(' Tata Power | TPDDL ||'), ['tata power', 'tpddl']);
      expect(parseMatchKeywords(''), isEmpty);
    });

    test('bank must agree, and so must the last digits when both are known', () {
      expect(bankMatches(smsBank: 'HDFC Bank', smsLast4: '1234', reminderBank: 'HDFC', reminderLast4: null), isTrue);
      expect(bankMatches(smsBank: 'HDFC Bank', smsLast4: '1234', reminderBank: 'HDFC Bank', reminderLast4: '1234'), isTrue);
      expect(bankMatches(smsBank: 'HDFC Bank', smsLast4: '1234', reminderBank: 'HDFC Bank', reminderLast4: '9999'), isFalse);
      expect(bankMatches(smsBank: 'ICICI Bank', smsLast4: '1234', reminderBank: 'HDFC Bank', reminderLast4: null), isFalse);
      expect(bankMatches(smsBank: null, smsLast4: null, reminderBank: 'HDFC Bank', reminderLast4: null), isFalse);
    });

    test('a payee match from another account of the linked bank does not pay it (decision 17)', () {
      final linked = reminder(payee: 'BESCOM', bankName: 'HDFC Bank', last4: '1234', dueAt: due);
      expect(matchSmsToReminder(debitSms(amountMinor: 150000, occurredAt: due, counterparty: 'BESCOM', last4: '9999'), [linked]), isNull);
      expect(matchSmsToReminder(debitSms(amountMinor: 150000, occurredAt: due, counterparty: 'BESCOM', last4: '1234'), [linked])?.reminderId, 'r1');
    });

    test('payee alone still pays when either side has no account digits', () {
      final unlinked = reminder(payee: 'BESCOM', dueAt: due);
      final linked = reminder(payee: 'BESCOM', bankName: 'HDFC Bank', last4: '1234', dueAt: due);
      expect(matchSmsToReminder(debitSms(amountMinor: 150000, occurredAt: due, counterparty: 'BESCOM', last4: '9999'), [unlinked])?.reminderId, 'r1');
      expect(matchSmsToReminder(debitSms(amountMinor: 150000, occurredAt: due, counterparty: 'BESCOM', last4: null), [linked])?.reminderId, 'r1');
    });

    test('account digits compare on the last four digits only', () {
      expect(accountDigitsConflict(smsLast4: 'XX1234', reminderLast4: '1234'), isFalse);
      expect(accountDigitsConflict(smsLast4: '1234', reminderLast4: '9999'), isTrue);
      expect(accountDigitsConflict(smsLast4: null, reminderLast4: '9999'), isFalse);
      expect(accountDigitsConflict(smsLast4: '12', reminderLast4: '9999'), isFalse, reason: 'too few digits to tell');
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

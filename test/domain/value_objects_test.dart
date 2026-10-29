import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/accounts/account_label.dart';
import 'package:hisab/domain/backup/backup_codec.dart';
import 'package:hisab/domain/budget/budget_math.dart';
import 'package:hisab/domain/money/money_format.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/recurring/repeat_draft.dart';
import 'package:hisab/domain/reminders/reminder_schedule.dart';
import 'package:hisab/domain/reminders/sms_reminder_match.dart';
import 'package:hisab/domain/sms/parsed_transaction.dart';
import 'package:hisab/domain/split/debt_simplifier.dart';
import 'package:hisab/domain/split/group_recurring.dart';
import 'package:hisab/domain/split/group_totals.dart';
import 'package:hisab/domain/split/item_split.dart';
import 'package:hisab/domain/split/split_calculator.dart';

/// Builds a value at runtime so equality is checked on distinct instances,
/// not on one canonicalised const.
T fresh<T>(T Function() build) => build();

void main() {
  group('account labels', () {
    test('a masked number moves onto its own line', () {
      final label = splitAccountLabel('HDFC Savings ••4421');
      expect(label.name, 'HDFC Savings');
      expect(label.mask, '••4421');
    });

    test('a name without a mask keeps the whole name', () {
      final label = splitAccountLabel(' Cash ');
      expect(label.name, 'Cash');
      expect(label.mask, isNull);
    });
  });

  test('a backup format error reads as its message', () {
    expect(fresh(() => const BackupFormatException('Not a Hisab backup')).toString(), 'Not a Hisab backup');
  });

  group('budget progress', () {
    test('projects spend to the end of the period from the pace so far', () {
      const halfway = BudgetProgress(limitMinor: 10000, spentMinor: 6000, elapsedFraction: 0.5);
      expect(halfway.projectedMinor, 12000);
      expect(halfway.isAheadOfPace, isTrue);
    });

    test('before the period starts the projection is what is already spent', () {
      const notStarted = BudgetProgress(limitMinor: 10000, spentMinor: 500, elapsedFraction: 0);
      expect(notStarted.projectedMinor, 500);
    });

    test('spending in step with the calendar is not ahead of pace', () {
      const onPace = BudgetProgress(limitMinor: 10000, spentMinor: 5200, elapsedFraction: 0.5);
      expect(onPace.isAheadOfPace, isFalse);
    });
  });

  test('money formats with the same fields are equal and hash alike', () {
    final western = MoneyFormat.inr.copyWith(grouping: DigitGrouping.western, symbol: r'$');
    final sameWestern = fresh(() => MoneyFormat.inr.copyWith(grouping: DigitGrouping.western, symbol: r'$'));
    expect(western, sameWestern);
    expect(western.hashCode, sameWestern.hashCode);
    expect(western, isNot(MoneyFormat.inr));
  });

  group('repeat drafts', () {
    test('copyWith replaces only the given fields', () {
      const monthly = RepeatDraft();
      final lastDay = monthly.copyWith(lastDayOfMonth: true, end: RepeatEnd.afterCount, maxCount: 6, autoPost: false);
      expect(lastDay.lastDayOfMonth, isTrue);
      expect(lastDay.maxCount, 6);
      expect(lastDay.frequency, RecurrenceFrequency.monthly);
      expect(monthly.copyWith(), monthly);
    });

    test('equal drafts hash alike', () {
      final weekly = fresh(() => const RepeatDraft(frequency: RecurrenceFrequency.weekly, interval: 2));
      final sameWeekly = fresh(() => const RepeatDraft().copyWith(frequency: RecurrenceFrequency.weekly, interval: 2));
      expect(weekly, sameWeekly);
      expect(weekly.hashCode, sameWeekly.hashCode);
    });
  });

  test('planned alerts compare by id, time and lead days', () {
    final fireAt = DateTime(2026, 11, 5, 9);
    final alert = PlannedAlert(notificationId: 7, fireAt: fireAt, daysBefore: 2);
    final sameAlert = PlannedAlert(notificationId: 7, fireAt: fireAt, daysBefore: 2);
    expect(alert, sameAlert);
    expect(alert.hashCode, sameAlert.hashCode);
    expect(alert.toString(), 'PlannedAlert(7, $fireAt, 2)');
  });

  group('reminder matches', () {
    test('compare by reminder, day and amount difference', () {
      final match = fresh(() => const ReminderMatch(reminderId: 'power', dayOffset: -2, amountDifferenceMinor: 150));
      const sameMatch = ReminderMatch(reminderId: 'power', dayOffset: -2, amountDifferenceMinor: 150);
      expect(match, sameMatch);
      expect(match.hashCode, sameMatch.hashCode);
      expect(match.toString(), 'ReminderMatch(power, day -2, diff 150)');
    });

    test('two equally close reminders resolve by id so the pick is stable', () {
      final due = DateTime(2026, 10, 10);
      final payment = ParsedTransaction(
        direction: TxnDirection.debit,
        amountMinor: 150000,
        instrument: Instrument.upi,
        occurredAt: due,
        raw: 'Rs 1500 debited to TATA POWER',
        bank: 'HDFC Bank',
        counterparty: 'TATA POWER',
      );
      ReminderMatchCandidate candidate(String id) => ReminderMatchCandidate(id: id, kind: 'bill', title: 'Tata Power', dueAt: due, amountMinor: 150000);

      expect(matchSmsToReminder(payment, [candidate('second'), candidate('first')])?.reminderId, 'first');
    });
  });

  group('split values', () {
    test('transfers read as from->to:amount and compare by value', () {
      final transfer = fresh(() => const Transfer('asha', 'ravi', 500));
      expect(transfer.toString(), 'asha->ravi:500');
      expect(transfer, const Transfer('asha', 'ravi', 500));
      expect(transfer.hashCode, const Transfer('asha', 'ravi', 500).hashCode);
    });

    test('occurrence splits compare by value', () {
      final split = fresh(() => const OccurrenceSplit(memberId: 'asha', amountMinor: 300, shareValue: 2));
      expect(split, const OccurrenceSplit(memberId: 'asha', amountMinor: 300, shareValue: 2));
      expect(split.hashCode, const OccurrenceSplit(memberId: 'asha', amountMinor: 300, shareValue: 2).hashCode);
      expect(split.toString(), 'asha:300');
    });

    test('member spend compares by value and reads paid and share', () {
      final spend = fresh(() => const MemberSpend(memberId: 'ravi', paidMinor: 900, shareMinor: 400));
      expect(spend.hashCode, const MemberSpend(memberId: 'ravi', paidMinor: 900, shareMinor: 400).hashCode);
      expect(spend.toString(), 'ravi(paid 900, share 400)');
    });

    test('item share summaries compare by value', () {
      final summary = fresh(() => const ItemShareSummary(memberId: 'asha', amountMinor: 620, itemCount: 3, percent: 31));
      expect(summary.hashCode, const ItemShareSummary(memberId: 'asha', amountMinor: 620, itemCount: 3, percent: 31).hashCode);
      expect(summary.toString(), 'asha:620/3/31%');
    });

    test('split shares and errors compare by value', () {
      final share = fresh(() => const SplitShare('asha', 250));
      expect(share.toString(), 'asha:250');
      expect(share, const SplitShare('asha', 250));
      expect(share.hashCode, const SplitShare('asha', 250).hashCode);
      final error = fresh(() => const SplitError(SplitErrorCode.percentLeft, percent: 10));
      expect(error.hashCode, const SplitError(SplitErrorCode.percentLeft, percent: 10).hashCode);
    });

    test('split input copyWith keeps the member and replaces the given fields', () {
      const input = SplitInput(memberId: 'asha');
      final updated = input.copyWith(included: false, amountMinor: 120, weight: 3);
      expect(updated.memberId, 'asha');
      expect(updated.included, isFalse);
      expect(updated.amountMinor, 120);
      expect(updated.weight, 3);
      expect(input.copyWith().amountMinor, 0);
    });
  });
}

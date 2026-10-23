import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/salary/salary_schedule.dart';

void main() {
  group('expected salary date', () {
    test('clamps the salary day to short months', () {
      expect(nominalSalaryDate(2026, 4, 31), DateTime(2026, 4, 30));
      expect(nominalSalaryDate(2027, 2, 30), DateTime(2027, 2, 28));
      expect(nominalSalaryDate(2028, 2, 31), DateTime(2028, 2, 29));
      expect(nominalSalaryDate(2026, 13, 5), DateTime(2027, 1, 5));
    });

    test('same day keeps a weekend date', () {
      expect(expectedSalaryDate(2026, 10, salaryDay: 31), DateTime(2026, 10, 31));
    });

    test('previous working day pulls a Saturday back to Friday', () {
      expect(expectedSalaryDate(2026, 10, salaryDay: 31, shift: SalaryShift.previousWorkingDay), DateTime(2026, 10, 30));
      expect(expectedSalaryDate(2027, 2, salaryDay: 30, shift: SalaryShift.previousWorkingDay), DateTime(2027, 2, 26));
    });

    test('next working day can cross into the next month', () {
      expect(expectedSalaryDate(2026, 10, salaryDay: 31, shift: SalaryShift.nextWorkingDay), DateTime(2026, 11, 2));
    });

    test('holidays are skipped like weekends', () {
      final holidays = {DateTime(2026, 10, 30)};
      expect(expectedSalaryDate(2026, 10, salaryDay: 31, shift: SalaryShift.previousWorkingDay, holidays: holidays), DateTime(2026, 10, 29));
      expect(expectedSalaryDate(2026, 10, salaryDay: 30, shift: SalaryShift.nextWorkingDay, holidays: holidays), DateTime(2026, 11, 2));
      expect(isWorkingDay(DateTime(2026, 10, 30, 15), holidays: holidays), isFalse);
      expect(isWorkingDay(DateTime(2026, 10, 29)), isTrue);
    });

    test('shift parses stored names and defaults to previous working day', () {
      expect(SalaryShift.parse('nextWorkingDay'), SalaryShift.nextWorkingDay);
      expect(SalaryShift.parse('junk'), SalaryShift.previousWorkingDay);
    });
  });

  group('salary cycle', () {
    test('current is the last expected date on or before today', () {
      final cycle = salaryCycle(DateTime(2026, 10, 22, 9), salaryDay: 1, shift: SalaryShift.nextWorkingDay);
      expect(cycle.current, DateTime(2026, 10, 1));
      expect(cycle.next, DateTime(2026, 11, 2));
    });

    test('on a shifted salary day that day is the current cycle', () {
      final cycle = salaryCycle(DateTime(2026, 10, 30, 8), salaryDay: 31, shift: SalaryShift.previousWorkingDay);
      expect(cycle.current, DateTime(2026, 10, 30));
      expect(cycle.next, DateTime(2026, 11, 30));
    });

    test('a date pushed into next month is not the current cycle yet', () {
      final cycle = salaryCycle(DateTime(2026, 11, 1), salaryDay: 31, shift: SalaryShift.nextWorkingDay);
      expect(cycle.current, DateTime(2026, 9, 30));
      expect(cycle.next, DateTime(2026, 11, 2));
    });

    test('days until salary counts calendar days', () {
      expect(daysUntilSalary(DateTime(2026, 11, 2), now: DateTime(2026, 10, 22, 23)), 11);
      expect(daysUntilSalary(DateTime(2026, 10, 22), now: DateTime(2026, 10, 22, 23)), 0);
    });
  });

  group('month starts on', () {
    test('suggestion follows the salary day up to the 28th', () {
      expect(suggestedMonthStartDay(25), 25);
      expect(suggestedMonthStartDay(1), 1);
      expect(suggestedMonthStartDay(31), 28);
    });

    test('alignment compares against the suggestion', () {
      expect(isMonthStartAligned(monthStartDay: 1, salaryDay: 1), isTrue);
      expect(isMonthStartAligned(monthStartDay: 1, salaryDay: 30), isFalse);
      expect(isMonthStartAligned(monthStartDay: 28, salaryDay: 31), isTrue);
    });

    test('an unaligned month start counts an end-of-month salary in the ending month', () {
      final unaligned = budgetMonthOfSalary(DateTime(2026, 10, 30), monthStartDay: 1);
      expect(unaligned.start, DateTime(2026, 10, 1));
      final aligned = budgetMonthOfSalary(DateTime(2026, 10, 30), monthStartDay: 28);
      expect(aligned.start, DateTime(2026, 10, 28));
      expect(aligned.end, DateTime(2026, 11, 28));
    });
  });

  group('salary detection', () {
    final expected = DateTime(2026, 10, 30);
    IncomeCandidate income(DateTime at, int amount, [String? account]) => IncomeCandidate(occurredAt: at, amountMinor: amount, accountId: account);

    test('amount tolerance is a share of the expected amount', () {
      expect(isAmountWithinTolerance(85000, 100000), isTrue);
      expect(isAmountWithinTolerance(84999, 100000), isFalse);
      expect(isAmountWithinTolerance(115000, 100000), isTrue);
      expect(isAmountWithinTolerance(1, 0), isTrue);
    });

    test('an income a few days early with a slightly different amount counts', () {
      final found = findSalaryIncome([income(DateTime(2026, 10, 27, 11), 98000)], expected: expected, expectedMinor: 100000, now: DateTime(2026, 11, 1));
      expect(found, isNotNull);
    });

    test('incomes outside the window or the tolerance do not count', () {
      final found = findSalaryIncome(
        [income(DateTime(2026, 10, 25), 100000), income(DateTime(2026, 10, 30), 5000)],
        expected: expected,
        expectedMinor: 100000,
        now: DateTime(2026, 11, 1),
      );
      expect(found, isNull);
    });

    test('a late salary up to today still counts, but not past the next cycle window', () {
      final late = income(DateTime(2026, 11, 10), 100000);
      expect(findSalaryIncome([late], expected: expected, expectedMinor: 100000, now: DateTime(2026, 11, 12), nextExpected: DateTime(2026, 11, 30)), isNotNull);
      final window = salaryMatchWindow(expected, now: DateTime(2026, 12, 20), nextExpected: DateTime(2026, 11, 30));
      expect(window.end, DateTime(2026, 11, 26));
    });

    test('account must match unless the income has no account', () {
      expect(findSalaryIncome([income(expected, 100000, 'hdfc')], expected: expected, expectedMinor: 100000, now: expected, accountId: 'sbi'), isNull);
      expect(findSalaryIncome([income(expected, 100000)], expected: expected, expectedMinor: 100000, now: expected, accountId: 'sbi'), isNotNull);
    });

    test('picks the income closest to the expected day', () {
      final found = findSalaryIncome(
        [income(DateTime(2026, 10, 27), 100000), income(DateTime(2026, 10, 30, 9), 100000)],
        expected: expected,
        expectedMinor: 100000,
        now: DateTime(2026, 11, 1),
      );
      expect(found!.occurredAt, DateTime(2026, 10, 30, 9));
    });
  });

  group('reminder', () {
    final expected = DateTime(2026, 10, 30);
    test('fires the configured number of days after the expected date', () {
      expect(salaryReminderAt(expected, delayDays: 2), DateTime(2026, 11, 1, 10));
    });

    test('waiting, due and seen', () {
      expect(salaryReminderState(expected: expected, now: DateTime(2026, 11, 1, 9), seen: false, delayDays: 2), SalaryReminderState.waiting);
      expect(salaryReminderState(expected: expected, now: DateTime(2026, 11, 1, 10), seen: false, delayDays: 2), SalaryReminderState.due);
      expect(salaryReminderState(expected: expected, now: DateTime(2026, 11, 5), seen: true, delayDays: 2), SalaryReminderState.seen);
    });
  });

  group('evaluate salary', () {
    IncomeCandidate income(DateTime at, int amount) => IncomeCandidate(occurredAt: at, amountMinor: amount);

    test('due when nothing arrived after the delay', () {
      final status = evaluateSalary(now: DateTime(2026, 11, 3, 12), salaryDay: 31, expectedMinor: 100000, incomes: const [], shift: SalaryShift.previousWorkingDay);
      expect(status.expected, DateTime(2026, 10, 30));
      expect(status.next, DateTime(2026, 11, 30));
      expect(status.reminderState, SalaryReminderState.due);
      expect(status.reminderAt, DateTime(2026, 11, 1, 10));
    });

    test('an SMS income that arrives later flips the state to seen', () {
      final status = evaluateSalary(
        now: DateTime(2026, 11, 3, 12),
        salaryDay: 31,
        expectedMinor: 100000,
        incomes: [income(DateTime(2026, 11, 3, 11), 101000)],
        shift: SalaryShift.previousWorkingDay,
      );
      expect(status.isSeen, isTrue);
      expect(status.reminderState, SalaryReminderState.seen);
    });

    test('last cycle salary does not count for this one', () {
      final status = evaluateSalary(now: DateTime(2026, 12, 3), salaryDay: 31, expectedMinor: 100000, incomes: [income(DateTime(2026, 10, 30), 100000)], shift: SalaryShift.previousWorkingDay);
      expect(status.expected, DateTime(2026, 11, 30));
      expect(status.isSeen, isFalse);
    });

    test('lookback covers the earliest possible match window', () {
      expect(salaryLookbackStart(DateTime(2026, 11, 3), windowDays: 4), DateTime(2026, 8, 30));
      expect(salaryLookbackStart(DateTime(2026, 11, 3)), DateTime(2026, 8, 27), reason: 'defaults to the widest window the user can pick');
    });

    test('a wider window and tolerance from the settings catch an early, smaller salary', () {
      final early = [income(DateTime(2026, 9, 25), 80000)];
      final strict = evaluateSalary(now: DateTime(2026, 10, 2), salaryDay: 1, expectedMinor: 100000, incomes: early);
      expect(strict.isSeen, isFalse, reason: '6 days early and 20% short misses the 4-day, 15% defaults');
      final windowOnly = evaluateSalary(now: DateTime(2026, 10, 2), salaryDay: 1, expectedMinor: 100000, incomes: early, windowDays: 7);
      expect(windowOnly.isSeen, isFalse, reason: 'still 20% short');

      final relaxed = evaluateSalary(
        now: DateTime(2026, 10, 2),
        salaryDay: 1,
        expectedMinor: 100000,
        incomes: early,
        windowDays: 7,
        tolerance: salaryToleranceFraction(20),
      );
      expect(relaxed.isSeen, isTrue);
    });

    test('a zero tolerance needs the exact amount', () {
      final status = evaluateSalary(now: DateTime(2026, 10, 2), salaryDay: 1, expectedMinor: 100000, incomes: [income(DateTime(2026, 10, 1), 99999)], tolerance: salaryToleranceFraction(0));
      expect(status.isSeen, isFalse);
    });
  });

  group('detection bounds', () {
    test('match window is kept between 1 and 7 days', () {
      expect(clampSalaryMatchWindowDays(0), 1);
      expect(clampSalaryMatchWindowDays(4), 4);
      expect(clampSalaryMatchWindowDays(30), 7);
    });

    test('tolerance is kept between 0 and 50 percent and becomes a fraction', () {
      expect(clampSalaryTolerancePercent(-5), 0);
      expect(clampSalaryTolerancePercent(90), 50);
      expect(salaryToleranceFraction(15), closeTo(0.15, 1e-9));
      expect(salaryToleranceFraction(200), closeTo(0.5, 1e-9));
      expect(kSalaryTolerancePercentChoices, contains(kDefaultSalaryTolerancePercent));
    });
  });

  group('claim the rule occurrence', () {
    SalaryStatus status({String? recurringId, bool received = true}) => SalaryStatus(
          expected: DateTime(2026, 10, 30),
          next: DateTime(2026, 11, 30),
          received: received ? IncomeCandidate(id: 'sms-1', occurredAt: DateTime(2026, 10, 30, 9), amountMinor: 100000, recurringId: recurringId) : null,
          reminderState: SalaryReminderState.seen,
          reminderAt: DateTime(2026, 11, 1, 10),
        );

    test('claims this cycle occurrence for an SMS income', () {
      expect(shouldClaimSalaryOccurrence(status(), ruleNextDue: DateTime(2026, 10, 31), ruleId: 'r'), isTrue);
    });

    test('leaves next cycle, missing salary and already linked entries alone', () {
      expect(shouldClaimSalaryOccurrence(status(), ruleNextDue: DateTime(2026, 11, 30), ruleId: 'r'), isFalse);
      expect(shouldClaimSalaryOccurrence(status(received: false), ruleNextDue: DateTime(2026, 10, 31), ruleId: 'r'), isFalse);
      expect(shouldClaimSalaryOccurrence(status(recurringId: 'r'), ruleNextDue: DateTime(2026, 11, 30), ruleId: 'r'), isFalse);
      expect(shouldClaimSalaryOccurrence(status(), ruleNextDue: null, ruleId: 'r'), isFalse);
    });
  });

  group('notification plan', () {
    SalaryStatus status({bool seen = false}) => SalaryStatus(
          expected: DateTime(2026, 10, 30),
          next: DateTime(2026, 11, 30),
          received: seen ? IncomeCandidate(occurredAt: DateTime(2026, 10, 30), amountMinor: 1) : null,
          reminderState: seen ? SalaryReminderState.seen : SalaryReminderState.waiting,
          reminderAt: DateTime(2026, 11, 1, 10),
        );

    test('schedules ahead before the reminder moment', () {
      expect(planSalaryNotification(status(), reminderEnabled: true, now: DateTime(2026, 10, 28)),
          ScheduleSalaryNotification(at: DateTime(2026, 11, 1, 10), expected: DateTime(2026, 10, 30)));
    });

    test('shows at once when already due', () {
      final now = DateTime(2026, 11, 2, 8);
      expect(planSalaryNotification(status(), reminderEnabled: true, now: now), ScheduleSalaryNotification(at: now, expected: DateTime(2026, 10, 30)));
    });

    test('cancels when seen, disabled, not set up or long stale', () {
      expect(planSalaryNotification(status(seen: true), reminderEnabled: true, now: DateTime(2026, 11, 2)), isA<CancelSalaryNotification>());
      expect(planSalaryNotification(status(), reminderEnabled: false, now: DateTime(2026, 11, 2)), isA<CancelSalaryNotification>());
      expect(planSalaryNotification(null, reminderEnabled: true, now: DateTime(2026, 11, 2)), isA<CancelSalaryNotification>());
      expect(planSalaryNotification(status(), reminderEnabled: true, now: DateTime(2026, 11, 20)), isA<CancelSalaryNotification>());
    });
  });
}

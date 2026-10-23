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
      expect(nearestSalaryToleranceChoice(15), 15);
      expect(nearestSalaryToleranceChoice(33), 30);
      expect(nearestSalaryToleranceChoice(37), 40);
      expect(nearestSalaryToleranceChoice(-1), 0);
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
      final plan = planSalaryNotification(status(), reminderEnabled: true, now: now);
      expect(plan, ScheduleSalaryNotification(at: now.add(kSalaryAlertLead), expected: DateTime(2026, 10, 30), overdue: true));
      expect((plan as ScheduleSalaryNotification).at.isAfter(now), isTrue, reason: 'the OS rejects a time that is not in the future');
    });

    test('cancels when seen, disabled, not set up or long stale', () {
      expect(planSalaryNotification(status(seen: true), reminderEnabled: true, now: DateTime(2026, 11, 2)), isA<CancelSalaryNotification>());
      expect(planSalaryNotification(status(), reminderEnabled: false, now: DateTime(2026, 11, 2)), isA<CancelSalaryNotification>());
      expect(planSalaryNotification(null, reminderEnabled: true, now: DateTime(2026, 11, 2)), isA<CancelSalaryNotification>());
      expect(planSalaryNotification(status(), reminderEnabled: true, now: DateTime(2026, 11, 20)), isA<CancelSalaryNotification>());
    });
  });

  group('alert fire time and repeats', () {
    final overdue = ScheduleSalaryNotification(at: DateTime(2026, 11, 2, 8, 0, 5), expected: DateTime(2026, 10, 30), overdue: true);
    final ahead = ScheduleSalaryNotification(at: DateTime(2026, 11, 1, 10), expected: DateTime(2026, 10, 30));

    test('never in the past, and a moment ahead when the moment is now', () {
      final now = DateTime(2026, 11, 2, 8);
      expect(salaryAlertFireAt(DateTime(2026, 11, 1, 10), now: now), now.add(kSalaryAlertLead));
      expect(salaryAlertFireAt(now, now: now), now.add(kSalaryAlertLead));
      expect(salaryAlertFireAt(DateTime(2026, 11, 3, 10), now: now), DateTime(2026, 11, 3, 10));
    });

    test('an overdue alert posts once per cycle and language', () {
      final marker = salaryAlertMarker(overdue, locale: 'en');
      expect(shouldApplySalaryPlan(overdue, postedMarker: null, locale: 'en'), isTrue);
      expect(shouldApplySalaryPlan(overdue, postedMarker: marker, locale: 'en'), isFalse);
      expect(shouldApplySalaryPlan(overdue, postedMarker: marker, locale: 'hi'), isTrue, reason: 'a language change refreshes the text');
      expect(shouldApplySalaryPlan(ahead, postedMarker: salaryAlertMarker(ahead, locale: 'en'), locale: 'en'), isTrue);
      expect(shouldApplySalaryPlan(const CancelSalaryNotification(), postedMarker: marker, locale: 'en'), isTrue);
    });
  });

  group('early salary and status lines', () {
    IncomeCandidate income(DateTime at, int amount) => IncomeCandidate(occurredAt: at, amountMinor: amount);

    test('an early salary settles the next cycle as soon as it arrives', () {
      final status = evaluateSalary(
        now: DateTime(2026, 11, 28, 12),
        salaryDay: 30,
        expectedMinor: 100000,
        incomes: [income(DateTime(2026, 10, 30), 100000), income(DateTime(2026, 11, 27, 10), 100000)],
      );
      expect(status.isSeen, isTrue);
      expect(status.expected, DateTime(2026, 11, 30));
      expect(status.next, DateTime(2026, 12, 30));
      expect(status.reminderState, SalaryReminderState.seen);
    });

    test('a missed cycle is late and remembers the last salary received', () {
      final status = evaluateSalary(
        now: DateTime(2026, 12, 5, 12),
        salaryDay: 30,
        expectedMinor: 100000,
        incomes: [income(DateTime(2026, 10, 30, 9), 99000)],
      );
      expect(status.isSeen, isFalse);
      expect(status.isLate, isTrue);
      expect(status.expected, DateTime(2026, 11, 30));
      expect(status.lastReceived?.occurredAt, DateTime(2026, 10, 30, 9));
    });

    test('not late before the reminder moment', () {
      final status = evaluateSalary(now: DateTime(2026, 11, 30, 12), salaryDay: 30, expectedMinor: 100000, incomes: const []);
      expect(status.isLate, isFalse);
      expect(status.lastReceived, isNull);
    });
  });

  group('salary rule due date', () {
    test('the cycle of a shifted or unshifted date is the nearest unshifted one', () {
      expect(nominalSalaryCycleOf(DateTime(2026, 10, 30, 9), salaryDay: 1), DateTime(2026, 11, 1));
      expect(nominalSalaryCycleOf(DateTime(2026, 11, 2, 9), salaryDay: 31), DateTime(2026, 10, 31));
      expect(nominalSalaryCycleOf(DateTime(2026, 10, 31), salaryDay: 31), DateTime(2026, 10, 31));
    });

    test('applies the weekend shift and keeps the time of day', () {
      final anchor = salaryRuleAnchorFor(DateTime(2026, 10, 31, 9), postedCount: 0, salaryDay: 31);
      expect(alignedSalaryRuleDue(DateTime(2026, 10, 31, 9), postedCount: 0, salaryDay: 31, anchor: anchor, shift: SalaryShift.previousWorkingDay), DateTime(2026, 10, 30, 9));
      expect(alignedSalaryRuleDue(DateTime(2026, 10, 31, 9), postedCount: 0, salaryDay: 31, anchor: anchor), DateTime(2026, 10, 31, 9));
    });

    test('follows the lifetime count after the engine steps a shifted date', () {
      final anchor = salaryRuleAnchorFor(DateTime(2026, 11, 1, 9), postedCount: 0, salaryDay: 1);
      // Engine stepped from Friday 30 Oct to 1 Nov; one occurrence was consumed.
      expect(alignedSalaryRuleDue(DateTime(2026, 11, 1, 9), postedCount: 1, salaryDay: 1, anchor: anchor, shift: SalaryShift.previousWorkingDay), DateTime(2026, 12, 1, 9));
    });

    test('falls back to the nearest cycle without an anchor', () {
      expect(alignedSalaryRuleDue(DateTime(2026, 10, 31, 9), postedCount: 3, salaryDay: 31, shift: SalaryShift.previousWorkingDay), DateTime(2026, 10, 30, 9));
    });

    test('an anchor round trips and rejects junk', () {
      final anchor = SalaryRuleAnchor(nominal: DateTime(2026, 10, 31), postedCount: 2);
      expect(SalaryRuleAnchor.fromJson(anchor.toJson()), anchor);
      expect(SalaryRuleAnchor.fromJson({'nominal': 'x', 'postedCount': 1}), isNull);
      expect(SalaryRuleAnchor.fromJson('nope'), isNull);
    });

    test('claims only the cycle the income settled', () {
      final status = SalaryStatus(
        expected: DateTime(2026, 11, 30),
        next: DateTime(2026, 12, 30),
        received: IncomeCandidate(id: 'early', occurredAt: DateTime(2026, 11, 27), amountMinor: 1),
        reminderState: SalaryReminderState.seen,
        reminderAt: DateTime(2026, 12, 2, 10),
      );
      expect(shouldClaimSalaryOccurrence(status, ruleNextDue: DateTime(2026, 11, 30, 9), ruleId: 'r'), isTrue);
      expect(shouldClaimSalaryOccurrence(status, ruleNextDue: DateTime(2026, 10, 30, 9), ruleId: 'r'), isFalse, reason: 'a missed cycle stays waiting');
    });
  });

  group('tracking starts with the rule', () {
    // Set up on Friday 23 Oct 2026 with day 31; 30 Sep was the previous cycle.
    SalaryStatus evaluateOn(DateTime now, {DateTime? trackedSince, Iterable<IncomeCandidate> incomes = const []}) => evaluateSalary(
          now: now,
          salaryDay: 31,
          expectedMinor: 10000000,
          incomes: incomes,
          shift: SalaryShift.sameDay,
          reminderDelayDays: 1,
          trackedSince: trackedSince,
        );

    test('a cycle before the setup day is never late', () {
      final status = evaluateOn(DateTime(2026, 10, 23, 12), trackedSince: DateTime(2026, 10, 23));
      expect(status.expected, DateTime(2026, 10, 31), reason: 'the first expected date on or after setup');
      expect(status.isLate, isFalse);
      expect(status.next, DateTime(2026, 11, 30));
    });

    test('without a start date (older setups) the previous cycle still counts', () {
      final status = evaluateOn(DateTime(2026, 10, 23, 12));
      expect(status.expected, DateTime(2026, 9, 30));
      expect(status.isLate, isTrue);
    });

    test('once the first cycle passes it is tracked and can be late', () {
      final status = evaluateOn(DateTime(2026, 11, 3, 12), trackedSince: DateTime(2026, 10, 23));
      expect(status.expected, DateTime(2026, 10, 31));
      expect(status.isLate, isTrue);
    });

    test('a salary expected on the setup day itself is tracked', () {
      expect(isBeforeSalaryTracking(DateTime(2026, 10, 23), trackedSince: DateTime(2026, 10, 23, 15)), isFalse);
      expect(isBeforeSalaryTracking(DateTime(2026, 10, 22), trackedSince: DateTime(2026, 10, 23)), isTrue);
      expect(isBeforeSalaryTracking(DateTime(2020, 1, 1), trackedSince: null), isFalse);
    });
  });

  test('only a new rule or a changed salary day restarts the rule', () {
    expect(shouldRestartSalaryRule(ruleDay: 31, salaryDay: 31), isFalse);
    expect(shouldRestartSalaryRule(ruleDay: 31, salaryDay: 25), isTrue);
    expect(shouldRestartSalaryRule(ruleDay: null, salaryDay: 25), isTrue);
  });
}

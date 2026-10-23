import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/recurring/repeat_draft.dart';

void main() {
  final start = DateTime(2026, 1, 31, 9, 30);

  group('RepeatDraft.specFrom', () {
    test('monthly anchors on the start day, or the last day when asked', () {
      expect(const RepeatDraft().specFrom(start).dayOfMonth, 31);
      expect(const RepeatDraft(lastDayOfMonth: true).specFrom(start).dayOfMonth, kLastDayOfMonth);
    });

    test('weekly anchors on the start weekday and ignores the day of month', () {
      final spec = const RepeatDraft(frequency: RecurrenceFrequency.weekly, interval: 2).specFrom(start);
      expect(spec.weekday, DateTime.saturday);
      expect(spec.dayOfMonth, isNull);
      expect(spec.interval, 2);
    });

    test('only the chosen end condition is carried', () {
      final endDate = DateTime(2026, 12, 31);
      final draft = RepeatDraft(end: RepeatEnd.afterCount, maxCount: 12, endDate: endDate);
      expect(draft.specFrom(start).maxCount, 12);
      expect(draft.specFrom(start).endDate, isNull);
      final byDate = draft.copyWith(end: RepeatEnd.onDate).specFrom(start);
      expect(byDate.endDate, endDate);
      expect(byDate.maxCount, isNull);
    });

    test('a zero interval is treated as every one', () {
      expect(const RepeatDraft(interval: 0).specFrom(start).interval, 1);
    });
  });

  test('fromSpec round-trips a draft', () {
    final drafts = [
      const RepeatDraft(),
      const RepeatDraft(lastDayOfMonth: true, autoPost: false),
      const RepeatDraft(frequency: RecurrenceFrequency.weekly, interval: 3, end: RepeatEnd.afterCount, maxCount: 4),
      RepeatDraft(frequency: RecurrenceFrequency.yearly, end: RepeatEnd.onDate, endDate: DateTime(2030, 1, 1)),
    ];
    for (final draft in drafts) {
      expect(RepeatDraft.fromSpec(draft.specFrom(start), autoPost: draft.autoPost), draft);
    }
  });

  test('isValidFrom rejects an end before the start and a zero count', () {
    expect(const RepeatDraft().isValidFrom(start), isTrue);
    expect(RepeatDraft(end: RepeatEnd.onDate, endDate: DateTime(2026, 1, 30)).isValidFrom(start), isFalse);
    expect(RepeatDraft(end: RepeatEnd.onDate, endDate: DateTime(2026, 1, 31)).isValidFrom(start), isTrue);
    expect(const RepeatDraft(end: RepeatEnd.onDate).isValidFrom(start), isFalse);
    expect(const RepeatDraft(end: RepeatEnd.afterCount, maxCount: 0).isValidFrom(start), isFalse);
    expect(const RepeatDraft(end: RepeatEnd.afterCount, maxCount: 1).isValidFrom(start), isTrue);
  });

  group('sectionOf', () {
    final now = DateTime(2026, 10, 10, 12);
    test('confirm-first rules with a due occurrence wait', () {
      expect(sectionOf(status: RecurringStatus.active, autoPost: false, nextDue: DateTime(2026, 10, 5), now: now), RecurringSection.waiting);
      expect(sectionOf(status: RecurringStatus.active, autoPost: false, nextDue: DateTime(2026, 11, 5), now: now), RecurringSection.active);
      expect(sectionOf(status: RecurringStatus.active, autoPost: true, nextDue: DateTime(2026, 10, 5), now: now), RecurringSection.active);
    });

    test('paused and ended follow the status; no next date means ended', () {
      expect(sectionOf(status: RecurringStatus.paused, autoPost: false, nextDue: DateTime(2026, 10, 5), now: now), RecurringSection.paused);
      expect(sectionOf(status: RecurringStatus.ended, autoPost: true, nextDue: null, now: now), RecurringSection.ended);
      expect(sectionOf(status: RecurringStatus.active, autoPost: true, nextDue: null, now: now), RecurringSection.ended);
    });
  });

  test('waitingCount counts every due occurrence of a confirm-first rule', () {
    final spec = const RepeatDraft(autoPost: false).specFrom(DateTime(2026, 7, 5, 9));
    expect(waitingCount(spec, nextDue: DateTime(2026, 7, 5, 9), now: DateTime(2026, 10, 6), postedCount: 0), 4);
    expect(waitingCount(spec, nextDue: DateTime(2026, 11, 5, 9), now: DateTime(2026, 10, 6), postedCount: 0), 0);
  });

  test('recurringTally splits used slots into added and skipped', () {
    expect(recurringTally(postedCount: 3, skippedCount: 1), (added: 2, skipped: 1));
    expect(recurringTally(postedCount: 2, skippedCount: 0), (added: 2, skipped: 0));
    expect(recurringTally(postedCount: 2, skippedCount: 5), (added: 0, skipped: 2), reason: 'skips never exceed used slots');
    expect(recurringTally(postedCount: -1, skippedCount: -1), (added: 0, skipped: 0));
  });
}

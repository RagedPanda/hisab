import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hisab/data/repositories/recurring_repository.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/recurring/repeat_draft.dart';
import 'package:hisab/features/recurring/recurring_list_model.dart';
import 'package:hisab/features/recurring/repeat_sheet.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';

RecurringRuleView view(String id, {String status = RecurringStatus.active, bool autoPost = true, DateTime? nextDue, int postedCount = 0}) => RecurringRuleView(
      rule: RecurringRule(
        id: id,
        name: id,
        kind: 'expense',
        amountMinor: 100,
        currency: 'INR',
        note: '',
        frequency: 'monthly',
        interval: 1,
        dayOfMonth: 5,
        startDate: DateTime(2026, 7, 5, 9),
        postedCount: postedCount,
        nextDue: nextDue,
        autoPost: autoPost,
        remindDaysBefore: '',
        isSubscription: false,
        status: status,
        createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 7, 1),
      ),
    );

void main() {
  final now = DateTime(2026, 10, 10, 12);

  test('recurringListItems groups by section and counts waiting occurrences', () {
    final items = recurringListItems([
      view('ended', status: RecurringStatus.ended),
      view('later', nextDue: DateTime(2026, 12, 5, 9)),
      view('paused', status: RecurringStatus.paused, nextDue: DateTime(2026, 11, 5, 9)),
      view('soon', nextDue: DateTime(2026, 11, 5, 9)),
      view('confirm', autoPost: false, nextDue: DateTime(2026, 8, 5, 9), postedCount: 1),
    ], now: now);
    expect(items.map((item) => item.view.rule.id), ['confirm', 'soon', 'later', 'paused', 'ended']);
    expect(items.first.section, RecurringSection.waiting);
    expect(items.first.waiting, 3, reason: 'Aug, Sep and Oct are due');
    expect(totalWaiting(items), 3);
  });

  group('repeatSummary', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final start = DateTime(2026, 7, 5, 9); // a Sunday
    setUpAll(() => initializeDateFormatting('en'));

    test('reads the schedule and its end', () {
      expect(repeatSummary(en, const RepeatDraft(), start, locale: 'en'), 'Every month on day 5');
      expect(repeatSummary(en, const RepeatDraft(lastDayOfMonth: true, end: RepeatEnd.afterCount, maxCount: 12), start, locale: 'en'), 'Every month on the last day, 12 times');
      expect(repeatSummary(en, const RepeatDraft(frequency: RecurrenceFrequency.weekly, interval: 2), start, locale: 'en'), 'Every 2 weeks on Sunday');
      expect(repeatSummary(en, const RepeatDraft(frequency: RecurrenceFrequency.daily), start, locale: 'en'), 'Every day');
      expect(repeatSummary(en, RepeatDraft(frequency: RecurrenceFrequency.yearly, end: RepeatEnd.onDate, endDate: DateTime(2030, 7, 5)), start, locale: 'en'), 'Every year on 5 Jul, until 5 Jul 2030');
    });
  });
}

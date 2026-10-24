import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/split/settle_reminder.dart';
import 'package:hisab/features/groups/settle_reminder_sheet.dart';
import 'package:hisab/features/groups/settle_up_messages.dart';
import 'package:hisab/l10n/generated/app_localizations_en.dart';
import 'package:hisab/l10n/generated/app_localizations_hi.dart';
import 'package:hisab/l10n/l10n.dart';

final _ravi = Member(updatedAt: DateTime(2026), id: 'ravi', groupId: 'flat', name: 'Ravi', isMe: false, weight: 1);

/// Thursday 22 Oct 2026, noon.
DateTime _now() => DateTime(2026, 10, 22, 12);

/// Opens the sheet from a button; the returned list receives the sheet's
/// result once it closes.
Future<List<SettleReminderChoice?>> _openSheet(WidgetTester tester, {SettleReminderSchedule? existing}) async {
  final results = <SettleReminderChoice?>[];
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () async =>
              results.add(await showSettleReminderSheet(context, otherMembers: [_ravi], existing: existing, clock: _now)),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  testWidgets('defaults to the 1st of each month about everyone', (tester) async {
    final results = await _openSheet(tester);
    expect(find.text('Next reminder: Sun, 1 Nov'), findsOneWidget);
    expect(find.text('Turn off'), findsNothing);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(results.single?.schedule,
        const SettleReminderSchedule(frequency: RecurrenceFrequency.monthly, dayOfMonth: 1));
  });

  testWidgets('a weekly reminder about one member', (tester) async {
    final results = await _openSheet(tester);
    await tester.tap(find.text('Ravi'));
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mon'));
    await tester.pumpAndSettle();
    expect(find.text('Next reminder: Mon, 26 Oct'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(results.single?.schedule,
        const SettleReminderSchedule(frequency: RecurrenceFrequency.weekly, weekday: DateTime.monday, memberId: 'ravi'));
  });

  testWidgets('an existing reminder can be turned off', (tester) async {
    final results = await _openSheet(tester,
        existing: const SettleReminderSchedule(frequency: RecurrenceFrequency.monthly, dayOfMonth: kLastDayOfMonth, memberId: 'ravi'));
    expect(find.text('Last day'), findsOneWidget);
    expect(find.text('Next reminder: Sat, 31 Oct'), findsOneWidget);
    await tester.tap(find.text('Turn off'));
    await tester.pumpAndSettle();
    expect(results.single, isNotNull);
    expect(results.single?.schedule, isNull);
  });

  group('settleScheduleSummary', () {
    final english = AppLocalizationsEn();
    test('monthly on a day and on the last day', () {
      expect(settleScheduleSummary(english, const SettleReminderSchedule(frequency: RecurrenceFrequency.monthly, dayOfMonth: 5)),
          'Reminder on day 5 every month');
      expect(
          settleScheduleSummary(english, const SettleReminderSchedule(frequency: RecurrenceFrequency.monthly, dayOfMonth: kLastDayOfMonth)),
          'Reminder on the last day of every month');
    });
    test('weekly names the weekday', () {
      expect(settleScheduleSummary(english, const SettleReminderSchedule(frequency: RecurrenceFrequency.weekly, weekday: DateTime.sunday), locale: 'en'),
          'Reminder every Sunday');
    });
    test('Hindi keeps the day number', () {
      expect(settleScheduleSummary(AppLocalizationsHi(), const SettleReminderSchedule(frequency: RecurrenceFrequency.monthly, dayOfMonth: 5)),
          contains('5'));
    });
  });
}

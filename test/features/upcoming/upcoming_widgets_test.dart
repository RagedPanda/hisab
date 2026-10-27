import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/recurring_repository.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/upcoming/upcoming_items.dart';
import 'package:hisab/features/dashboard/dashboard_keys.dart';
import 'package:hisab/features/dashboard/widgets/upcoming_card.dart';
import 'package:hisab/features/upcoming/upcoming_calendar_screen.dart';
import 'package:hisab/features/upcoming/upcoming_providers.dart';
import 'package:hisab/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

final today = DateTime(2026, 10, 22);

UpcomingInputs sampleInputs() => UpcomingInputs(
  reminders: [
    ReminderInput(id: 'electricity', title: 'Electricity bill', dueAt: DateTime(2026, 10, 19), amountMinor: 184000),
    ReminderInput(id: 'insurance', title: 'Car insurance', dueAt: DateTime(2026, 11, 10), amountMinor: 1250000),
  ],
  recurring: [RecurringOccurrenceInput(ruleId: 'rent', title: 'Rent', dueAt: DateTime(2026, 10, 25), amountMinor: 2000000)],
);

Future<void> pump(WidgetTester tester, Widget child, {UpcomingInputs? inputs, Locale locale = const Locale('en'), List<Override> overrides = const []}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        upcomingTodayProvider.overrideWithValue(today),
        upcomingInputsProvider.overrideWith((ref, range) => AsyncData(inputs ?? const UpcomingInputs())),
        ...overrides,
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Upcoming card', () {
    testWidgets('hides the card when nothing is due in the window', (tester) async {
      await pump(tester, const UpcomingCard());
      expect(find.byKey(kUpcomingCardKey), findsNothing);
      expect(find.text('Upcoming'), findsNothing);
    });

    testWidgets('lists overdue first with a red label and the 7 day items', (tester) async {
      await pump(tester, const UpcomingCard(), inputs: sampleInputs());
      expect(find.text('Electricity bill'), findsOneWidget);
      expect(find.text('Overdue by 3 days'), findsOneWidget);
      expect(find.text('1 overdue'), findsOneWidget);
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Car insurance'), findsNothing, reason: 'due in 19 days, outside the week');
      final overdueLabel = tester.widget<Text>(find.text('Overdue by 3 days'));
      final context = tester.element(find.text('Overdue by 3 days'));
      expect(overdueLabel.style?.color, Theme.of(context).colorScheme.error);
      expect(tester.getTopLeft(find.text('Electricity bill')).dy, lessThan(tester.getTopLeft(find.text('Rent')).dy));
    });

    testWidgets('the 30 day toggle widens the list and is remembered', (tester) async {
      await pump(tester, const UpcomingCard(), inputs: sampleInputs());
      await tester.tap(find.byKey(const ValueKey('upcoming.window.month')));
      await tester.pumpAndSettle();
      expect(find.text('Car insurance'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kUpcomingWindowPrefKey), 'month');
    });

    testWidgets('renders in Hindi', (tester) async {
      await pump(tester, const UpcomingCard(), inputs: sampleInputs(), locale: const Locale('hi'));
      expect(find.text('3 दिन से बकाया'), findsOneWidget);
    });
  });

  testWidgets('tapping an overdue confirm-first item offers Confirm, which posts it, and Edit', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final ruleId = (await tester.runAsync(
      () => RecurringRepository(db).saveRule(
        RecurringRepository.newRule(
          name: 'Rent',
          kind: 'expense',
          amountMinor: 2000000,
          frequency: RecurrenceFrequency.monthly,
          dayOfMonth: 18,
          startDate: DateTime(2026, 10, 18, 9),
          autoPost: false,
        ),
      ),
    ))!;
    final inputs = UpcomingInputs(
      recurring: [RecurringOccurrenceInput(ruleId: ruleId, title: 'Rent', dueAt: DateTime(2026, 10, 18, 9), amountMinor: 2000000, awaitsConfirm: true)],
    );
    await pump(tester, const UpcomingCard(), inputs: inputs, overrides: [databaseProvider.overrideWithValue(db)]);

    await tester.tap(find.text('Rent'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('upcoming.confirm.post')), findsOneWidget);
    expect(find.byKey(const ValueKey('upcoming.confirm.edit')), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget, reason: 'Edit stays available as the secondary action');

    await tester.tap(find.byKey(const ValueKey('upcoming.confirm.post')));
    await tester.pumpAndSettle();
    final entries = await tester.runAsync(() => db.select(db.entries).get());
    expect(entries!.map((entry) => entry.recurringId), [ruleId], reason: 'Confirm posted the waiting occurrence');
    expect(find.byKey(const ValueKey('upcoming.confirm.post')), findsNothing);
  });

  testWidgets('the Confirm sheet sits above a shell Add button: tapping the centre of Confirm confirms', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final ruleId = (await tester.runAsync(
      () => RecurringRepository(db).saveRule(
        RecurringRepository.newRule(
          name: 'Rent',
          kind: 'expense',
          amountMinor: 2000000,
          frequency: RecurrenceFrequency.monthly,
          dayOfMonth: 18,
          startDate: DateTime(2026, 10, 18, 9),
          autoPost: false,
        ),
      ),
    ))!;
    final inputs = UpcomingInputs(
      recurring: [RecurringOccurrenceInput(ruleId: ruleId, title: 'Rent', dueAt: DateTime(2026, 10, 18, 9), amountMinor: 2000000, awaitsConfirm: true)],
    );
    var addTaps = 0;
    // Like the app shell: the tab content lives in a nested navigator under a
    // Scaffold whose wide "Add entry" button floats over the bottom centre.
    final shell = Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('shell.add'),
        onPressed: () => addTaps++,
        label: const SizedBox(width: 600, child: Text('Add entry')),
      ),
      body: Navigator(onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => const SingleChildScrollView(child: UpcomingCard()))),
    );
    await pump(tester, SizedBox(height: 600, child: shell), inputs: inputs, overrides: [databaseProvider.overrideWithValue(db)]);

    await tester.tap(find.text('Rent'));
    await tester.pumpAndSettle();
    final confirm = find.byKey(const ValueKey('upcoming.confirm.post'));
    await tester.tapAt(tester.getCenter(confirm));
    await tester.pumpAndSettle();

    expect(addTaps, 0, reason: 'the Add button must not catch a tap on Confirm');
    final entries = await tester.runAsync(() => db.select(db.entries).get());
    expect(entries!.map((entry) => entry.recurringId), [ruleId], reason: 'tapping the centre of Confirm posted the occurrence');
    expect(confirm, findsNothing);
  });

  group('Due calendar', () {
    testWidgets('draws dots on due days and lists the tapped day', (tester) async {
      await pump(tester, const SizedBox(height: 900, child: UpcomingCalendarScreen()), inputs: sampleInputs());
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.byKey(const ValueKey('upcoming.calendar.dayEmpty')), findsOneWidget, reason: 'nothing due today');
      final rentDay = find.byKey(const ValueKey('upcoming.calendar.day.25'));
      expect(tester.getSemantics(rentDay).label, contains('1 due'));
      await tester.tap(rentDay);
      await tester.pumpAndSettle();
      expect(find.text('Rent'), findsOneWidget);
    });

    testWidgets('starts the week on the device region: Monday for en-GB, Sunday for en-US', (tester) async {
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      double left(String label) => tester.getTopLeft(find.text(label)).dx;

      tester.platformDispatcher.localesTestValue = const [Locale('en', 'GB')];
      await pump(tester, const SizedBox(height: 900, child: UpcomingCalendarScreen()));
      expect(left('Mon'), lessThan(left('Sun')));

      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      await pump(tester, const SizedBox(height: 900, child: UpcomingCalendarScreen()));
      expect(left('Sun'), lessThan(left('Mon')));
    });

    testWidgets('moves between months', (tester) async {
      await pump(tester, const SizedBox(height: 900, child: UpcomingCalendarScreen()), inputs: sampleInputs());
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('upcoming.calendar.day.10')));
      await tester.pumpAndSettle();
      expect(find.text('Car insurance'), findsOneWidget);
    });
  });
}

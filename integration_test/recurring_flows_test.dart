/// Recurring entries end to end: Repeat in the editor, catch-up posting on
/// resume, confirm-first rules from the dashboard banner, pause, delete with
/// undo, editing a rule, and a screenshot tour in English and Hindi, light
/// and dark.
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/recurring_flows_test.dart -d $DEV
library;

import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/money.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/recurring_repository.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/features/expense_editor/expense_editor_screen.dart';
import 'package:hisab/features/recurring/recurring_rule_form_screen.dart';
import 'package:hisab/features/recurring/recurring_screen.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:integration_test/integration_test.dart';

import 'harness.dart';

const _configs = [('en', ThemeMode.light), ('en', ThemeMode.dark), ('hi', ThemeMode.light), ('hi', ThemeMode.dark)];

Finder _key(String id) => find.byKey(ValueKey(id));

/// Same day [months] months back at midnight, clamped to that month's
/// length, so this month's occurrence is already due whatever the time.
DateTime _monthsAgo(int months) {
  final now = DateTime.now();
  final month = DateTime(now.year, now.month - months, 1);
  return DateTime(month.year, month.month, now.day.clamp(1, daysInMonth(month.year, month.month)));
}

Future<String> _categoryId(AppHandle app, String seedKey) async {
  final category = await app.read(categoriesRepositoryProvider).findBySeedKey(seedKey);
  expect(category, isNotNull, reason: 'seed category $seedKey');
  return category!.id;
}

Future<List<Entry>> _recurringEntries(AppHandle app, String ruleId) =>
    (app.db.select(app.db.entries)..where((t) => t.recurringId.equals(ruleId) & t.deletedAt.isNull())).get();

/// Seeds the rules the screenshot tour shows: one waiting to confirm, one
/// active, one paused.
Future<void> _seedRules(AppHandle app) async {
  final repository = app.read(recurringRepositoryProvider);
  final cashId = (await app.read(accountsRepositoryProvider).getAll()).first.id;
  await repository.saveRule(RecurringRepository.newRule(
    name: 'SIP',
    kind: 'expense',
    amountMinor: 500000,
    categoryId: await _categoryId(app, 'rent'),
    accountId: cashId,
    frequency: RecurrenceFrequency.monthly,
    dayOfMonth: _monthsAgo(1).day,
    startDate: _monthsAgo(1),
    autoPost: false,
  ));
  await repository.saveRule(RecurringRepository.newRule(
    name: 'Salary',
    kind: 'income',
    amountMinor: 8500000,
    categoryId: await _categoryId(app, 'salary'),
    accountId: cashId,
    frequency: RecurrenceFrequency.monthly,
    dayOfMonth: kLastDayOfMonth,
    startDate: DateTime.now().add(const Duration(days: 3)),
  ));
  final paused = await repository.saveRule(RecurringRepository.newRule(
    name: 'Gym membership',
    kind: 'expense',
    amountMinor: 150000,
    categoryId: await _categoryId(app, 'rent'),
    frequency: RecurrenceFrequency.weekly,
    interval: 2,
    startDate: DateTime.now().add(const Duration(days: 5)),
    maxCount: 12,
  ));
  await repository.setPaused(paused, true, now: DateTime.now());
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('recurring: repeat from the editor, catch up on resume, confirm, skip, pause, delete with undo, edit', (tester) async {
    final app = await createApp();
    addTearDown(app.container.dispose);
    await pumpApp(tester, app);
    final repository = app.read(recurringRepositoryProvider);

    // 1. A new entry with Repeat monthly becomes a rule whose first
    //    occurrence is the entry itself.
    // Read the day once so a run that crosses midnight still matches the
    // date the editor opened with.
    final today = DateTime.now().day;
    await tapFinder(tester, find.byType(FloatingActionButton));
    final amountField = find.descendant(of: find.byType(ExpenseEditorScreen), matching: find.byType(TextField)).first;
    await enterText(tester, amountField, '15000');
    await tapText(tester, 'Choose category');
    await enterText(tester, find.widgetWithText(TextField, 'Search categories'), 'rent');
    await tapText(tester, 'Rent');
    await scrollTo(tester, _key('editor.repeat'));
    expect(find.text('Does not repeat'), findsOneWidget);
    await tapFinder(tester, _key('editor.repeat'), frames: 10);
    await waitFor(tester, _key('repeat.done'));
    await settle(tester, 10);
    expect(find.textContaining('Every month on day $today'), findsWidgets);
    await shoot(tester, 'repeat_sheet');
    await tapFinder(tester, _key('repeat.done'), frames: 10);
    expect(find.textContaining('Every month on day $today'), findsOneWidget);
    await tapFinder(tester, find.widgetWithText(FilledButton, 'Save ${formatMinor(1500000)}'), frames: 12);
    final rule = (await repository.getViews()).single.rule;
    expect(rule.postedCount, 1, reason: 'the saved entry is the first occurrence');
    expect(rule.nextDue!.isAfter(DateTime.now()), isTrue);
    expect((await _recurringEntries(app, rule.id)).single.amountMinor, 1500000);

    // 2. An auto rule left behind for months catches up on resume, once.
    final cashId = (await app.read(accountsRepositoryProvider).getAll()).first.id;
    final backlogId = await repository.saveRule(RecurringRepository.newRule(
      name: 'Maid salary',
      kind: 'expense',
      amountMinor: 400000,
      categoryId: await _categoryId(app, 'rent'),
      accountId: cashId,
      frequency: RecurrenceFrequency.monthly,
      dayOfMonth: _monthsAgo(3).day,
      startDate: _monthsAgo(3),
    ));
    Future<void> resume() async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester, 10);
    }

    await resume();
    final backlog = await _recurringEntries(app, backlogId);
    expect(backlog.length, 4, reason: 'three missed months plus this month');
    await resume();
    expect((await _recurringEntries(app, backlogId)).length, 4, reason: 'resuming again posts nothing new');

    // 3. A confirm-first rule waits on the dashboard; Add posts one, Skip drops one.
    final confirmId = await repository.saveRule(RecurringRepository.newRule(
      name: 'Society maintenance',
      kind: 'expense',
      amountMinor: 250000,
      categoryId: await _categoryId(app, 'rent'),
      accountId: cashId,
      frequency: RecurrenceFrequency.monthly,
      dayOfMonth: _monthsAgo(1).day,
      startDate: _monthsAgo(1),
      autoPost: false,
    ));
    await resume();
    expect(await _recurringEntries(app, confirmId), isEmpty, reason: 'confirm-first rules never post on their own');
    appRouter.go('/home');
    await settle(tester, 10);
    await waitFor(tester, find.text('2 recurring entries to confirm'));
    await shoot(tester, 'dashboard_banner');
    await tapText(tester, '2 recurring entries to confirm', frames: 10);
    expect(find.byType(RecurringScreen), findsOneWidget);
    expect(find.text('Waiting for you'), findsOneWidget);
    expect(find.text('and 1 more waiting'), findsOneWidget);
    await tapFinder(tester, _key('recurring.confirm.$confirmId'), frames: 10);
    expect((await _recurringEntries(app, confirmId)).length, 1);
    await tapFinder(tester, _key('recurring.skip.$confirmId'), frames: 10);
    expect(find.text('Waiting for you'), findsNothing);
    expect((await _recurringEntries(app, confirmId)).length, 1, reason: 'skip posts nothing');

    // 4. Pause, then delete with undo.
    await tapFinder(tester, _key('recurring.menu.$backlogId'));
    await tapText(tester, 'Pause', last: true);
    expect((await repository.getRule(backlogId))!.status, RecurringStatus.paused);
    expect(find.text('Paused'), findsOneWidget);
    await scrollTo(tester, _key('recurring.menu.$confirmId'), up: true);
    await tapFinder(tester, _key('recurring.menu.$confirmId'));
    await tapText(tester, 'Delete', last: true);
    expect(find.text('Society maintenance'), findsNothing);
    await tapText(tester, 'Undo');
    await waitFor(tester, find.text('Society maintenance'));

    // 5. Edit a rule from its card.
    await tapText(tester, 'Maid salary', frames: 10);
    expect(find.byType(RecurringRuleFormScreen), findsOneWidget);
    await enterText(tester, _key('recurring.amount'), '4500');
    await tapFinder(tester, _key('recurring.save'), frames: 10);
    expect((await repository.getRule(backlogId))!.amountMinor, 450000);
    expect(find.byType(RecurringScreen), findsOneWidget);

    // 6. The entry that started a rule links back to it.
    final firstEntry = (await _recurringEntries(app, rule.id)).single;
    appRouter.go('/home');
    await settle(tester, 4);
    appRouter.push('/entry?id=${firstEntry.id}');
    await settle(tester, 10);
    await scrollTo(tester, _key('editor.recurringRule'));
    await tapFinder(tester, _key('editor.recurringRule'), frames: 10);
    expect(find.byType(RecurringRuleFormScreen), findsOneWidget);
  });

  testWidgets('recurring screens in every locale and theme', (tester) async {
    final app = await createApp();
    addTearDown(app.container.dispose);
    await _seedRules(app);
    await pumpApp(tester, app);

    for (final (locale, mode) in _configs) {
      await app.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: locale, themeMode: mode));
      final tag = '${locale}_${mode.name}';
      appRouter.go('/home');
      await settle(tester, 10);
      await shoot(tester, 'dashboard_$tag');
      appRouter.go('/settings');
      await settle(tester, 10);
      await scrollTo(tester, find.byIcon(Icons.repeat));
      await shoot(tester, 'settings_money_$tag');
      appRouter.push('/recurring');
      await settle(tester, 10);
      await shoot(tester, 'recurring_list_$tag');
      appRouter.push('/recurring/new');
      await settle(tester, 10);
      await shoot(tester, 'rule_form_$tag');
      await scrollTo(tester, _key('editor.repeat'));
      await tapFinder(tester, _key('editor.repeat'), frames: 10);
      await tapFinder(tester, find.descendant(of: find.byType(BottomSheet), matching: find.byType(ChoiceChip)).at(6), frames: 4);
      await shoot(tester, 'repeat_sheet_$tag');
      await tester.tapAt(const Offset(20, 40));
      await settle(tester, 8);
      appRouter.go('/home');
      await settle(tester, 6);
    }
  });
}

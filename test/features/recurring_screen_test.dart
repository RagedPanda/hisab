import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/recurring_repository.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/features/recurring/recurring_screen.dart';

import '../support/app_harness.dart';

final _today = DateTime.now();

Future<String> _saveRule(WidgetTester tester, ProviderContainer container, {String name = '', String kind = 'expense', String? payee, String? categoryId, required DateTime start, bool autoPost = true}) async =>
    (await tester.runAsync(() => container.read(recurringRepositoryProvider).saveRule(RecurringRepository.newRule(
          name: name,
          kind: kind,
          amountMinor: 50000,
          payee: payee,
          categoryId: categoryId,
          frequency: RecurrenceFrequency.monthly,
          dayOfMonth: start.day,
          startDate: start,
          autoPost: autoPost,
        ))))!;

/// Marks a rule ended after [posted] uses, [skipped] of them skipped.
Future<void> _endRule(WidgetTester tester, ProviderContainer container, String id, {required int posted, required int skipped}) async {
  final db = container.read(databaseProvider);
  await tester.runAsync(() => (db.update(db.recurringRules)..where((rule) => rule.id.equals(id)))
      .write(RecurringRulesCompanion(status: const Value(RecurringStatus.ended), nextDue: const Value(null), postedCount: Value(posted), skippedCount: Value(skipped))));
}

Future<RecurringRule> _rule(WidgetTester tester, ProviderContainer container, String id) async => (await tester.runAsync(() => container.read(recurringRepositoryProvider).getRule(id)))!;

Future<void> _pickFromMenu(WidgetTester tester, String ruleId, String action) async {
  await tester.tap(find.byKey(ValueKey('recurring.menu.$ruleId')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(action).last);
  await pumpWithDatabase(tester);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('with no rules the screen offers to add one', (tester) async {
    final container = await createContainer();
    await pumpScreen(tester, container, const RecurringScreen());
    expect(find.text('Nothing repeats yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'New recurring'));
    await tester.pumpAndSettle();
    expect(find.text(openedLocation('/recurring/new')), findsOneWidget);
  });

  testWidgets('rules are grouped by what needs doing and titled by name, payee or category', (tester) async {
    final container = await createContainer();
    final groceries = (await tester.runAsync(() => container.read(categoriesRepositoryProvider).findBySeedKey('groceries')))!;
    await _saveRule(tester, container, name: 'Rent', start: DateTime(_today.year, _today.month - 2, 1), autoPost: false);
    await _saveRule(tester, container, payee: ' Cult ', start: DateTime(_today.year, _today.month + 1, 3));
    final paused = await _saveRule(tester, container, categoryId: groceries.id, start: DateTime(_today.year, _today.month + 1, 4));
    final transfer = await _saveRule(tester, container, kind: 'transfer', start: DateTime(_today.year - 1, 1, 5));
    final untitled = await _saveRule(tester, container, start: DateTime(_today.year - 1, 2, 6));
    await tester.runAsync(() => container.read(recurringRepositoryProvider).setPaused(paused, true, now: _today));
    await _endRule(tester, container, transfer, posted: 3, skipped: 1);
    await _endRule(tester, container, untitled, posted: 2, skipped: 0);
    await pumpScreen(tester, container, const RecurringScreen(), size: const Size(430, 1600));

    for (final header in ['Waiting for you', 'Active', 'Paused', 'Ended']) {
      expect(find.text(header), findsOneWidget);
    }
    expect(find.text('Rent'), findsOneWidget);
    expect(find.textContaining('more waiting'), findsOneWidget, reason: 'a confirm-first rule two months behind has more than one occurrence waiting');
    expect(find.textContaining('Due '), findsOneWidget);
    expect(find.text('Cult'), findsOneWidget, reason: 'a rule with no name is titled by its payee');
    expect(find.textContaining('Next '), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget, reason: 'then by its category');
    expect(find.text('Transfer'), findsOneWidget, reason: 'a transfer with nothing else is called a transfer');
    expect(find.text('2 added, 1 skipped'), findsOneWidget);
    expect(find.text('Recurring'), findsNWidgets(2), reason: 'the app bar and the rule with nothing to name it by');
    expect(find.text('Added 2 times'), findsOneWidget);
  });

  testWidgets('a waiting occurrence can be added or skipped from its card', (tester) async {
    final container = await createContainer();
    final rent = await _saveRule(tester, container, name: 'Rent', start: DateTime(_today.year, _today.month - 1, 1), autoPost: false);
    await pumpScreen(tester, container, const RecurringScreen());

    await tester.tap(find.byKey(ValueKey('recurring.confirm.$rent')));
    await pumpWithDatabase(tester);
    expect(find.text('Entry added'), findsOneWidget);
    expect((await _rule(tester, container, rent)).postedCount, 1);

    await tester.tap(find.byKey(ValueKey('recurring.skip.$rent')));
    await pumpWithDatabase(tester);
    await tester.pumpAndSettle();
    expect(find.text('Skipped'), findsOneWidget, reason: 'the previous snackbar makes way for this one');
    expect((await _rule(tester, container, rent)).skippedCount, 1);
  });

  testWidgets('the menu pauses, resumes, edits and deletes with undo', (tester) async {
    final container = await createContainer();
    final gym = await _saveRule(tester, container, name: 'Gym', start: DateTime(_today.year, _today.month + 1, 5));
    final router = await pumpScreen(tester, container, const RecurringScreen());

    await _pickFromMenu(tester, gym, 'Pause');
    expect((await _rule(tester, container, gym)).status, RecurringStatus.paused);
    expect(find.text('Paused'), findsOneWidget);

    await _pickFromMenu(tester, gym, 'Resume');
    expect((await _rule(tester, container, gym)).status, RecurringStatus.active);

    await _pickFromMenu(tester, gym, 'Edit');
    await tester.pumpAndSettle();
    expect(find.text(openedLocation('/recurring/$gym')), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gym'));
    await tester.pumpAndSettle();
    expect(find.text(openedLocation('/recurring/$gym')), findsOneWidget, reason: 'tapping the card opens it too');
    router.pop();
    await tester.pumpAndSettle();

    await _pickFromMenu(tester, gym, 'Delete');
    expect(find.text('Recurring entry deleted'), findsOneWidget);
    expect(find.text('Gym'), findsNothing);
    await tester.tap(find.text('Undo'));
    await pumpWithDatabase(tester);
    expect(find.text('Gym'), findsOneWidget);
  });
}

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/subscriptions/subscription_templates.dart';
import 'package:hisab/features/shell/router.dart';

import '../support/app_harness.dart' show enter, settle;
import '../support/screen_harness.dart';
import 'groups_screen_test.dart' show createContainer;
import 'subscriptions_screen_test.dart' show seedSubscription;

const _nameField = Key('subscriptionName');
const _priceField = Key('subscriptionPrice');

Future<List<RecurringRule>> _rules(WidgetTester tester, ProviderContainer container) async {
  final db = container.read(databaseProvider);
  return (await tester.runAsync(() => (db.select(db.recurringRules)..where((t) => t.deletedAt.isNull())).get()))!;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('a blank subscription needs a name and a price, then saves with the picked cycle, category, account and auto-post', (tester) async {
    final container = await createContainer();
    final accountId = (await tester.runAsync(() async {
      final accounts = container.read(accountsRepositoryProvider);
      final existing = await accounts.getAll();
      return existing.first.id;
    }))!;
    await pumpAt(tester, container, '/subscriptions');
    appRouter.push('/subscriptions/new');
    await settle(tester);

    expect(find.byKey(_nameField), findsOneWidget);
    await tapAndSettle(tester, find.text('Save'));
    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Enter the price'), findsOneWidget);
    expect(await _rules(tester, container), isEmpty);

    await enter(tester, find.byKey(_nameField), '  Music  ');
    await enter(tester, find.byKey(_priceField), '199');
    expect(find.text('Enter a name'), findsNothing);

    await tapAndSettle(tester, find.text('Every month'));
    await tapAndSettle(tester, find.text('Every 3 months').last);

    await tapAndSettle(tester, find.text('Category'));
    await tapAndSettle(tester, find.text('Transport'));
    expect(find.text('Transport'), findsOneWidget);

    await tapAndSettle(tester, find.text('Add to expenses on each renewal'));
    expect(find.byType(ChoiceChip), findsWidgets);
    await tapAndSettle(tester, find.byType(ChoiceChip).last);
    await tapAndSettle(tester, find.text('Save'));

    final rule = (await _rules(tester, container)).single;
    final transport = (await tester.runAsync(() => container.read(categoriesRepositoryProvider).findBySeedKey('transport')))!;
    expect((rule.name, rule.payee, rule.amountMinor, rule.isSubscription), ('Music', 'Music', 19900, true));
    expect((rule.frequency, rule.interval), ('monthly', 3));
    expect(rule.categoryId, transport.id);
    expect(rule.autoPost, isFalse);
    expect(rule.accountId, isNotNull);
    expect(accountId, isNotEmpty);
    expect(rule.startDate.hour, 9, reason: 'renewals are recorded at the default hour');
    expect(find.byKey(_nameField), findsNothing, reason: 'saving closes the form');
    expect(appRouter.state.uri.path, '/subscriptions');
  });

  testWidgets('a template prefills the name and cycle, and an unreadable price is flagged', (tester) async {
    final container = await createContainer();
    await pumpAt(tester, container, '/subscriptions/new?template=jiohotstar');

    expect(tester.widget<TextField>(find.byKey(_nameField)).controller!.text, 'JioHotstar');
    expect(find.text('Every 3 months'), findsOneWidget);
    await enter(tester, find.byKey(_priceField), '0');
    await tapAndSettle(tester, find.text('Save'));
    expect(find.text('Enter the price'), findsOneWidget);
    expect(await _rules(tester, container), isEmpty);

    await tapAndSettle(tester, find.text('Category'));
    await tester.tapAt(const Offset(200, 20));
    await settle(tester);
    expect(find.text('OTT & Streaming'), findsOneWidget, reason: 'a dismissed category picker keeps the template category');
  });

  testWidgets('a past renewal date picked in the form shows when it started', (tester) async {
    final container = await createContainer();
    await pumpAt(tester, container, '/subscriptions/new');
    await enter(tester, find.byKey(_nameField), 'Paper');
    await enter(tester, find.byKey(_priceField), '300');

    await tapAndSettle(tester, find.text('Next renewal'));
    await tapAndSettle(tester, find.text('Cancel'));
    expect(find.textContaining('Started'), findsNothing, reason: 'a cancelled picker changes nothing');

    await tapAndSettle(tester, find.text('Next renewal'));
    await tapAndSettle(tester, find.byTooltip('Previous month'));
    await tester.tap(find.text('1').first);
    await tester.pump();
    await tapAndSettle(tester, find.text('OK'));
    expect(find.textContaining('Started'), findsOneWidget);

    await tapAndSettle(tester, find.text('Save'));
    final rule = (await _rules(tester, container)).single;
    expect(rule.nextDue!.isAfter(startOfDay(DateTime.now()).subtract(const Duration(days: 1))), isTrue, reason: 'a past start rolls forward to the next renewal');
  });

  testWidgets('editing loads the subscription and keeps its schedule when the date is untouched', (tester) async {
    final container = await createContainer();
    final id = (await tester.runAsync(() => seedSubscription(container, 'Netflix', 64900, categorySeedKey: 'ott', cycle: const SubscriptionCycle(RecurrenceFrequency.weekly, 2))))!;
    final before = (await _rules(tester, container)).single;
    await pumpAt(tester, container, '/subscriptions/$id/edit');

    expect(find.text('Edit subscription'), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(_nameField)).controller!.text, 'Netflix');
    expect(tester.widget<TextField>(find.byKey(_priceField)).controller!.text, '649');
    expect(find.text('Every 2 weeks'), findsOneWidget, reason: 'a cycle outside the presets is still offered');
    expect(find.text('OTT & Streaming'), findsOneWidget);

    await enter(tester, find.byKey(_nameField), 'Netflix Premium');
    await tapAndSettle(tester, find.text('Save'));
    final after = (await _rules(tester, container)).single;
    expect((after.id, after.name, after.payee), (id, 'Netflix Premium', 'Netflix Premium'));
    expect((after.frequency, after.interval), ('weekly', 2));
    expect(after.weekday, before.weekday);
    expect(after.startDate, before.startDate);
  });

  testWidgets('editing a rule without a category or due date falls back to today', (tester) async {
    final container = await createContainer();
    final id = (await tester.runAsync(() async {
      final id = await seedSubscription(container, 'Gym', 100000);
      final db = container.read(databaseProvider);
      await (db.update(db.recurringRules)..where((t) => t.id.equals(id))).write(const RecurringRulesCompanion(nextDue: Value(null), categoryId: Value(null)));
      return id;
    }))!;
    await pumpAt(tester, container, '/subscriptions/$id/edit');

    expect(find.text('Not set'), findsOneWidget);
    await tapAndSettle(tester, find.text('Save'));
    final rule = (await _rules(tester, container)).single;
    expect(rule.categoryId, isNull);
    expect(rule.nextDue, isNotNull);
  });

  testWidgets('editing a subscription that no longer exists shows an empty form', (tester) async {
    final container = await createContainer();
    await pumpAt(tester, container, '/subscriptions/missing/edit');
    expect(find.text('Edit subscription'), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(_nameField)).controller!.text, isEmpty);
  });
}

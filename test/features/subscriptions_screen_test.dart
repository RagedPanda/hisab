import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/recurring_repository.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/subscriptions/subscription_costs.dart';
import 'package:hisab/domain/subscriptions/subscription_templates.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:hisab/features/subscriptions/subscription_labels.dart';
import 'package:hisab/features/subscriptions/subscription_rules.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';
import 'package:hisab/l10n/generated/app_localizations_en.dart';

import '../support/app_harness.dart' show settle;
import '../support/screen_harness.dart';
import '../support/app_harness.dart' show createContainer;

/// Saves a subscription named [name] costing [amountMinor] per [cycle] that
/// next renews [daysAhead] days from today.
Future<String> seedSubscription(ProviderContainer container, String name, int amountMinor,
    {SubscriptionCycle cycle = const SubscriptionCycle(RecurrenceFrequency.monthly, 1), int daysAhead = 10, String? categorySeedKey}) async {
  final category = categorySeedKey == null ? null : await container.read(categoriesRepositoryProvider).findBySeedKey(categorySeedKey);
  final start = startOfDay(DateTime.now()).add(Duration(days: daysAhead, hours: 9));
  return container.read(recurringRepositoryProvider).saveRule(
        newSubscriptionRule(SubscriptionDraft(name: name, amountMinor: amountMinor, cycle: cycle, startDate: start, categoryId: category?.id)),
      );
}

Future<RecurringRule> _rule(WidgetTester tester, ProviderContainer container, String id) async => (await tester.runAsync(() => container.read(recurringRepositoryProvider).getRule(id)))!;

/// Opens the actions sheet of the subscription titled [name] and picks [action].
Future<void> _act(WidgetTester tester, String name, String action) async {
  await tapAndSettle(tester, find.text(name).first);
  await tapAndSettle(tester, find.text(action).last);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('with no subscriptions the screen shows the empty state', (tester) async {
    final container = await createContainer();
    await pumpAt(tester, container, '/subscriptions');
    expect(find.text('No subscriptions yet'), findsOneWidget);
  });

  testWidgets('subscriptions are totalled and sorted, and a template or a blank form is opened from add', (tester) async {
    final container = await createContainer();
    await tester.runAsync(() async {
      await seedSubscription(container, 'Netflix', 64900, categorySeedKey: 'ott');
      await seedSubscription(container, 'Prime', 149900, cycle: const SubscriptionCycle(RecurrenceFrequency.yearly, 1), daysAhead: 1);
      await seedSubscription(container, 'Recharge', 29900, cycle: const SubscriptionCycle(RecurrenceFrequency.daily, 28), daysAhead: 3);
      await seedSubscription(container, 'Gym', 100000, cycle: const SubscriptionCycle(RecurrenceFrequency.weekly, 2), daysAhead: 30);
    });
    await pumpAt(tester, container, '/subscriptions');

    expect(find.text('4 active subscriptions'), findsOneWidget);
    expect(find.text('Per month'), findsOneWidget);
    expect(find.text('Renews tomorrow'), findsOneWidget);
    expect(find.text('Renews in 3 days'), findsOneWidget);
    expect(find.textContaining('Every 28 days'), findsOneWidget);
    expect(find.textContaining('Every 2 weeks'), findsOneWidget);
    expect(find.textContaining('Every year'), findsOneWidget);

    double topOf(String name) => tester.getTopLeft(find.text(name)).dy;
    expect(topOf('Gym'), lessThan(topOf('Netflix')), reason: 'cost high to low by default');

    await tapAndSettle(tester, find.byTooltip('Sort'));
    await tapAndSettle(tester, find.text('Name').last);
    expect(topOf('Gym'), lessThan(topOf('Netflix')));
    expect(topOf('Netflix'), lessThan(topOf('Prime')));
    await tapAndSettle(tester, find.byTooltip('Sort'));
    await tapAndSettle(tester, find.text('Cost: low to high'));
    expect(topOf('Netflix'), lessThan(topOf('Gym')));
    await tapAndSettle(tester, find.byTooltip('Sort'));
    await tapAndSettle(tester, find.text('Next renewal').last);
    expect(topOf('Prime'), lessThan(topOf('Recharge')));

    await tapAndSettle(tester, find.byType(FloatingActionButton));
    expect(find.text('Pick a service'), findsOneWidget);
    await tapAndSettle(tester, find.text('Netflix').last);
    expect(appRouter.state.uri.toString(), '/subscriptions/new?template=netflix');
    await settle(tester);
    appRouter.pop();
    await settle(tester);

    await tapAndSettle(tester, find.byType(FloatingActionButton));
    await tester.scrollUntilVisible(find.text('Something else'), 200, scrollable: find.byType(Scrollable).last);
    await tapAndSettle(tester, find.text('Something else'));
    expect(appRouter.state.uri.toString(), '/subscriptions/new');
    await settle(tester);
    appRouter.pop();
    await settle(tester);

    await tapAndSettle(tester, find.byType(FloatingActionButton));
    await tester.tapAt(const Offset(200, 20));
    await settle(tester);
    expect(appRouter.state.uri.toString(), '/subscriptions', reason: 'a dismissed template sheet opens nothing');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a subscription is paused, resumed, cancelled, deleted and restored from its sheet', (tester) async {
    final container = await createContainer();
    final id = (await tester.runAsync(() => seedSubscription(container, 'Netflix', 64900)))!;
    await pumpAt(tester, container, '/subscriptions');

    await _act(tester, 'Netflix', 'Pause');
    expect((await _rule(tester, container, id)).status, RecurringStatus.paused);
    expect(find.text('Paused'), findsOneWidget);

    await _act(tester, 'Netflix', 'Resume');
    expect((await _rule(tester, container, id)).status, RecurringStatus.active);

    await _act(tester, 'Netflix', 'Mark as cancelled');
    expect(find.text('Mark Netflix as cancelled?'), findsOneWidget);
    await tapAndSettle(tester, find.text('Cancel'));
    expect((await _rule(tester, container, id)).status, RecurringStatus.active, reason: 'declining keeps it active');
    await _act(tester, 'Netflix', 'Mark as cancelled');
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Mark as cancelled'));
    expect((await _rule(tester, container, id)).status, RecurringStatus.ended);
    expect(find.text('Cancelled'), findsOneWidget);

    await tapAndSettle(tester, find.text('Netflix').first);
    expect(find.text('Pause'), findsNothing);
    expect(find.text('Mark as cancelled'), findsNothing, reason: 'a cancelled subscription cannot be cancelled again');
    await tapAndSettle(tester, find.text('Delete'));
    expect((await _rule(tester, container, id)).deletedAt, isNotNull);
    expect(find.text('Subscription deleted'), findsOneWidget);
    await tapAndSettle(tester, find.text('Undo'));
    expect((await _rule(tester, container, id)).deletedAt, isNull);

    await tapAndSettle(tester, find.text('Netflix').first);
    await tester.tapAt(const Offset(200, 20));
    await settle(tester);
    expect((await _rule(tester, container, id)).deletedAt, isNull, reason: 'a dismissed sheet does nothing');
  });

  testWidgets('edit in the sheet opens the subscription form', (tester) async {
    final container = await createContainer();
    final id = (await tester.runAsync(() => seedSubscription(container, 'Netflix', 64900)))!;
    await pumpAt(tester, container, '/subscriptions');
    await _act(tester, 'Netflix', 'Edit');
    expect(appRouter.state.uri.toString(), '/subscriptions/$id/edit');
    expect(find.text('Edit subscription'), findsOneWidget);
    await settle(tester);
  });

  group('labels', () {
    final AppLocalizations l10n = AppLocalizationsEn();

    test('every template has a name and an unknown one falls back to its key', () {
      for (final template in subscriptionTemplates) {
        expect(subscriptionTemplateName(l10n, template), isNot(template.key), reason: template.key);
      }
      expect(subscriptionTemplateName(l10n, const SubscriptionTemplate(key: 'other', frequency: RecurrenceFrequency.monthly, categoryKey: 'ott')), 'other');
    });

    test('cycles, renewals and sorts read naturally', () {
      expect(subscriptionCycleLabel(l10n, RecurrenceFrequency.monthly, 0), 'Every month', reason: 'a zero interval reads as one');
      expect(subscriptionCycleLabel(l10n, RecurrenceFrequency.daily, 1), 'Every day');
      final today = DateTime(2026, 10, 20);
      expect(subscriptionRenewalLabel(l10n, DateTime(2026, 10, 15), today), startsWith('Was due'));
      expect(subscriptionRenewalLabel(l10n, today, today), 'Renews today');
      expect(subscriptionRenewalLabel(l10n, DateTime(2026, 10, 21), today), 'Renews tomorrow');
      expect(subscriptionRenewalLabel(l10n, DateTime(2026, 11, 20), today), startsWith('Renews '));
      expect([for (final sort in SubscriptionSort.values) subscriptionSortLabel(l10n, sort)], hasLength(SubscriptionSort.values.length));
    });
  });
}

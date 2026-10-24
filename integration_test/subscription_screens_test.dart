/// Screenshot tour of the subscription screens in every locale and theme,
/// for the visual checks in the dev reports. Seeds rules through the
/// repository and only navigates, so it runs unchanged in English and Hindi.
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/subscription_screens_test.dart -d emulator-5556
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/repositories/categories_repository.dart';
import 'package:hisab/data/repositories/recurring_repository.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:integration_test/integration_test.dart';

import 'harness.dart';

const _configs = [('en', ThemeMode.light), ('en', ThemeMode.dark), ('hi', ThemeMode.light), ('hi', ThemeMode.dark)];

Future<void> _seed(AppHandle app) async {
  final recurring = app.read(recurringRepositoryProvider);
  final categories = CategoriesRepository(app.db);
  final today = startOfDay(DateTime.now());
  Future<void> add(String name, int amountMinor, RecurrenceFrequency frequency, String categoryKey, {int interval = 1, int inDays = 3, String? status}) async {
    final category = await categories.findBySeedKey(categoryKey);
    final id = await recurring.saveRule(
      RecurringRepository.newRule(
        name: name,
        kind: 'expense',
        amountMinor: amountMinor,
        categoryId: category?.id,
        frequency: frequency,
        interval: interval,
        startDate: today.add(Duration(days: inDays, hours: 9)),
        autoPost: false,
        isSubscription: true,
      ),
    );
    if (status == 'paused') await recurring.setPaused(id, true, now: today);
    if (status == 'ended') await recurring.setStatus(id, RecurringStatus.ended);
  }

  await add('Netflix', 64900, RecurrenceFrequency.monthly, 'ott', inDays: 0);
  await add('Amazon Prime', 149900, RecurrenceFrequency.yearly, 'ott', inDays: 40);
  await add('JioHotstar', 29900, RecurrenceFrequency.monthly, 'ott', interval: 3, inDays: 12);
  await add('Jio prepaid', 34900, RecurrenceFrequency.daily, 'mobile_recharge', interval: 28, inDays: 1);
  await add('Airtel Xstream Fiber', 79900, RecurrenceFrequency.monthly, 'internet', inDays: 6);
  await add('Cult gym', 150000, RecurrenceFrequency.monthly, 'fitness', status: 'paused');
  await add('Spotify', 13900, RecurrenceFrequency.monthly, 'ott', status: 'ended');
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('subscription screens in every locale and theme', (tester) async {
    final app = await createApp();
    await tester.runAsync(() => _seed(app));
    await pumpApp(tester, app);

    for (final (locale, mode) in _configs) {
      await app.read(settingsProvider.notifier).update((s) => s.copyWith(localeCode: locale, themeMode: mode));
      final tag = '${locale}_${mode.name}';
      appRouter.go('/subscriptions');
      await settle(tester, 10);
      await shoot(tester, 'subscriptions_$tag');
      await scrollTo(tester, find.byType(ListTile).last);
      await shoot(tester, 'subscriptions_bottom_$tag');

      await tapFinder(tester, find.byType(FloatingActionButton), frames: 10);
      await shoot(tester, 'subscription_templates_$tag');
      await tapFinder(tester, find.descendant(of: find.byType(DraggableScrollableSheet), matching: find.byType(ListTile)).at(5), frames: 10);
      FocusManager.instance.primaryFocus?.unfocus();
      await settle(tester, 6);
      await shoot(tester, 'subscription_form_$tag');
      appRouter.go('/settings');
      await settle(tester, 8);
      await scrollTo(tester, find.byIcon(Icons.autorenew));
      await shoot(tester, 'settings_money_$tag');
    }
  });
}

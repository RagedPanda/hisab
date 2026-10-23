import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/salary/salary_providers.dart';
import 'package:hisab/features/salary/salary_reminder.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/fake_notification_gateway.dart';

Future<ProviderContainer> _pumpSalary(WidgetTester tester, {String localeCode = 'en'}) async {
  SharedPreferences.setMockInitialValues({'onboarded': true, if (localeCode != 'en') 'localeCode': localeCode});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    databaseProvider.overrideWithValue(db),
    notificationGatewayProvider.overrideWithValue(FakeNotificationGateway()),
  ]);
  addTearDown(container.dispose);
  await tester.binding.setSurfaceSize(const Size(360, 780));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  appRouter.go('/settings');
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
  await _settle(tester);
  appRouter.push(kSalaryLocation);
  await _settle(tester);
  return container;
}

Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Scrolls the lazy salary form until [key] is built and on screen.
Future<void> _reveal(WidgetTester tester, String key) async {
  final form = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(find.byKey(Key(key)), 200, scrollable: form);
  await _settle(tester, 4);
}

Future<void> _pick(WidgetTester tester, String key, String option) async {
  await _reveal(tester, key);
  await tester.tap(find.byKey(Key(key)));
  await _settle(tester, 6);
  await tester.tap(find.text(option).last);
  await _settle(tester, 6);
}

void main() {
  final english = lookupAppLocalizations(const Locale('en'));

  testWidgets('detection window and tolerance are chosen on the salary screen, saved and backed up', (tester) async {
    final container = await _pumpSalary(tester);
    await tester.enterText(find.byKey(const Key('salaryAmount')), '85000');
    await _reveal(tester, 'salaryTolerance');
    expect(find.text(english.salaryMatchWindowDays(4)), findsOneWidget, reason: 'defaults to 4 days');
    expect(find.text(english.salaryTolerancePercent(15)), findsOneWidget, reason: 'defaults to 15%');

    await _pick(tester, 'salaryMatchWindow', english.salaryMatchWindowDays(6));
    await _pick(tester, 'salaryTolerance', english.salaryToleranceExact);
    await tester.tap(find.byKey(const Key('salarySave')));
    await _settle(tester);
    if (find.text(english.salaryAlignAction).evaluate().isNotEmpty) {
      await tester.tap(find.text(english.salaryAlignAction));
      await _settle(tester);
    }

    final saved = container.read(salarySettingsProvider);
    expect(saved.isSetUp, isTrue);
    expect(saved.matchWindowDays, 6);
    expect(saved.tolerancePercent, 0);
    expect(saved.updatedAt, isNotNull);

    final payload = await container.read(backupServiceProvider).snapshot();
    final block = payload['salarySettings'] as Map<String, dynamic>;
    expect(block['matchWindowDays'], 6);
    expect(block['tolerancePercent'], 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hindi detection fields fit at 360dp', (tester) async {
    await _pumpSalary(tester, localeCode: 'hi');
    final hindi = lookupAppLocalizations(const Locale('hi'));
    await _reveal(tester, 'salaryTolerance');
    expect(find.text(hindi.salaryMatchWindow), findsOneWidget);
    expect(find.text(hindi.salaryTolerance), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

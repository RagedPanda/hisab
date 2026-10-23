import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/core/salary_settings.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/domain/salary/salary_schedule.dart';
import 'package:hisab/features/salary/salary_setup_screen.dart';
import 'package:hisab/features/salary/salary_providers.dart';
import 'package:hisab/features/salary/salary_reminder.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/fake_notification_gateway.dart';

Future<ProviderContainer> _pumpSalary(WidgetTester tester, {String localeCode = 'en', FakeNotificationGateway? gateway, Map<String, Object> prefsValues = const {}}) async {
  SharedPreferences.setMockInitialValues({'onboarded': true, if (localeCode != 'en') 'localeCode': localeCode, ...prefsValues});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    databaseProvider.overrideWithValue(db),
    notificationGatewayProvider.overrideWithValue(gateway ?? FakeNotificationGateway()),
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

/// Enters [amount], closes the keyboard and taps Save.
Future<void> _enterAndSave(WidgetTester tester, String amount) async {
  await tester.enterText(find.byKey(const Key('salaryAmount')), amount);
  FocusManager.instance.primaryFocus?.unfocus();
  await _settle(tester, 4);
  await tester.tap(find.byKey(const Key('salarySave')));
  await _settle(tester, 20);
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

  testWidgets('saving with the reminder on asks for notification permission and stores an untranslated rule name', (tester) async {
    final gateway = FakeNotificationGateway(notificationsAllowed: false);
    final container = await _pumpSalary(tester, localeCode: 'hi', gateway: gateway);
    await _enterAndSave(tester, '85000');

    expect(gateway.permissionRequests, 1);
    final saved = container.read(salarySettingsProvider);
    final rule = await container.read(salaryServiceProvider).recurring.getRule(saved.ruleId);
    expect(rule!.name, kSalaryRuleName, reason: 'translated only for display');
    expect(tester.takeException(), isNull);
  });

  testWidgets('turning the reminder on asks for permission right away', (tester) async {
    final gateway = FakeNotificationGateway(notificationsAllowed: false);
    await _pumpSalary(tester, gateway: gateway, prefsValues: {'salaryReminderEnabled': false});
    await _reveal(tester, 'salaryReminderSwitch');
    await tester.tap(find.byKey(const Key('salaryReminderSwitch')));
    await _settle(tester);
    expect(gateway.permissionRequests, 1);
  });

  testWidgets('a declined month-start suggestion is not offered again for the rule, and Remove resets the form', (tester) async {
    final container = await _pumpSalary(tester, prefsValues: {'salaryDay': 25});
    await _enterAndSave(tester, '85000');
    expect(find.text(english.salaryAlignAction), findsOneWidget);
    await tester.tap(find.text(english.cancel));
    await _settle(tester);

    final saved = container.read(salarySettingsProvider);
    expect(saved.alignDeclinedRuleId, saved.ruleId);
    expect(container.read(settingsProvider).monthStartDay, 1);

    appRouter.push(kSalaryLocation);
    await _settle(tester);
    await tester.tap(find.byKey(const Key('salarySave')));
    await _settle(tester);
    expect(find.text(english.salaryAlignAction), findsNothing);

    appRouter.push(kSalaryLocation);
    await _settle(tester);
    await tester.tap(find.byKey(const Key('salaryRemove')));
    await _settle(tester, 6);
    await tester.tap(find.text(english.salaryRemove).last);
    await _settle(tester);

    final cleared = container.read(salarySettingsProvider);
    expect(cleared.isSetUp, isFalse);
    expect(cleared.salaryDay, const SalarySettings().salaryDay);
    expect(cleared.amountMinor, 0);
    expect(cleared.alignDeclinedRuleId, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a language change refreshes the salary alert text without a resume', (tester) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final gateway = FakeNotificationGateway();
    final container = await _pumpSalary(tester, gateway: gateway, prefsValues: {
      'salaryRuleId': 'salary-rule',
      'salaryAmountMinor': 8500000,
      'salaryDay': yesterday.day.clamp(1, 28),
      'salaryShift': 'sameDay',
    });
    expect(gateway.scheduled[kSalaryNotificationId]?.title, english.salaryNotSeenTitle);

    await container.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'hi'));
    await _settle(tester);
    expect(gateway.scheduled[kSalaryNotificationId]?.title, lookupAppLocalizations(const Locale('hi')).salaryNotSeenTitle);
  });

  group('status card lines', () {
    setUpAll(() => initializeDateFormatting('en'));
    IncomeCandidate income(DateTime at, int amount) => IncomeCandidate(occurredAt: at, amountMinor: amount);
    SalaryStatus status({IncomeCandidate? received, IncomeCandidate? last, SalaryReminderState state = SalaryReminderState.waiting}) => SalaryStatus(
          expected: DateTime(2026, 11, 30),
          next: DateTime(2026, 12, 30),
          received: received,
          lastReceived: received ?? last,
          reminderState: state,
          reminderAt: DateTime(2026, 12, 2, 10),
        );

    test('received shows the date and amount, then the next expected date', () {
      final lines = salaryStatusLines(status(received: income(DateTime(2026, 11, 27), 8500000), state: SalaryReminderState.seen), english, locale: 'en', symbol: '₹');
      expect(lines.title, english.salaryReceivedAmount('27 Nov 2026', '₹85,000'));
      expect(lines.subtitle, english.salaryNextExpected('30 Dec 2026'));
    });

    test('a missed cycle reads late and shows the last salary received', () {
      final lines = salaryStatusLines(status(last: income(DateTime(2026, 10, 30), 8500000), state: SalaryReminderState.due), english, locale: 'en', symbol: '₹');
      expect(lines.title, english.salaryLateSince('30 Nov 2026'));
      expect(lines.subtitle, '${english.salaryLastReceived('30 Oct 2026', '₹85,000')}\n${english.salaryNextExpected('30 Dec 2026')}');
    });

    test('waiting reads expected, not late', () {
      final lines = salaryStatusLines(status(), english, locale: 'en', symbol: '₹');
      expect(lines.title, english.salaryExpectedOn('30 Nov 2026'));
      expect(lines.subtitle, english.salaryNextExpected('30 Dec 2026'));
    });
  });
}

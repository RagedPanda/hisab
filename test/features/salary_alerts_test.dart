import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/core/salary_settings.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/domain/salary/salary_schedule.dart';
import 'package:hisab/features/salary/salary_providers.dart';
import 'package:hisab/features/salary/salary_reminder.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/fake_notification_gateway.dart';

void main() {
  final english = lookupAppLocalizations(const Locale('en'));
  final plan = ScheduleSalaryNotification(at: DateTime(2026, 10, 3, 10), expected: DateTime(2026, 10, 1));

  test('schedules one plain alert at the planned time, exact when allowed', () async {
    final gateway = FakeNotificationGateway(exactAlarmsAllowed: false);
    await GatewaySalaryAlerts(gateway, english, locale: 'en').apply(plan);

    final request = gateway.scheduled[kSalaryNotificationId]!;
    expect(gateway.scheduled, hasLength(1));
    expect(request.fireAt, DateTime(2026, 10, 3, 10));
    expect(request.title, 'Salary not seen yet');
    expect(request.body, contains('1 Oct 2026'));
    expect(request.payload, kSalaryAlertPayload);
    expect(request.withActions, isFalse);
    expect(gateway.exactById[kSalaryNotificationId], isFalse);
  });

  test('rescheduling replaces the alert and cancel dismisses it', () async {
    final gateway = FakeNotificationGateway();
    final alerts = GatewaySalaryAlerts(gateway, english, locale: 'en');
    await alerts.apply(plan);
    await alerts.apply(ScheduleSalaryNotification(at: DateTime(2026, 11, 3, 10), expected: DateTime(2026, 11, 1)));
    expect(gateway.scheduled, hasLength(1));

    await alerts.apply(const CancelSalaryNotification());
    expect(gateway.scheduled, isEmpty);
    expect(gateway.cancelled, [kSalaryNotificationId]);
  });

  test('speaks Hindi when the app does', () async {
    await initializeDateFormatting('hi');
    final request = salaryAlertRequest(plan, lookupAppLocalizations(const Locale('hi')), locale: 'hi');
    expect(request.title, isNot('Salary not seen yet'));
    expect(request.title, isNotEmpty);
  });

  group('sync of an overdue salary reminder', () {
    // The salary on the 30th was due Friday 30 Oct; the reminder moment
    // (2 days later, 10:00) has passed.
    final now = DateTime(2026, 11, 3, 12);
    late FakeNotificationGateway gateway;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'onboarded': true});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      gateway = FakeNotificationGateway()..clock = () => now;
      container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
        notificationGatewayProvider.overrideWithValue(gateway),
      ]);
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      final saved = await container.read(salaryServiceProvider).saveSalaryRule(settings: const SalarySettings(amountMinor: 8500000, salaryDay: 30), today: DateTime(2026, 10, 22));
      await container.read(salarySettingsProvider.notifier).save(saved);
    });

    test('is posted a moment ahead instead of being rejected for being in the past', () async {
      final plan = await syncSalaryReminder(container.read, now: now);
      expect(plan, isA<ScheduleSalaryNotification>());
      final alert = gateway.scheduled[kSalaryNotificationId];
      expect(alert, isNotNull, reason: 'zonedSchedule rejects now; the alert must still be posted');
      expect(alert!.fireAt.isAfter(now), isTrue);
    });

    test('is posted once per cycle, and again in the new language', () async {
      await syncSalaryReminder(container.read, now: now);
      gateway.scheduled.clear(); // shown, then swiped away
      await syncSalaryReminder(container.read, now: now.add(const Duration(hours: 1)));
      expect(gateway.scheduled, isEmpty, reason: 'not re-shown on every resume');

      await container.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'hi'));
      await syncSalaryReminder(container.read, now: now.add(const Duration(hours: 2)));
      expect(gateway.scheduled[kSalaryNotificationId]?.title, lookupAppLocalizations(const Locale('hi')).salaryNotSeenTitle);
    });

    test('a failed post is retried on the next sync, and a refused exact alarm falls back to inexact', () async {
      gateway.clock = () => now.add(const Duration(days: 1));
      await syncSalaryReminder(container.read, now: now);
      expect(gateway.scheduled, isEmpty);

      gateway.clock = () => now;
      gateway.failExact = true;
      await syncSalaryReminder(container.read, now: now);
      expect(gateway.scheduled[kSalaryNotificationId], isNotNull);
      expect(gateway.exactById[kSalaryNotificationId], isFalse);
    });
  });
}

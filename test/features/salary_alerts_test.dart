import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hisab/domain/salary/salary_schedule.dart';
import 'package:hisab/features/salary/salary_reminder.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';

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
    final alerts = GatewaySalaryAlerts(gateway, english);
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
}

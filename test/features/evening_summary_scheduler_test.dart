import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/money.dart';
import 'package:hisab/core/notifications/reminder_alert_text.dart';
import 'package:hisab/domain/notifications/evening_summary.dart';
import 'package:hisab/features/notifications/evening_summary_service.dart';
import 'package:hisab/features/notifications/notification_texts.dart';

import '../core/fake_notification_gateway.dart';

void main() {
  final english = notificationLocalizations('en');
  final now = DateTime(2026, 10, 29, 22, 15);
  late FakeNotificationGateway gateway;
  late List<DateTime> loadedDays;

  EveningSummaryScheduler scheduler() => EveningSummaryScheduler(
        gateway,
        loadSummary: (day) async {
          loadedDays.add(day);
          return EveningSummary(spentMinor: day.day * 100, reviewCount: 0, dueCount: 0, dueMinor: 0);
        },
        buildAlert: (summary, {required slot, required fireAt}) => eveningSummaryAlert(summary, english, slot: slot, fireAt: fireAt, moneyFormat: MoneyFormat.inr),
        clock: () => now,
      );

  setUp(() {
    gateway = FakeNotificationGateway()..clock = () => now;
    loadedDays = [];
  });

  test('switched on, posts the next evenings with each evening\'s own figures', () async {
    expect(await scheduler().refresh(enabled: true, minuteOfDay: 21 * 60), kEveningSummaryNightsAhead);

    final posted = gateway.alertsFor(kEveningSummaryPayload);
    expect(posted.map((alert) => alert.fireAt), [DateTime(2026, 10, 30, 21), DateTime(2026, 10, 31, 21), DateTime(2026, 11, 1, 21)]);
    expect(loadedDays, [DateTime(2026, 10, 30), DateTime(2026, 10, 31), DateTime(2026, 11, 1)]);
    expect(posted.first.body, 'Spent ₹30 today');
  });

  test('refreshing replaces what was posted, and switching off cancels it', () async {
    await scheduler().refresh(enabled: true, minuteOfDay: 21 * 60);
    await scheduler().refresh(enabled: true, minuteOfDay: 23 * 60);
    expect(gateway.alertsFor(kEveningSummaryPayload).map((alert) => alert.fireAt.hour), [23, 23, 23], reason: 'tonight at 23:00 is still ahead');
    expect(gateway.alertsFor(kEveningSummaryPayload).first.fireAt, DateTime(2026, 10, 29, 23));

    expect(await scheduler().refresh(enabled: false, minuteOfDay: 23 * 60), 0);
    expect(gateway.alertsFor(kEveningSummaryPayload), isEmpty);
  });

  test('without exact-alarm access the summaries are still posted, inexact', () async {
    gateway.exactAlarmsAllowed = false;
    await scheduler().refresh(enabled: true, minuteOfDay: 21 * 60);
    expect(gateway.alertsFor(kEveningSummaryPayload), hasLength(kEveningSummaryNightsAhead));
    expect(gateway.exactById.values.toSet(), {false});
  });
}

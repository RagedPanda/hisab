import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/notifications/notification_gateway.dart';
import 'package:hisab/core/notifications/reminder_payload.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/domain/reminders/reminder_draft.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';
import 'package:hisab/features/reminders/reminder_startup.dart';
import 'package:hisab/features/salary/salary_reminder.dart';
import 'package:hisab/features/shell/router.dart';

import '../core/fake_notification_gateway.dart';
import '../support/app_harness.dart' show pumpApp, settle;

/// A plugin that is not available at all on this device.
class BrokenNotificationGateway extends FakeNotificationGateway {
  @override
  Future<void> initialize({required void Function(NotificationTap tap) onTap}) async => throw StateError('plugin missing');

  @override
  Future<NotificationPermissionState> permissionState() async => throw StateError('plugin missing');
}

String _location() => appRouter.state.uri.toString();

Future<String> _addBill(ProviderContainer container) {
  final inThreeDays = DateTime.now().add(const Duration(days: 3));
  return container.read(reminderSchedulerProvider).save(ReminderDraft(
        kind: ReminderKind.bill,
        title: 'Electricity',
        amountMinor: 210000,
        dueAt: DateTime(inThreeDays.year, inThreeDays.month, inThreeDays.day),
        repeat: ReminderRepeat.monthly,
        remindDaysBefore: const [1, 0],
      ));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('startup follows the launching tap, listens for taps and re-posts alerts', (tester) async {
    final gateway = FakeNotificationGateway();
    final container = await pumpApp(tester, overrides: [notificationGatewayProvider.overrideWithValue(gateway)]);
    final reminderId = await _addBill(container);
    gateway.scheduled.clear();
    gateway.launch = NotificationTap(payload: reminderPayload(reminderId), actionId: kMarkPaidActionId);

    await tester.runAsync(() => startReminderNotifications(container));
    await settle(tester);

    expect(_location(), '/entry?reminder=$reminderId', reason: 'Mark paid opens the prefilled editor');
    expect(gateway.alertsFor(reminderPayload(reminderId)), isNotEmpty, reason: 'pending reminders are posted again');
    expect(gateway.onTap, isNotNull);

    gateway.onTap!(const NotificationTap(payload: kSalaryAlertPayload));
    await settle(tester);
    expect(_location(), kSalaryLocation, reason: 'later taps arrive through the listener');
  });

  testWidgets('taps route by payload: junk is ignored, salary opens salary, Snooze stays put', (tester) async {
    final container = await pumpApp(tester, overrides: [notificationGatewayProvider.overrideWithValue(FakeNotificationGateway())]);
    final reminderId = await _addBill(container);

    await handleReminderTap(container, const NotificationTap(payload: 'not a reminder'));
    await settle(tester);
    expect(_location(), '/home');

    await handleReminderTap(container, const NotificationTap(payload: kSalaryAlertPayload));
    await settle(tester);
    expect(_location(), kSalaryLocation);

    await tester.runAsync(() => handleReminderTap(container, NotificationTap(payload: reminderPayload(reminderId), actionId: kSnoozeActionId)));
    await settle(tester);
    expect(_location(), kSalaryLocation, reason: 'Snooze opens nothing');
    expect((await container.read(remindersRepositoryProvider).getById(reminderId))?.snoozedUntil, isNotNull);
  });

  testWidgets('the same tap delivered twice is handled once', (tester) async {
    final container = await pumpApp(tester, overrides: [notificationGatewayProvider.overrideWithValue(FakeNotificationGateway())]);
    final tap = NotificationTap(payload: reminderPayload('twice'));

    await handleReminderTap(container, tap);
    await settle(tester);
    appRouter.go('/home');
    await settle(tester);
    await handleReminderTap(container, tap);
    await settle(tester);

    expect(_location(), '/home');
  });

  testWidgets('a missing notification plugin never breaks startup or resume', (tester) async {
    final container = await pumpApp(tester, overrides: [notificationGatewayProvider.overrideWithValue(BrokenNotificationGateway())]);
    const known = NotificationPermissionState(notificationsAllowed: true, exactAlarmsAllowed: false);

    await tester.runAsync(() => startReminderNotifications(container));
    expect(await tester.runAsync(() => recheckAlarmAccess(container, known)), same(known));
  });
}

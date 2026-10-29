import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/notification_prefs.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/domain/notifications/notification_kinds.dart';
import 'package:hisab/features/notifications/notification_settings_screen.dart';
import 'package:hisab/features/notifications/notification_texts.dart';
import 'package:hisab/features/shortcuts/launcher_sync.dart';
import 'package:hisab/features/shortcuts/shortcut_settings.dart';

import '../core/fake_notification_gateway.dart';
import '../support/app_harness.dart';
import '../support/fake_launcher_channel.dart';

void main() {
  Finder switchOf(NotificationKind kind) => find.descendant(of: find.byKey(Key('notificationKind-${kind.name}')), matching: find.byType(Switch));
  bool isOn(WidgetTester tester, NotificationKind kind) => tester.widget<Switch>(switchOf(kind)).value;

  Future<void> tapAndWait(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await pumpWithDatabase(tester, 20);
  }

  testWidgets('on a new install every kind is off, and turning on the evening summary offers its time and remembers it', (tester) async {
    final gateway = FakeNotificationGateway();
    final container = await createContainer(overrides: [notificationGatewayProvider.overrideWithValue(gateway)]);
    await pumpScreen(tester, container, const NotificationSettingsScreen(), size: const Size(360, 1600));

    for (final kind in NotificationKind.values) {
      expect(isOn(tester, kind), isFalse, reason: kind.name);
    }
    expect(find.byKey(const Key('eveningSummaryTime')), findsNothing);
    expect(find.text('Set up salary day'), findsOneWidget, reason: 'salary has nothing to watch for yet');

    await tapAndWait(tester, switchOf(NotificationKind.eveningSummary));

    expect(isOn(tester, NotificationKind.eveningSummary), isTrue);
    expect(find.byKey(const Key('eveningSummaryTime')), findsOneWidget);
    expect(find.text('9:00 PM'), findsOneWidget);
    expect(container.read(sharedPreferencesProvider).getBool(notificationChoiceKey(NotificationKind.eveningSummary)), isTrue);
    expect(gateway.alertsFor(kEveningSummaryPayload), isNotEmpty);
  });

  testWidgets('an upgrade with SMS capture on keeps its bank SMS alerts on', (tester) async {
    final container = await createContainer(preferences: {'smsEnabled': true}, overrides: [notificationGatewayProvider.overrideWithValue(FakeNotificationGateway())]);
    await pumpScreen(tester, container, const NotificationSettingsScreen(), size: const Size(360, 1600));

    expect(isOn(tester, NotificationKind.bankSms), isTrue);
    expect(isOn(tester, NotificationKind.eveningSummary), isFalse);
  });

  testWidgets('Show sample posts a marked sample at once, even with the kind off', (tester) async {
    final gateway = FakeNotificationGateway();
    final container = await createContainer(overrides: [notificationGatewayProvider.overrideWithValue(gateway)]);
    await pumpScreen(tester, container, const NotificationSettingsScreen(), size: const Size(360, 1600));

    await tapAndWait(tester, find.byKey(const Key('notificationSample-reminders')));
    await tapAndWait(tester, find.byKey(const Key('notificationSample-eveningSummary')));

    expect(gateway.shown.map((alert) => alert.title), ['Sample · Electricity bill', 'Sample · Your day in Hisab']);
    expect(gateway.shown.last.body, 'Nothing spent today');
    expect(gateway.scheduled, isEmpty, reason: 'a sample schedules nothing');
    expect(find.textContaining('Sample sent'), findsOneWidget);
  });

  testWidgets('the Add expense shortcut switch asks for access, stays off without it, and shares its setting with Shortcuts & widget', (tester) async {
    final gateway = FakeNotificationGateway(notificationsAllowed: false, grantOnRequest: false);
    final launcher = FakeLauncherChannel();
    final container = await createContainer(overrides: [notificationGatewayProvider.overrideWithValue(gateway), launcherChannelProvider.overrideWithValue(launcher)]);
    await pumpScreen(tester, container, const NotificationSettingsScreen(), size: const Size(360, 2000));
    final shortcut = switchOf(NotificationKind.addExpenseShortcut);

    await tapAndWait(tester, shortcut);
    expect(gateway.permissionRequests, 1);
    expect(isOn(tester, NotificationKind.addExpenseShortcut), isFalse, reason: 'no notification access, so nothing to show');
    expect(container.read(shortcutSettingsProvider).addExpenseNotification, isFalse);

    gateway.grantOnRequest = true;
    await tapAndWait(tester, shortcut);
    expect(gateway.permissionRequests, 2);
    expect(isOn(tester, NotificationKind.addExpenseShortcut), isTrue);
    expect(container.read(sharedPreferencesProvider).getBool(kAddExpenseNotificationKey), isTrue);
    expect(container.read(sharedPreferencesProvider).containsKey(notificationChoiceKey(NotificationKind.addExpenseShortcut)), isFalse, reason: 'one setting, kept by Shortcuts & widget');

    await container.read(shortcutSettingsProvider.notifier).setAddExpenseNotification(false);
    await pumpWithDatabase(tester, 5);
    expect(isOn(tester, NotificationKind.addExpenseShortcut), isFalse, reason: 'turned off on Shortcuts & widget');
  });

  testWidgets('the Settings row counts what is on and opens the screen', (tester) async {
    final container = await createContainer(preferences: {notificationChoiceKey(NotificationKind.eveningSummary): true}, overrides: [notificationGatewayProvider.overrideWithValue(FakeNotificationGateway())]);
    await pumpScreen(tester, container, const Scaffold(body: NotificationsSettingsTile()));

    expect(find.text('1 of 5 on'), findsOneWidget);
    await tapAndWait(tester, find.byKey(const Key('settingsNotifications')));
    expect(find.text(openedLocation(kNotificationSettingsLocation)), findsOneWidget);
  });
}

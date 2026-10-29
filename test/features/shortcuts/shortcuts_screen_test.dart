import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/domain/launcher/quick_entry_shortcuts.dart';
import 'package:hisab/features/shortcuts/launcher_sync.dart';
import 'package:hisab/features/shortcuts/shortcut_settings.dart';
import 'package:hisab/features/shortcuts/shortcuts_screen.dart';

import '../../core/fake_notification_gateway.dart';
import '../../support/app_harness.dart';
import '../../support/fake_launcher_channel.dart';
import '../../support/screen_harness.dart';
import '../../support/seed.dart';

void main() {
  testWidgets('keeps the launcher shortcuts, widget and notification in step', (tester) async {
    final launcher = FakeLauncherChannel();
    final container = await createContainer(overrides: [launcherChannelProvider.overrideWithValue(launcher)]);
    await seedEntry(container, id: 'e1', payee: 'Shop', amountMinor: 45000);
    await pumpAt(tester, container, '/home');

    // The starter quick entries, up to the launcher limit.
    expect(launcher.shortcuts.last, hasLength(kMaxQuickEntryShortcuts));
    expect(launcher.widgets.last['amount'], '₹450');
    expect(launcher.notifications.last['enabled'], isFalse);

    await container.read(quickEntriesRepositoryProvider).rename(launcher.shortcuts.last.first.id.substring(kQuickEntryShortcutPrefix.length), 'Chai');
    await container.read(shortcutSettingsProvider.notifier).setWidgetOpacity(60);
    await settle(tester);
    expect(launcher.shortcuts.last.first.shortLabel, 'Chai');
    expect(launcher.widgets.last['opacity'], 60);
  });

  testWidgets('explains the manual way when the system cannot add the tile or widget', (tester) async {
    final container = await createContainer(overrides: [launcherChannelProvider.overrideWithValue(FakeLauncherChannel())]);
    await pumpAt(tester, container, kShortcutsLocation);

    await tapAndSettle(tester, find.byKey(const Key('shortcuts.tile')));
    expect(find.textContaining('tap the pencil to edit'), findsOneWidget);
    await tapAndSettle(tester, find.text('OK'));

    await tapAndSettle(tester, find.byKey(const Key('shortcuts.widget')));
    expect(find.textContaining('tap Widgets and pick Hisab'), findsOneWidget);
  });

  testWidgets('the notification switch asks for access and offers the system settings when refused', (tester) async {
    final gateway = FakeNotificationGateway(notificationsAllowed: false, grantOnRequest: false);
    final container = await createContainer(overrides: [launcherChannelProvider.overrideWithValue(FakeLauncherChannel()), notificationGatewayProvider.overrideWithValue(gateway)]);
    await pumpAt(tester, container, kShortcutsLocation);
    final toggle = find.byKey(const Key('shortcuts.notification'));

    await tapAndSettle(tester, toggle);
    expect(gateway.permissionRequests, 1);
    expect(container.read(shortcutSettingsProvider).addExpenseNotification, isFalse);
    expect(find.text('Allow notifications for Hisab to show the shortcut'), findsOneWidget);

    gateway.grantOnRequest = true;
    await tapAndSettle(tester, toggle);
    expect(container.read(shortcutSettingsProvider).addExpenseNotification, isTrue);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
  });

  testWidgets('Settings opens Shortcuts & widget', (tester) async {
    final container = await createContainer(overrides: [launcherChannelProvider.overrideWithValue(FakeLauncherChannel())]);
    await pumpAt(tester, container, '/settings');
    final tile = find.byKey(const Key('settings.shortcuts'));
    await tester.scrollUntilVisible(tile, 200, scrollable: find.byType(Scrollable).first);
    await tapAndSettle(tester, tile);
    expect(find.byType(ShortcutsScreen), findsOneWidget);
    expect(find.text('Add expense notification'), findsOneWidget);
  });

  testWidgets('Settings has no Shortcuts & widget row off Android', (tester) async {
    final container = await createContainer();
    await pumpAt(tester, container, '/settings');
    await tester.scrollUntilVisible(find.byKey(const Key('settingsNotifications')), 200, scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const Key('settings.shortcuts')), findsNothing);
  });
}

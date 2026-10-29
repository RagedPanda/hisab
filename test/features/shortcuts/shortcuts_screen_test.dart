import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/launcher/launcher_channel.dart';
import 'package:hisab/domain/launcher/quick_entry_shortcuts.dart';
import 'package:hisab/features/shortcuts/launcher_sync.dart';
import 'package:hisab/features/shortcuts/shortcut_settings.dart';
import 'package:hisab/features/shortcuts/shortcuts_screen.dart';

import '../../support/app_harness.dart';
import '../../support/screen_harness.dart';
import '../../support/seed.dart';

/// Android as far as the app can tell, without a platform: records what
/// would reach the launcher and turns down every system request.
class _FakeLauncher extends LauncherChannel {
  final shortcuts = <List<LauncherShortcut>>[];
  final widgets = <Map<String, Object>>[];
  final notifications = <Map<String, Object>>[];

  @override
  bool get isSupported => true;

  @override
  Future<void> setQuickEntryShortcuts(List<LauncherShortcut> shortcuts) async => this.shortcuts.add(shortcuts);

  @override
  Future<void> updateSpendWidget(Map<String, Object> data) async => widgets.add(data);

  @override
  Future<void> setAddExpenseNotification(AddExpenseNotificationConfig config) async => notifications.add(config.toMap());

  @override
  Future<bool> requestAddTile() async => false;

  @override
  Future<bool> requestPinWidget() async => false;
}

void main() {
  testWidgets('keeps the launcher shortcuts, widget and notification in step', (tester) async {
    final launcher = _FakeLauncher();
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
    final container = await createContainer(overrides: [launcherChannelProvider.overrideWithValue(_FakeLauncher())]);
    await pumpAt(tester, container, kShortcutsLocation);

    await tapAndSettle(tester, find.byKey(const Key('shortcuts.tile')));
    expect(find.textContaining('tap the pencil to edit'), findsOneWidget);
    await tapAndSettle(tester, find.text('OK'));

    await tapAndSettle(tester, find.byKey(const Key('shortcuts.widget')));
    expect(find.textContaining('tap Widgets and pick Hisab'), findsOneWidget);
  });

  testWidgets('Settings opens Shortcuts & widget', (tester) async {
    final container = await createContainer();
    await pumpAt(tester, container, '/settings');
    final tile = find.byKey(const Key('settings.shortcuts'));
    await tester.scrollUntilVisible(tile, 200, scrollable: find.byType(Scrollable).first);
    await tapAndSettle(tester, tile);
    expect(find.byType(ShortcutsScreen), findsOneWidget);
    expect(find.text('Add expense notification'), findsOneWidget);
  });
}

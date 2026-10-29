import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'launcher_sync.dart';
import 'shortcut_settings.dart';

const String kShortcutsLocation = '/settings/shortcuts';

/// Settings → Shortcuts & widget: the ways to start an expense without
/// going through Home first.
class ShortcutsScreen extends ConsumerWidget {
  const ShortcutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(shortcutSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shortcutsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: SwitchListTile(
              key: const Key('shortcuts.notification'),
              secondary: const Icon(Icons.notifications_outlined),
              title: Text(l10n.addExpenseNotification),
              subtitle: Text(l10n.addExpenseNotificationHint),
              value: settings.addExpenseNotification,
              onChanged: (enabled) => _setNotification(context, ref, enabled),
            ),
          ),
          Card(
            child: ListTile(
              key: const Key('shortcuts.tile'),
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: Text(l10n.quickSettingsTile),
              subtitle: Text(l10n.quickSettingsTileHint),
              trailing: const Icon(Icons.add),
              onTap: () => _addTile(context, ref),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(l10n.launcherShortcutsHelp, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  /// Turning it on asks for notification access first; without it the
  /// switch stays off and offers the system settings instead.
  Future<void> _setNotification(BuildContext context, WidgetRef ref, bool enabled) async {
    final notifier = ref.read(shortcutSettingsProvider.notifier);
    if (!enabled || !ref.read(launcherChannelProvider).isSupported) return notifier.setAddExpenseNotification(enabled);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    if (!(await Permission.notification.request()).isGranted) {
      showActionSnackBar(messenger, message: l10n.addExpenseNotificationBlocked, actionLabel: l10n.settings, onAction: () => openAppSettings());
      return;
    }
    await notifier.setAddExpenseNotification(true);
  }

  Future<void> _addTile(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    if (await ref.read(launcherChannelProvider).requestAddTile() || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.quickSettingsTile),
        content: Text(l10n.quickSettingsTileManual),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(MaterialLocalizations.of(dialogContext).okButtonLabel))],
      ),
    );
  }
}

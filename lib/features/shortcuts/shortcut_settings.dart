import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// Notification kind of the persistent "Add expense" shortcut, for a
/// per-kind notification setting. Off by default.
const String kAddExpenseNotificationKind = 'addExpenseShortcut';

const String kAddExpenseNotificationKey = 'addExpenseNotification';

/// Settings → Shortcuts & widget, kept beside [AppSettings] in shared
/// preferences.
class ShortcutSettings {
  const ShortcutSettings({this.addExpenseNotification = false});

  /// Whether the persistent "Add expense" notification is shown.
  final bool addExpenseNotification;

  ShortcutSettings copyWith({bool? addExpenseNotification}) =>
      ShortcutSettings(addExpenseNotification: addExpenseNotification ?? this.addExpenseNotification);
}

class ShortcutSettingsNotifier extends Notifier<ShortcutSettings> {
  @override
  ShortcutSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return ShortcutSettings(addExpenseNotification: prefs.getBool(kAddExpenseNotificationKey) ?? false);
  }

  Future<void> setAddExpenseNotification(bool enabled) async {
    state = state.copyWith(addExpenseNotification: enabled);
    await ref.read(sharedPreferencesProvider).setBool(kAddExpenseNotificationKey, enabled);
  }
}

final shortcutSettingsProvider = NotifierProvider<ShortcutSettingsNotifier, ShortcutSettings>(ShortcutSettingsNotifier.new);

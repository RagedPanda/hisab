import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

const String kAddExpenseNotificationKey = 'addExpenseNotification';
const String kSpendWidgetOpacityKey = 'spendWidgetOpacity';

/// Background opacity of the Home-screen widget, in percent.
const int kDefaultSpendWidgetOpacity = 100;
const int kMinSpendWidgetOpacity = 0;
const int kMaxSpendWidgetOpacity = 100;

int clampSpendWidgetOpacity(int percent) => percent.clamp(kMinSpendWidgetOpacity, kMaxSpendWidgetOpacity);

/// Settings → Shortcuts & widget, kept beside [AppSettings] in shared
/// preferences.
class ShortcutSettings {
  const ShortcutSettings({this.addExpenseNotification = false, this.widgetOpacity = kDefaultSpendWidgetOpacity});

  /// Whether the persistent "Add expense" notification is shown.
  final bool addExpenseNotification;

  /// Home-screen widget background opacity, 0..100 percent.
  final int widgetOpacity;

  ShortcutSettings copyWith({bool? addExpenseNotification, int? widgetOpacity}) => ShortcutSettings(
        addExpenseNotification: addExpenseNotification ?? this.addExpenseNotification,
        widgetOpacity: widgetOpacity ?? this.widgetOpacity,
      );
}

class ShortcutSettingsNotifier extends Notifier<ShortcutSettings> {
  @override
  ShortcutSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return ShortcutSettings(
      addExpenseNotification: prefs.getBool(kAddExpenseNotificationKey) ?? false,
      widgetOpacity: clampSpendWidgetOpacity(prefs.getInt(kSpendWidgetOpacityKey) ?? kDefaultSpendWidgetOpacity),
    );
  }

  Future<void> setAddExpenseNotification(bool enabled) async {
    state = state.copyWith(addExpenseNotification: enabled);
    await ref.read(sharedPreferencesProvider).setBool(kAddExpenseNotificationKey, enabled);
  }

  Future<void> setWidgetOpacity(int percent) async {
    state = state.copyWith(widgetOpacity: clampSpendWidgetOpacity(percent));
    await ref.read(sharedPreferencesProvider).setInt(kSpendWidgetOpacityKey, state.widgetOpacity);
  }
}

final shortcutSettingsProvider = NotifierProvider<ShortcutSettingsNotifier, ShortcutSettings>(ShortcutSettingsNotifier.new);

import 'dart:io';

import 'package:flutter/services.dart';

import '../../domain/launcher/quick_entry_shortcuts.dart';

/// Thin wrapper over the Android channel for what Hisab shows outside the
/// app: launcher shortcuts, the Quick Settings tile, the persistent
/// "Add expense" notification and the Home-screen spend widget. Every method is a no-op off Android.
class LauncherChannel {
  const LauncherChannel();

  static const _methods = MethodChannel('com.ragedpanda.hisab/launcher');

  bool get isSupported => Platform.isAndroid;

  /// Replaces the dynamic launcher shortcuts with [shortcuts].
  Future<void> setQuickEntryShortcuts(List<LauncherShortcut> shortcuts) async {
    if (!isSupported) return;
    await _methods.invokeMethod<void>('setQuickEntryShortcuts', [for (final shortcut in shortcuts) shortcut.toMap()]);
  }

  /// Shows or removes the persistent "Add expense" notification. Native code
  /// keeps [config] so it can post it again after a reboot.
  Future<void> setAddExpenseNotification(AddExpenseNotificationConfig config) async {
    if (!isSupported) return;
    await _methods.invokeMethod<void>('setAddExpenseNotification', config.toMap());
  }

  /// Asks the system to add the "Add expense" Quick Settings tile (Android
  /// 13+). False where it cannot ask, so the caller explains the manual way.
  Future<bool> requestAddTile() async {
    if (!isSupported) return false;
    return await _methods.invokeMethod<bool>('requestAddTile') ?? false;
  }

  /// Stores the spend widget's text and redraws every placed widget.
  Future<void> updateSpendWidget(Map<String, Object> data) async {
    if (!isSupported) return;
    await _methods.invokeMethod<void>('updateSpendWidget', data);
  }

  /// Asks the launcher to place the spend widget (Android 8+, launcher
  /// permitting). False where it cannot ask.
  Future<bool> requestPinWidget() async {
    if (!isSupported) return false;
    return await _methods.invokeMethod<bool>('requestPinWidget') ?? false;
  }
}

/// The persistent "Add expense" notification in the user's language.
class AddExpenseNotificationConfig {
  const AddExpenseNotificationConfig({required this.enabled, required this.channelName, required this.title, required this.body});

  final bool enabled;
  final String channelName;
  final String title;
  final String body;

  Map<String, Object> toMap() => {'enabled': enabled, 'channelName': channelName, 'title': title, 'body': body};
}

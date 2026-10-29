import 'dart:io';

import 'package:flutter/services.dart';

import '../../domain/launcher/quick_entry_shortcuts.dart';

/// Thin wrapper over the Android channel for what Hisab shows outside the
/// app: launcher shortcuts. Every method is a no-op off Android.
class LauncherChannel {
  const LauncherChannel();

  static const _methods = MethodChannel('com.ragedpanda.hisab/launcher');

  bool get isSupported => Platform.isAndroid;

  /// Replaces the dynamic launcher shortcuts with [shortcuts].
  Future<void> setQuickEntryShortcuts(List<LauncherShortcut> shortcuts) async {
    if (!isSupported) return;
    await _methods.invokeMethod<void>('setQuickEntryShortcuts', [for (final shortcut in shortcuts) shortcut.toMap()]);
  }
}

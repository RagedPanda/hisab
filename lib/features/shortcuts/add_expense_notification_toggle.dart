import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../salary/salary_setup_screen.dart' show ensureSalaryNotificationPermission;
import 'launcher_sync.dart';
import 'shortcut_settings.dart';

/// Turns the persistent "Add expense" notification on or off, for both
/// Settings > Shortcuts & widget and Settings > Notifications. Turning it on
/// asks for notification access first; without it the setting stays off and
/// this returns false so the caller can point at the system settings. Takes
/// the [container] rather than a widget's ref: the screen may close while the
/// prompt is up.
Future<bool> setAddExpenseNotification(ProviderContainer container, bool enabled) async {
  if (enabled && container.read(launcherChannelProvider).isSupported && !await _notificationsAllowedAfterAsking(container)) return false;
  await container.read(shortcutSettingsProvider.notifier).setAddExpenseNotification(enabled);
  return true;
}

Future<bool> _notificationsAllowedAfterAsking(ProviderContainer container) async {
  await ensureSalaryNotificationPermission(container);
  try {
    return (await container.read(notificationServiceProvider).checkPermission()).notificationsAllowed;
  } catch (_) {
    return false;
  }
}

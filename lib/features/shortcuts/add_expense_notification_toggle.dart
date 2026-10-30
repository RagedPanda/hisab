import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../salary/salary_setup_screen.dart' show ensureSalaryNotificationPermission;
import 'launcher_sync.dart';
import 'shortcut_settings.dart';

/// Turns the persistent "Add expense" notification on or off, for both
/// Settings > Shortcuts & widget and Settings > Notifications. Turning it on
/// asks for notification access first; without it the setting stays off and
/// this returns false so the caller can point at the system settings.
Future<bool> setAddExpenseNotification(WidgetRef ref, bool enabled) async {
  if (enabled && ref.read(launcherChannelProvider).isSupported && !await _notificationsAllowedAfterAsking(ref)) return false;
  await ref.read(shortcutSettingsProvider.notifier).setAddExpenseNotification(enabled);
  return true;
}

Future<bool> _notificationsAllowedAfterAsking(WidgetRef ref) async {
  await ensureSalaryNotificationPermission(ref);
  try {
    return (await ref.read(notificationServiceProvider).checkPermission()).notificationsAllowed;
  } catch (_) {
    return false;
  }
}

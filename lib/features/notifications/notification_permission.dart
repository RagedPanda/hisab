import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;

import '../../core/providers.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';

/// Asks for notification access (the Android 13+ prompt) unless it is already
/// granted; returns whether notifications are allowed afterwards. Every switch
/// that turns a notification on goes through this and stays off on false.
/// Never throws: a platform that cannot say counts as allowed, so a choice is
/// never lost to a plugin error. Takes the [container] rather than a widget's
/// ref: the screen may close while the prompt is up.
Future<bool> ensureNotificationPermission(ProviderContainer container) async {
  try {
    final notifications = container.read(notificationServiceProvider);
    if ((await notifications.checkPermission()).notificationsAllowed) return true;
    return await notifications.requestPermission();
  } catch (error) {
    debugPrint('Hisab: notification permission not requested: $error');
    return true;
  } finally {
    container.invalidate(notificationPermissionProvider);
  }
}

/// Says notifications are blocked and offers the app's system settings, where
/// they can be turned back on once Android stops showing the prompt.
void showNotificationsBlockedSnackBar(ScaffoldMessengerState messenger, AppLocalizations l10n, {String? message}) => showActionSnackBar(
      messenger,
      message: message ?? l10n.notificationsDenied,
      actionLabel: l10n.settings,
      onAction: () => openAppSettings(),
    );

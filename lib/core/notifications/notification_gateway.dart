/// The Android channel a notification goes to, so each can be muted apart.
enum AlertChannel {
  /// Bills, due dates and the salary alert.
  reminders,

  /// The evening summary and the samples Settings > Notifications shows.
  updates,
}

/// One local notification to post at [fireAt].
class AlertRequest {
  const AlertRequest({
    required this.id,
    required this.title,
    required this.body,
    required this.fireAt,
    required this.payload,
    required this.markPaidLabel,
    required this.snoozeLabel,
    required this.isMoney,
    this.withActions = true,
    this.channel = AlertChannel.reminders,
  });

  final int id;
  final String title;
  final String body;
  final DateTime fireAt;
  final String payload;

  /// Action button labels ("Mark paid" / "Done", "Snooze 1 day").
  final String markPaidLabel;
  final String snoozeLabel;

  /// Money reminders say "Mark paid"; documents and custom ones say "Done".
  final bool isMoney;

  /// False for plain nudges (the salary alert) that have nothing to mark paid or snooze.
  final bool withActions;

  final AlertChannel channel;
}

/// A notification the OS still holds for later.
class PendingAlert {
  const PendingAlert({required this.id, this.payload});
  final int id;
  final String? payload;
}

/// Whether the OS will show and time our notifications.
class NotificationPermissionState {
  const NotificationPermissionState({required this.notificationsAllowed, required this.exactAlarmsAllowed});

  /// Android 13+ POST_NOTIFICATIONS / iOS alert authorisation.
  final bool notificationsAllowed;

  /// Android 12+ "Alarms & reminders"; always true on iOS and old Android.
  final bool exactAlarmsAllowed;
}

/// A tap on a notification or one of its action buttons.
class NotificationTap {
  const NotificationTap({this.payload, this.actionId});
  final String? payload;
  final String? actionId;
}

/// Labels the platform needs before anything is scheduled (iOS action
/// categories and the Android channel), in the user's language.
class NotificationSetupTexts {
  const NotificationSetupTexts({
    required this.channelName,
    required this.channelDescription,
    required this.markPaidLabel,
    required this.doneLabel,
    required this.snoozeLabel,
    this.updatesChannelName,
    this.updatesChannelDescription,
  });

  final String channelName;
  final String channelDescription;

  /// Name of the [AlertChannel.updates] channel; [channelName] when null.
  final String? updatesChannelName;
  final String? updatesChannelDescription;
  final String markPaidLabel;
  final String doneLabel;
  final String snoozeLabel;
}

/// The plugin calls NotificationService needs, behind an interface so the
/// scheduling rules are unit tested without a device.
abstract interface class NotificationGateway {
  /// Sets up the plugin in the app's main isolate. [onTap] runs for taps and
  /// foreground actions; background actions go to the top-level handler.
  /// Scheduling works without it (the background action isolate never calls it).
  Future<void> initialize({required void Function(NotificationTap tap) onTap});

  /// The tap that launched the app from a killed state, if any.
  Future<NotificationTap?> launchTap();

  Future<void> schedule(AlertRequest request, {required bool exact});

  /// Posts [request] now, ignoring its fire time (Settings' samples).
  Future<void> show(AlertRequest request);
  Future<void> cancel(int id);
  Future<List<PendingAlert>> pending();

  Future<NotificationPermissionState> permissionState();

  /// Shows the system prompt (Android 13+, iOS); true when allowed afterwards.
  Future<bool> requestPermission();

  /// Opens the Android "Alarms & reminders" screen; true when allowed afterwards.
  Future<bool> requestExactAlarms();
}

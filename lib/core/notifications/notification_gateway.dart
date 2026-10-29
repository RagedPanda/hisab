/// The Android channel a notification goes to, so each can be muted apart.
enum AlertChannel {
  /// Bills, due dates and the salary alert.
  reminders,

  /// The evening summary and the samples Settings > Notifications shows.
  updates,
}

/// A notification [NotificationGateway.show] can post at once.
sealed class ShownAlert {
  const ShownAlert({required this.id, required this.title, required this.body, required this.payload});

  final int id;
  final String title;
  final String body;
  final String payload;
}

/// One local notification to post at [fireAt].
class AlertRequest extends ShownAlert {
  const AlertRequest({
    required super.id,
    required super.title,
    required super.body,
    required this.fireAt,
    required super.payload,
    required this.markPaidLabel,
    required this.snoozeLabel,
    required this.isMoney,
    this.withActions = true,
    this.channel = AlertChannel.reminders,
  });

  final DateTime fireAt;

  /// Action button labels ("Mark paid" / "Done", "Snooze 1 day").
  final String markPaidLabel;
  final String snoozeLabel;

  /// Money reminders say "Mark paid"; documents and custom ones say "Done".
  final bool isMoney;

  /// False for plain nudges (the salary alert) that have nothing to mark paid or snooze.
  final bool withActions;

  final AlertChannel channel;
}

/// A notification shown at once for an entry added from a bank SMS, with
/// Change category (opens the app) and Undo (runs in the background).
class SmsEntryAlert extends ShownAlert {
  const SmsEntryAlert({
    required super.id,
    required super.title,
    required super.body,
    required super.payload,
    required this.changeCategoryLabel,
    required this.undoLabel,
  });

  final String changeCategoryLabel;
  final String undoLabel;
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
    required this.smsChannelName,
    required this.smsChannelDescription,
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

  /// Channel of the "added from SMS" notifications.
  final String smsChannelName;
  final String smsChannelDescription;
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

  /// Posts [alert] now, replacing one with the same id: an [AlertRequest]
  /// ignores its fire time (Settings' samples, the evening summary), an
  /// [SmsEntryAlert] carries Change category and Undo.
  Future<void> show(ShownAlert alert);
  Future<void> cancel(int id);
  Future<List<PendingAlert>> pending();

  Future<NotificationPermissionState> permissionState();

  /// Shows the system prompt (Android 13+, iOS); true when allowed afterwards.
  Future<bool> requestPermission();

  /// Opens the Android "Alarms & reminders" screen; true when allowed afterwards.
  Future<bool> requestExactAlarms();
}

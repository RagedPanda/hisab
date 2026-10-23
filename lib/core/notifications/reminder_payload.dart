/// Notification payloads and action ids for reminder alerts. Pure, so the
/// foreground app, the background action isolate and tests agree on them.
library;

import '../../domain/split/settle_reminder.dart';

const String kReminderPayloadPrefix = 'hisab://reminder/';

/// Action id: open the app on a prefilled entry and mark the reminder paid.
const String kMarkPaidActionId = 'markPaid';

/// Action id: snooze the reminder by [kSnoozeDuration] without opening the app.
const String kSnoozeActionId = 'snooze';

const Duration kSnoozeDuration = Duration(days: 1);

String reminderPayload(String reminderId) => '$kReminderPayloadPrefix$reminderId';

/// The reminder id in a [reminderPayload], or null for anything else.
String? reminderIdFromPayload(String? payload) {
  if (payload == null || !payload.startsWith(kReminderPayloadPrefix)) return null;
  final id = payload.substring(kReminderPayloadPrefix.length);
  return id.isEmpty ? null : id;
}

/// In-app location a tapped reminder alert (or one of its actions) opens.
/// Snooze is handled without opening the app, so it has none.
String? reminderLocationFor({required String? payload, required String? actionId}) {
  final id = reminderIdFromPayload(payload);
  if (id == null) return null;
  if (actionId == kSnoozeActionId) return null;
  // A group's settle-up reminder opens the group's Balances tab, whichever button was used.
  final settleGroupId = groupIdOfSettleSchedule(id);
  if (settleGroupId != null) return settleUpLocationFor(settleGroupId);
  if (actionId == kMarkPaidActionId) return '/entry?reminder=$id';
  return '/reminders/$id';
}

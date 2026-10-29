/// Notification payloads and action ids for entries Hisab added from a bank
/// SMS. Pure, so the foreground app, the background action isolate and
/// tests agree on them.
library;

import '../../domain/reminders/reminder_schedule.dart';

const String _scheme = 'hisab';
const String _host = 'sms-entry';

/// Android channel (and notification kind) of the "added from SMS"
/// notifications; one place to gate or toggle this kind by.
const String kSmsEntryChannelId = 'sms_entries';

/// Action id: undo the automatic add without opening the app.
const String kSmsUndoActionId = 'smsUndo';

/// Action id: open the app on a category picker for the added entry.
const String kSmsChangeCategoryActionId = 'smsCategory';

/// Route of the screen that changes an SMS entry's category.
const String kSmsEntryCategoryRoute = '/sms/entry-category';

/// The SMS and the entry it added, as carried by a notification.
typedef SmsEntryRef = ({String smsId, String entryId});

String smsEntryPayload({required String smsId, required String entryId}) =>
    Uri(scheme: _scheme, host: _host, queryParameters: {'sms': smsId, 'entry': entryId}).toString();

/// The SMS and entry of an [smsEntryPayload], or null for anything else.
SmsEntryRef? smsEntryFromPayload(String? payload) {
  final uri = payload == null ? null : Uri.tryParse(payload);
  if (uri == null || uri.scheme != _scheme || uri.host != _host) return null;
  final smsId = uri.queryParameters['sms'] ?? '';
  final entryId = uri.queryParameters['entry'] ?? '';
  return smsId.isEmpty || entryId.isEmpty ? null : (smsId: smsId, entryId: entryId);
}

/// One notification per SMS, so a re-post replaces it instead of stacking.
int smsEntryNotificationId(String smsId) => notificationIdFor('sms:$smsId', 0);

/// Location of the category picker for [ref]'s entry.
String smsEntryCategoryLocation(SmsEntryRef ref) =>
    Uri(path: kSmsEntryCategoryRoute, queryParameters: {'entry': ref.entryId, 'sms': ref.smsId}).toString();

/// In-app location a tapped SMS entry notification (or its action) opens:
/// Change category opens the picker, the notification itself opens the
/// entry. Undo is handled without opening the app, so it has none.
String? smsEntryLocationFor({required String? payload, required String? actionId}) {
  final ref = smsEntryFromPayload(payload);
  if (ref == null || actionId == kSmsUndoActionId) return null;
  if (actionId == kSmsChangeCategoryActionId) return smsEntryCategoryLocation(ref);
  return Uri(path: '/entry', queryParameters: {'id': ref.entryId}).toString();
}

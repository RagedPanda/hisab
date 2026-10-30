/// What the evening summary and the Settings samples say, in the user's
/// language. Pure: figures, texts and the clock in, an [AlertRequest] out.
library;

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/notifications/notification_gateway.dart';
import '../../core/notifications/reminder_alert_text.dart';
import '../../domain/notifications/evening_summary.dart';
import '../../domain/notifications/notification_kinds.dart';
import '../../domain/reminders/reminder_schedule.dart';
import '../../l10n/generated/app_localizations.dart';

/// Payload of the evening summary; a tap just opens the app.
const String kEveningSummaryPayload = 'hisab://summary';

/// Payload of a sample; a tap just opens the app.
const String kSamplePayload = 'hisab://sample';

/// Made-up sender and amount the Bank SMS and reminder samples show.
const String kSampleSmsSender = 'HDFCBK';
const int kSampleAmountMinor = 185000;

/// Notification id of the evening summary posted [slot] evenings ahead.
int eveningSummaryNotificationId(int slot) => notificationIdFor('eveningSummary', slot);

/// Notification id of [kind]'s sample; a second tap replaces the first.
int sampleNotificationId(NotificationKind kind) => notificationIdFor('sample', kind.index);

/// "Spent ₹450 today · 2 SMS to review · 1 bill due in the next 3 days (₹1,850)".
String eveningSummaryBody(EveningSummary summary, AppLocalizations l10n, {required MoneyFormat moneyFormat}) {
  String money(int minor) => formatMinor(minor, format: moneyFormat);
  final due = l10n.eveningSummaryDue(summary.dueCount);
  return [
    summary.spentMinor > 0 ? l10n.eveningSummarySpent(money(summary.spentMinor)) : l10n.eveningSummaryNothingSpent,
    if (summary.reviewCount > 0) l10n.eveningSummaryReview(summary.reviewCount),
    if (summary.dueCount > 0) summary.dueMinor > 0 ? '$due (${money(summary.dueMinor)})' : due,
  ].join(' · ');
}

/// The evening summary posted [slot] evenings ahead, firing at [fireAt].
AlertRequest eveningSummaryAlert(EveningSummary summary, AppLocalizations l10n, {required int slot, required DateTime fireAt, required MoneyFormat moneyFormat}) =>
    _plainAlert(
      id: eveningSummaryNotificationId(slot),
      title: l10n.eveningSummaryTitle,
      body: eveningSummaryBody(summary, l10n, moneyFormat: moneyFormat),
      fireAt: fireAt,
      payload: kEveningSummaryPayload,
    );

/// A sample of [kind], titled "Sample · ..." so it is never mistaken for a
/// real alert. Reminders, salary and Bank SMS use made-up figures; the
/// evening summary shows [summary], today's real one.
AlertRequest sampleAlertFor(
  NotificationKind kind,
  AppLocalizations l10n, {
  required DateTime now,
  required MoneyFormat moneyFormat,
  required EveningSummary summary,
  bool smsAutoAdd = false,
}) {
  final sampleAmount = formatMinor(kSampleAmountMinor, format: moneyFormat);
  final (title, body) = switch (kind) {
    NotificationKind.reminders => (
        l10n.notifSampleReminderTitle,
        reminderDueCaption(l10n, dueAt: now.add(const Duration(days: 2)), at: now, amountMinor: kSampleAmountMinor, moneyFormat: moneyFormat),
      ),
    NotificationKind.salary => (l10n.salaryNotSeenTitle, l10n.salaryNotSeenBody(formatShortDate(now.subtract(const Duration(days: 2)), locale: l10n.localeName))),
    NotificationKind.bankSms => (
        l10n.smsNotificationTitle,
        smsAutoAdd ? l10n.smsNotificationBodyAmountAutoAdd(sampleAmount, kSampleSmsSender) : l10n.smsNotificationBodyAmount(sampleAmount, kSampleSmsSender),
      ),
    NotificationKind.eveningSummary => (l10n.eveningSummaryTitle, eveningSummaryBody(summary, l10n, moneyFormat: moneyFormat)),
    NotificationKind.addExpenseShortcut => (l10n.addExpense, l10n.addExpenseNotificationBody),
  };
  return _plainAlert(id: sampleNotificationId(kind), title: l10n.notificationsSampleTitle(title), body: body, fireAt: now, payload: kSamplePayload);
}

AlertRequest _plainAlert({required int id, required String title, required String body, required DateTime fireAt, required String payload}) => AlertRequest(
      id: id,
      title: title,
      body: body,
      fireAt: fireAt,
      payload: payload,
      markPaidLabel: '',
      snoozeLabel: '',
      isMoney: false,
      withActions: false,
      channel: AlertChannel.updates,
    );

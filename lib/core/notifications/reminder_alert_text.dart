import 'dart:ui';

import '../../data/db/database.dart';
import '../../domain/reminders/reminder_kind.dart';
import '../../domain/reminders/reminder_schedule.dart';
import '../../l10n/generated/app_localizations.dart';
import '../money.dart';
import 'notification_gateway.dart';
import 'reminder_payload.dart';

/// Strings for notifications in the app's language: the saved choice
/// ([localeCode], empty = follow the device) when Hisab supports it, else English.
AppLocalizations notificationLocalizations(String localeCode, {Locale? deviceLocale}) {
  final wanted = localeCode.isNotEmpty ? Locale(localeCode) : (deviceLocale ?? PlatformDispatcher.instance.locale);
  final supported = AppLocalizations.supportedLocales.any((locale) => locale.languageCode == wanted.languageCode);
  return lookupAppLocalizations(supported ? Locale(wanted.languageCode) : const Locale('en'));
}

NotificationSetupTexts notificationSetupTexts(AppLocalizations l10n) => NotificationSetupTexts(
      channelName: l10n.reminderChannelName,
      channelDescription: l10n.reminderChannelDescription,
      markPaidLabel: l10n.reminderMarkPaid,
      doneLabel: l10n.reminderMarkDone,
      snoozeLabel: l10n.reminderSnoozeOneDay,
    );

/// "Due in 3 days · ₹2,100", "Due today", "Overdue by 2 days · ₹999".
String reminderDueCaption(AppLocalizations l10n, {required DateTime dueAt, required DateTime at, int? amountMinor, required String currencySymbol}) {
  final days = daysUntilDue(dueAt, at);
  final due = days < 0
      ? l10n.reminderOverdueDays(-days)
      : days == 0
          ? l10n.reminderDueToday
          : l10n.reminderDueInDays(days);
  return amountMinor == null ? due : '$due · ${formatMinor(amountMinor, symbol: currencySymbol)}';
}

/// The notification for [alert] of [reminder].
AlertRequest alertRequestFor(Reminder reminder, PlannedAlert alert, AppLocalizations l10n, {required String currencySymbol}) {
  final isMoney = ReminderKind.fromKey(reminder.kind)?.isMoney ?? true;
  return AlertRequest(
    id: alert.notificationId,
    title: reminder.title.isEmpty ? l10n.remindersTitle : reminder.title,
    body: reminderDueCaption(l10n, dueAt: reminder.dueAt!, at: alert.fireAt, amountMinor: reminder.amountMinor, currencySymbol: currencySymbol),
    fireAt: alert.fireAt,
    payload: reminderPayload(reminder.id),
    markPaidLabel: isMoney ? l10n.reminderMarkPaid : l10n.reminderMarkDone,
    snoozeLabel: l10n.reminderSnoozeOneDay,
    isMoney: isMoney,
  );
}

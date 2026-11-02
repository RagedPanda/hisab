import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/reminder_alert_text.dart';
import '../../core/providers.dart';
import '../../core/dates.dart';
import '../../domain/notifications/evening_summary.dart';
import '../../domain/notifications/notification_kinds.dart';
import '../salary/salary_providers.dart';
import '../salary/salary_reminder.dart';
import '../shortcuts/add_expense_notification_toggle.dart';
import '../shortcuts/shortcut_settings.dart';
import 'evening_summary_service.dart';
import 'notification_permission.dart';
import 'notification_texts.dart';

/// What this install already does, for switches the user never touched.
NotificationFacts notificationFactsOf(WidgetRef ref) {
  final salary = ref.watch(salarySettingsProvider);
  return NotificationFacts(
    hasReminders: (ref.watch(upcomingRemindersProvider).value ?? const []).isNotEmpty,
    salaryAlertOn: salary.isSetUp && salary.reminderEnabled,
    smsEnabled: ref.watch(settingsProvider).smsEnabled,
    addExpenseShortcutOn: ref.watch(shortcutSettingsProvider).addExpenseNotification,
  );
}

/// Turns [kind] on or off and brings what is posted in line straight away.
/// Turning one on asks for the notification permission when it is missing;
/// refused, nothing changes and this returns false so the caller can point at
/// the system settings. These take the [container] rather than a widget's
/// ref: the screen may close while the prompt is up, and the change still has
/// to land.
Future<bool> setNotificationKind(ProviderContainer container, NotificationKind kind, bool on) async {
  // The Add expense shortcut asks itself (only where it can be shown).
  if (on && kind != NotificationKind.addExpenseShortcut && !await ensureNotificationPermission(container)) return false;
  switch (kind) {
    case NotificationKind.addExpenseShortcut:
      return setAddExpenseNotification(container, on);
    case NotificationKind.salary:
      final salary = container.read(salarySettingsProvider);
      await container.read(salarySettingsProvider.notifier).save(salary.copyWith(reminderEnabled: on));
      await syncSalaryReminder(container.read, now: DateTime.now());
    case NotificationKind.reminders || NotificationKind.bankSms || NotificationKind.eveningSummary:
      await container.read(notificationPrefsProvider.notifier).update((prefs) => prefs.withChoice(kind, on));
      // Bank SMS: SmsAutoSync hands the new choice to the native receiver.
      if (kind == NotificationKind.reminders) await container.read(reminderSchedulerProvider).rescheduleAll();
      if (kind == NotificationKind.eveningSummary) await refreshEveningSummary(container.read);
  }
  return true;
}

/// Moves the evening summary to [minuteOfDay] and re-posts it.
Future<void> setEveningSummaryMinute(ProviderContainer container, int minuteOfDay) async {
  await container.read(notificationPrefsProvider.notifier).update((prefs) => prefs.withEveningSummaryMinute(minuteOfDay));
  await refreshEveningSummary(container.read);
}

/// Posts a sample of [kind] now (asking for the permission first when
/// needed). The evening summary sample shows today's real figures.
Future<void> showNotificationSample(ProviderContainer container, NotificationKind kind) async {
  await ensureNotificationPermission(container);
  final now = DateTime.now();
  final summary = kind == NotificationKind.eveningSummary
      ? await loadEveningSummary(container.read, startOfDay(now))
      : const EveningSummary(spentMinor: 0, reviewCount: 0, dueCount: 0, dueMinor: 0);
  final l10n = notificationLocalizations(container.read(settingsProvider).localeCode);
  final request = sampleAlertFor(
    kind,
    l10n,
    now: now,
    moneyFormat: container.read(homeMoneyFormatProvider),
    summary: summary,
    smsAutoAdd: container.read(settingsProvider).smsAutoAdd,
  );
  await container.read(notificationGatewayProvider).show(request);
}

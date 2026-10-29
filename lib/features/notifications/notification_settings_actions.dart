import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/reminder_alert_text.dart';
import '../../core/providers.dart';
import '../../core/dates.dart';
import '../../domain/notifications/evening_summary.dart';
import '../../domain/notifications/notification_kinds.dart';
import '../salary/salary_providers.dart';
import '../salary/salary_reminder.dart';
import '../salary/salary_setup_screen.dart' show ensureSalaryNotificationPermission;
import 'evening_summary_service.dart';
import 'notification_texts.dart';

/// What this install already does, for switches the user never touched.
NotificationFacts notificationFactsOf(WidgetRef ref) {
  final salary = ref.watch(salarySettingsProvider);
  return NotificationFacts(
    hasReminders: (ref.watch(upcomingRemindersProvider).value ?? const []).isNotEmpty,
    salaryAlertOn: salary.isSetUp && salary.reminderEnabled,
    smsEnabled: ref.watch(settingsProvider).smsEnabled,
  );
}

/// Turns [kind] on or off and brings what is posted in line straight away.
/// Turning one on asks for the notification permission when it is missing.
Future<void> setNotificationKind(WidgetRef ref, NotificationKind kind, bool on) async {
  if (on) await ensureSalaryNotificationPermission(ref);
  switch (kind) {
    case NotificationKind.salary:
      final salary = ref.read(salarySettingsProvider);
      await ref.read(salarySettingsProvider.notifier).save(salary.copyWith(reminderEnabled: on));
      await syncSalaryReminder(ref.read, now: DateTime.now());
    case NotificationKind.reminders || NotificationKind.bankSms || NotificationKind.eveningSummary:
      await ref.read(notificationPrefsProvider.notifier).update((prefs) => prefs.withChoice(kind, on));
      // Bank SMS: SmsAutoSync hands the new choice to the native receiver.
      if (kind == NotificationKind.reminders) await ref.read(reminderSchedulerProvider).rescheduleAll();
      if (kind == NotificationKind.eveningSummary) await refreshEveningSummary(ref.read);
  }
}

/// Moves the evening summary to [minuteOfDay] and re-posts it.
Future<void> setEveningSummaryMinute(WidgetRef ref, int minuteOfDay) async {
  await ref.read(notificationPrefsProvider.notifier).update((prefs) => prefs.withEveningSummaryMinute(minuteOfDay));
  await refreshEveningSummary(ref.read);
}

/// Posts a sample of [kind] now (asking for the permission first when
/// needed). The evening summary sample shows today's real figures.
Future<void> showNotificationSample(WidgetRef ref, NotificationKind kind) async {
  await ensureSalaryNotificationPermission(ref);
  final now = DateTime.now();
  final summary = kind == NotificationKind.eveningSummary
      ? await loadEveningSummary(ref.read, startOfDay(now))
      : const EveningSummary(spentMinor: 0, reviewCount: 0, dueCount: 0, dueMinor: 0);
  final l10n = notificationLocalizations(ref.read(settingsProvider).localeCode);
  final request = sampleAlertFor(
    kind,
    l10n,
    now: now,
    moneyFormat: ref.read(homeMoneyFormatProvider),
    summary: summary,
    smsAutoAdd: ref.read(settingsProvider).smsAutoAdd,
  );
  await ref.read(notificationGatewayProvider).show(request);
}

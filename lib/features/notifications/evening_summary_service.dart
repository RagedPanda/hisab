import 'package:flutter/foundation.dart';

import '../../core/dates.dart';
import '../../core/home_currency.dart';
import '../../core/notifications/alarm_timing.dart';
import '../../core/notifications/notification_gateway.dart';
import '../../core/notifications/reminder_alert_text.dart';
import '../../core/providers.dart';
import '../../domain/notifications/evening_summary.dart';
import '../../domain/notifications/notification_kinds.dart';
import '../salary/salary_reminder.dart' show ProviderReader;
import '../upcoming/upcoming_sources.dart';
import 'notification_texts.dart';

/// Posts the evening summary for the next few evenings. There is no
/// background work in Hisab, so each evening's text is worked out now from
/// what the app knows and posted as a scheduled alert; [refresh] runs again
/// whenever the app opens or goes to the background, replacing them.
class EveningSummaryScheduler {
  EveningSummaryScheduler(this._gateway, {required this.loadSummary, required this.buildAlert, DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final NotificationGateway _gateway;

  /// The figures for one evening (midnight of that day).
  final Future<EveningSummary> Function(DateTime day) loadSummary;
  final AlertRequest Function(EveningSummary summary, {required int slot, required DateTime fireAt}) buildAlert;
  final DateTime Function() _clock;

  /// Cancels what was posted and, when [enabled], posts the next evenings at
  /// [minuteOfDay]. Returns how many were posted.
  Future<int> refresh({required bool enabled, required int minuteOfDay}) async {
    for (var slot = 0; slot < kEveningSummaryNightsAhead; slot++) {
      await _gateway.cancel(eveningSummaryNotificationId(slot));
    }
    if (!enabled) return 0;
    final times = nextEveningTimes(now: _clock(), minuteOfDay: minuteOfDay);
    final exact = useExactAlarms(await _gateway.permissionState());
    for (final (slot, fireAt) in times.indexed) {
      final request = buildAlert(await loadSummary(startOfDay(fireAt)), slot: slot, fireAt: fireAt);
      try {
        await _gateway.schedule(request, exact: exact);
      } catch (error) {
        if (!exact) rethrow;
        await _gateway.schedule(request, exact: false);
      }
    }
    return times.length;
  }
}

/// [day]'s figures from the app's data: my spend that day, SMS waiting for
/// review and what is due from [day] through the next 3 days.
Future<EveningSummary> loadEveningSummary(ProviderReader read, DateTime day) async {
  final end = DateTime(day.year, day.month, day.day + kEveningSummaryDueDays + 1);
  final totals = await read(entriesRepositoryProvider).watchTotals(dayRange(day)).first;
  // Straight from the database: a provider nobody watches is paused, so its
  // future would never complete here.
  final pending = await watchReviewableSms(read(smsLogRepositoryProvider), read(homeCurrencyCodeProvider)).first;
  final views = await read(recurringRepositoryProvider).watchViews().first;
  final reminders = await read(remindersRepositoryProvider).watchDue().first;
  return buildEveningSummary(
    day: day,
    spentMinor: totals.expense,
    reviewCount: pending.length,
    currency: read(homeCurrencyCodeProvider),
    recurring: recurringOccurrenceInputs(views, today: day, start: day, end: end, monthStartDay: read(settingsProvider).monthStartDay),
    reminders: reminderInputs(reminders, end: end),
  );
}

/// The evening summary scheduler on the app's providers.
EveningSummaryScheduler eveningSummarySchedulerOf(ProviderReader read) {
  final l10n = notificationLocalizations(read(settingsProvider).localeCode);
  final moneyFormat = read(homeMoneyFormatProvider);
  return EveningSummaryScheduler(
    read(notificationGatewayProvider),
    loadSummary: (day) => loadEveningSummary(read, day),
    buildAlert: (summary, {required slot, required fireAt}) => eveningSummaryAlert(summary, l10n, slot: slot, fireAt: fireAt, moneyFormat: moneyFormat),
  );
}

/// Brings the posted evening summaries in line with Settings and today's
/// data. Never throws: a failed refresh is retried on the next one.
Future<void> refreshEveningSummary(ProviderReader read) async {
  try {
    final prefs = read(notificationPrefsProvider);
    final enabled = notificationKindOn(NotificationKind.eveningSummary, choices: prefs.choices, facts: const NotificationFacts());
    await eveningSummarySchedulerOf(read).refresh(enabled: enabled, minuteOfDay: prefs.eveningSummaryMinute);
  } catch (error) {
    debugPrint('Hisab: evening summary not updated: $error');
  }
}

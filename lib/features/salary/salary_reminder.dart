import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import 'package:flutter/foundation.dart';

import '../../core/format.dart';
import '../../core/notifications/notification_gateway.dart';
import '../../core/notifications/reminder_alert_text.dart';
import '../../core/providers.dart';
import '../../domain/reminders/reminder_schedule.dart';
import '../../domain/salary/salary_schedule.dart';
import '../../l10n/generated/app_localizations.dart';
import 'salary_providers.dart';

/// Shows, schedules or removes the single "Salary not seen yet" alert.
abstract interface class SalaryAlertSink {
  Future<void> apply(SalaryNotificationPlan plan);
}

/// Payload of the salary alert; a tap opens the salary screen.
const String kSalaryAlertPayload = 'hisab://salary';

/// Location a tapped salary alert opens.
const String kSalaryLocation = '/salary';

/// The one notification id the salary alert reuses, so scheduling replaces it
/// and cancelling dismisses it (shown or pending). Same hash as reminder ids.
final int kSalaryNotificationId = notificationIdFor('salary', 0);

/// The "Salary not seen yet" alert for [plan], in [l10n]'s language.
AlertRequest salaryAlertRequest(ScheduleSalaryNotification plan, AppLocalizations l10n, {String? locale}) => AlertRequest(
      id: kSalaryNotificationId,
      title: l10n.salaryNotSeenTitle,
      body: l10n.salaryNotSeenBody(formatShortDate(plan.expected, locale: locale)),
      fireAt: plan.at,
      payload: kSalaryAlertPayload,
      markPaidLabel: '',
      snoozeLabel: '',
      isMoney: false,
      withActions: false,
    );

/// Posts the salary alert through the shared notification gateway.
class GatewaySalaryAlerts implements SalaryAlertSink {
  const GatewaySalaryAlerts(this._gateway, this._l10n, {this.locale});

  final NotificationGateway _gateway;
  final AppLocalizations _l10n;

  /// Date format locale for the body.
  final String? locale;

  /// Never throws: a failed alert must not break salary detection.
  @override
  Future<void> apply(SalaryNotificationPlan plan) async {
    try {
      switch (plan) {
        case CancelSalaryNotification():
          await _gateway.cancel(kSalaryNotificationId);
        case ScheduleSalaryNotification():
          // Alerts can be planned before any localized widget has loaded date symbols.
          await initializeDateFormatting(locale);
          final exact = (await _gateway.permissionState()).exactAlarmsAllowed;
          await _gateway.schedule(salaryAlertRequest(plan, _l10n, locale: locale), exact: exact);
      }
    } catch (error) {
      debugPrint('Hisab: salary alert not updated: $error');
    }
  }
}

final salaryAlertSinkProvider = Provider<SalaryAlertSink>((ref) {
  final localeCode = ref.watch(settingsProvider.select((settings) => settings.localeCode));
  final l10n = notificationLocalizations(localeCode);
  return GatewaySalaryAlerts(ref.watch(notificationGatewayProvider), l10n, locale: l10n.localeName);
});

/// Re-evaluates the salary cycle: claims the rule's waiting occurrence when
/// the salary arrived on its own, then schedules or dismisses the reminder.
/// Safe to call often (app start, resume, after SMS ingest, after saving).
/// Pass `ref.read` from a widget or a provider.
Future<SalaryNotificationPlan> syncSalaryReminder(ProviderReader read, {required DateTime now}) async {
  final settings = read(salarySettingsProvider);
  final status = await read(salaryServiceProvider).reconcile(settings, now: now, monthStartDay: read(settingsProvider).monthStartDay);
  final plan = planSalaryNotification(status, reminderEnabled: settings.reminderEnabled, now: now);
  await read(salaryAlertSinkProvider).apply(plan);
  return plan;
}

/// `ref.read` of either a [Ref] or a WidgetRef.
typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);

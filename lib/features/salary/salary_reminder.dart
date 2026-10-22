import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../../core/providers.dart';
import '../../domain/salary/salary_schedule.dart';
import 'salary_providers.dart';

/// Shows, schedules or removes the single "Salary not seen yet" alert.
abstract interface class SalaryAlertSink {
  Future<void> apply(SalaryNotificationPlan plan);
}

class _NoSalaryAlerts implements SalaryAlertSink {
  const _NoSalaryAlerts();
  @override
  Future<void> apply(SalaryNotificationPlan plan) async {}
}

final salaryAlertSinkProvider = Provider<SalaryAlertSink>((ref) => const _NoSalaryAlerts());

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

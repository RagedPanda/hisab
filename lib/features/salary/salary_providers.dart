import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/salary_settings.dart';
import '../../data/salary/salary_service.dart';
import '../../domain/salary/salary_schedule.dart';

class SalarySettingsNotifier extends Notifier<SalarySettings> {
  @override
  SalarySettings build() => SalarySettings.fromPrefs(ref.watch(sharedPreferencesProvider));

  Future<void> save(SalarySettings settings) async {
    state = settings;
    await settings.writeTo(ref.read(sharedPreferencesProvider));
  }
}

final salarySettingsProvider = NotifierProvider<SalarySettingsNotifier, SalarySettings>(SalarySettingsNotifier.new);

final salaryServiceProvider = Provider((ref) => SalaryService(ref.watch(databaseProvider)));

/// Recent incomes for salary detection; re-emits when entries change.
final salaryIncomesProvider = StreamProvider<List<IncomeCandidate>>((ref) {
  final now = DateTime.now();
  return ref.watch(salaryServiceProvider).watchRecentIncomes(salaryLookbackStart(now));
});

/// The current pay cycle, or null while the salary is not set up.
final salaryStatusProvider = Provider<SalaryStatus?>((ref) {
  final settings = ref.watch(salarySettingsProvider);
  if (!settings.isSetUp) return null;
  final incomes = ref.watch(salaryIncomesProvider).value ?? const <IncomeCandidate>[];
  return evaluateSalary(
    now: DateTime.now(),
    salaryDay: settings.salaryDay,
    expectedMinor: settings.amountMinor,
    incomes: incomes,
    shift: settings.shift,
    holidays: settings.holidaySet,
    accountId: settings.accountId,
    reminderDelayDays: settings.reminderDelayDays,
  );
});

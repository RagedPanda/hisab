import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/salary_settings.dart';
import '../../data/salary/salary_service.dart';
import '../../domain/salary/salary_schedule.dart';

class SalarySettingsNotifier extends Notifier<SalarySettings> {
  @override
  SalarySettings build() => SalarySettings.fromPrefs(ref.watch(sharedPreferencesProvider));

  /// Stores [settings], stamped now so backups can tell which setup is newer.
  Future<void> save(SalarySettings settings) async {
    final stamped = settings.copyWith(updatedAt: DateTime.now());
    state = stamped;
    await stamped.writeTo(ref.read(sharedPreferencesProvider));
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
  return settings.evaluate(now: DateTime.now(), incomes: incomes);
});

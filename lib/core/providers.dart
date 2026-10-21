import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/backup/backup_service.dart';
import '../data/db/database.dart';
import '../data/repositories/accounts_repository.dart';
import '../data/repositories/budgets_repository.dart';
import '../data/repositories/categories_repository.dart';
import '../data/repositories/entries_repository.dart';
import '../data/repositories/groups_repository.dart';
import '../data/repositories/sms_log_repository.dart';
import '../data/sms/sms_ingest_service.dart';
import '../domain/stats/dashboard_ledger.dart';
import '../domain/stats/spend_series.dart';
import 'dates.dart';
import 'settings.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('overridden in main'));

final entriesRepositoryProvider = Provider((ref) => EntriesRepository(ref.watch(databaseProvider)));
final accountsRepositoryProvider = Provider((ref) => AccountsRepository(ref.watch(databaseProvider)));
final categoriesRepositoryProvider = Provider((ref) => CategoriesRepository(ref.watch(databaseProvider)));
final groupsRepositoryProvider = Provider((ref) => GroupsRepository(ref.watch(databaseProvider)));
final budgetsRepositoryProvider = Provider((ref) => BudgetsRepository(ref.watch(databaseProvider)));
final smsLogRepositoryProvider = Provider((ref) => SmsLogRepository(ref.watch(databaseProvider)));

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => AppSettings.fromPrefs(ref.watch(sharedPreferencesProvider));

  Future<void> update(AppSettings Function(AppSettings) change) async {
    state = change(state);
    await state.writeTo(ref.read(sharedPreferencesProvider));
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// The month currently shown on dashboard and transactions. Stored as an anchor date.
class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void shift(int months) => state = DateTime(state.year, state.month + months, 15);
  void select(DateTime anchor) => state = anchor;
  void reset() => state = DateTime.now();
}

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(SelectedMonthNotifier.new);

final selectedRangeProvider = Provider<DateRange>((ref) {
  final anchor = ref.watch(selectedMonthProvider);
  final startDay = ref.watch(settingsProvider).monthStartDay;
  return monthRange(anchor, startDay: startDay);
});

final categoriesProvider = StreamProvider((ref) => ref.watch(categoriesRepositoryProvider).watchAll());
final allCategoriesProvider = StreamProvider((ref) => ref.watch(categoriesRepositoryProvider).watchAll(includeArchived: true));
final accountsProvider = StreamProvider((ref) => ref.watch(accountsRepositoryProvider).watchAll());
final budgetsProvider = StreamProvider((ref) => ref.watch(budgetsRepositoryProvider).watchAll());
final groupSummariesProvider = StreamProvider((ref) => ref.watch(groupsRepositoryProvider).watchSummaries());
final pendingSmsProvider = StreamProvider((ref) => ref.watch(smsLogRepositoryProvider).watchPending());

final monthEntriesProvider = StreamProvider((ref) {
  final range = ref.watch(selectedRangeProvider);
  return ref.watch(entriesRepositoryProvider).watchEntries(range: range, myLedger: true);
});
final monthTotalsProvider = StreamProvider((ref) {
  final range = ref.watch(selectedRangeProvider);
  return ref.watch(entriesRepositoryProvider).watchTotals(range);
});
final monthCategoryTotalsProvider = StreamProvider((ref) {
  final range = ref.watch(selectedRangeProvider);
  return ref.watch(entriesRepositoryProvider).watchCategoryTotals(range);
});
final monthDailyExpenseProvider = StreamProvider((ref) {
  final range = ref.watch(selectedRangeProvider);
  return ref.watch(entriesRepositoryProvider).watchDailyExpense(range);
});

/// Months of ledger the dashboard loads in one stream: the selected month and
/// the five before it, for the trend bars and last-month comparisons.
const int kDashboardMonths = 6;

final dashboardMonthRangesProvider = Provider<List<DateRange>>((ref) {
  final range = ref.watch(selectedRangeProvider);
  final startDay = ref.watch(settingsProvider).monthStartDay;
  return trailingMonthRanges(range, count: kDashboardMonths, startDay: startDay);
});

/// Every ledger line of the dashboard window, in one query, so each card
/// derives its figures from the same emission.
final dashboardLedgerProvider = StreamProvider<DashboardLedger>((ref) {
  final ranges = ref.watch(dashboardMonthRangesProvider);
  final window = DateRange(ranges.first.start, ranges.last.end);
  return ref.watch(entriesRepositoryProvider).watchLedgerLines(window).map((lines) => DashboardLedger(ranges: ranges, lines: lines));
});

final smsIngestServiceProvider = Provider((ref) => SmsIngestService(
      smsLog: ref.watch(smsLogRepositoryProvider),
      accounts: ref.watch(accountsRepositoryProvider),
      categories: ref.watch(categoriesRepositoryProvider),
      entries: ref.watch(entriesRepositoryProvider),
    ));

final backupServiceProvider = Provider((ref) => BackupService(ref.watch(databaseProvider)));

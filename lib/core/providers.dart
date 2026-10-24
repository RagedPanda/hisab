import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/backup/backup_service.dart';
import '../data/backup/month_start_backup.dart';
import '../data/db/database.dart';
import '../data/repositories/accounts_repository.dart';
import '../data/repositories/entry_removal.dart';
import '../data/repositories/budgets_repository.dart';
import '../data/repositories/categories_repository.dart';
import '../data/repositories/entries_repository.dart';
import '../data/repositories/groups_repository.dart';
import '../data/repositories/project_fields_repository.dart';
import '../data/repositories/projects_repository.dart';
import '../data/repositories/recurring_repository.dart';
import '../data/repositories/reminders_repository.dart';
import '../data/repositories/settle_schedule_repository.dart';
import '../data/repositories/sms_log_repository.dart';
import '../data/salary/salary_backup.dart';
import '../data/sms/sms_channel.dart';
import '../data/sms/sms_ingest_service.dart';
import '../data/sms/sms_notification_prompt.dart';
import '../data/sms/sms_sync_cursor.dart';
import '../domain/entries/entry_filter.dart';
import '../domain/sms/sms_currency.dart';
import '../domain/sms/sms_parser.dart';
import '../domain/stats/dashboard_ledger.dart';
import '../domain/stats/spend_series.dart';
import 'dates.dart';
import 'home_currency.dart';
import 'notifications/notification_gateway.dart';
import 'notifications/notification_service.dart';
import 'notifications/plugin_notification_gateway.dart';
import 'notifications/reminder_alert_text.dart';
import 'notifications/reminder_scheduler.dart';
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
final projectsRepositoryProvider = Provider((ref) => ProjectsRepository(ref.watch(databaseProvider)));
final projectFieldsRepositoryProvider = Provider((ref) => ProjectFieldsRepository(ref.watch(databaseProvider)));
final smsLogRepositoryProvider = Provider((ref) => SmsLogRepository(ref.watch(databaseProvider)));
final remindersRepositoryProvider = Provider((ref) => RemindersRepository(ref.watch(databaseProvider)));
final recurringRepositoryProvider = Provider((ref) => RecurringRepository(ref.watch(databaseProvider)));
final settleScheduleRepositoryProvider = Provider((ref) => SettleScheduleRepository(ref.watch(databaseProvider)));

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

/// The project the last saved entry went to, remembered for this app session
/// only so a run of entries for one project needs no re-picking.
class LastProjectNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? projectId) => state = projectId;
}

final lastProjectIdProvider = NotifierProvider<LastProjectNotifier, String?>(LastProjectNotifier.new);

final selectedRangeProvider = Provider<DateRange>((ref) {
  final anchor = ref.watch(selectedMonthProvider);
  final startDay = ref.watch(settingsProvider).monthStartDay;
  return monthRange(anchor, startDay: startDay);
});

final categoriesProvider = StreamProvider((ref) => ref.watch(categoriesRepositoryProvider).watchAll());
final allCategoriesProvider = StreamProvider((ref) => ref.watch(categoriesRepositoryProvider).watchAll(includeArchived: true));
final accountsProvider = StreamProvider((ref) => ref.watch(accountsRepositoryProvider).watchAll());
final recentAccountIdsProvider = StreamProvider((ref) => ref.watch(entriesRepositoryProvider).watchRecentAccountIds());
final budgetsProvider = StreamProvider((ref) => ref.watch(budgetsRepositoryProvider).watchAll());
final groupSummariesProvider = StreamProvider((ref) => ref.watch(groupsRepositoryProvider).watchSummaries());

/// Every live project with its spend, budget progress and month buckets.
final projectViewsProvider = StreamProvider<List<ProjectView>>((ref) {
  final monthStartDay = ref.watch(settingsProvider).monthStartDay;
  return ref.watch(projectsRepositoryProvider).watchViews(monthStartDay: monthStartDay);
});
final recurringViewsProvider = StreamProvider((ref) => ref.watch(recurringRepositoryProvider).watchViews());
/// SMS waiting for review. Rows in another currency, queued before such SMS
/// were ignored, are left out so they neither show nor count on Home.
final pendingSmsProvider = StreamProvider((ref) {
  final homeCurrency = ref.watch(homeCurrencyCodeProvider);
  return ref
      .watch(smsLogRepositoryProvider)
      .watchPending()
      .map((rows) => rows.where((row) => !isForeignCurrency(smsCurrencyCode(row.body), homeCurrency)).toList());
});
final smsHistoryProvider = StreamProvider((ref) => ref.watch(smsLogRepositoryProvider).watchHistory());

final monthEntriesProvider = StreamProvider((ref) {
  final range = ref.watch(selectedRangeProvider);
  return ref.watch(entriesRepositoryProvider).watchEntries(range: range, myLedger: true);
});
/// My ledger in an explicit window, for the Entries date filter.
final windowEntriesProvider = StreamProvider.family<List<EntryDetails>, ({DateTime start, DateTime end})>(
  (ref, window) => ref.watch(entriesRepositoryProvider).watchEntries(range: DateRange(window.start, window.end), myLedger: true),
);

/// Every tag used on a live entry, for the Entries tag filter.
final entryTagsProvider = StreamProvider((ref) => ref.watch(entriesRepositoryProvider).watchTagTexts().map(distinctTags));
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

/// Whether the user has recorded anything yet, independent of the month shown.
final hasAnyEntriesProvider = StreamProvider<bool>((ref) => ref.watch(entriesRepositoryProvider).watchHasAnyEntries());

final smsIngestServiceProvider = Provider((ref) => SmsIngestService(
      smsLog: ref.watch(smsLogRepositoryProvider),
      accounts: ref.watch(accountsRepositoryProvider),
      categories: ref.watch(categoriesRepositoryProvider),
      entries: ref.watch(entriesRepositoryProvider),
      cursor: SmsSyncCursor(ref.watch(sharedPreferencesProvider)),
      homeCurrencyCode: () => ref.read(homeCurrencyCodeProvider),
    ));

/// Requests POST_NOTIFICATIONS for Bank SMS notifications; a no-op off Android.
final smsNotificationPromptProvider = Provider((ref) => SmsNotificationPrompt(
      ref.watch(sharedPreferencesProvider),
      request: () async {
        if (SmsChannel.isSupported) await Permission.notification.request();
      },
    ));

final backupServiceProvider = Provider(
  (ref) => BackupService(ref.watch(databaseProvider), sections: [
        MonthStartBackupSection(ref.watch(sharedPreferencesProvider)),
        SalaryBackupSection(ref.watch(sharedPreferencesProvider)),
      ]),
);

// Reminders and notifications ------------------------------------------------

/// Plugin access for [NotificationService]; tests override it with a fake.
final notificationGatewayProvider = Provider<NotificationGateway>((ref) {
  final localeCode = ref.watch(settingsProvider.select((settings) => settings.localeCode));
  return PluginNotificationGateway(notificationSetupTexts(notificationLocalizations(localeCode)));
});

/// The single notification layer: schedule, cancel, rescheduleAll, permissions.
final notificationServiceProvider = Provider((ref) {
  final localeCode = ref.watch(settingsProvider.select((settings) => settings.localeCode));
  final currencySymbol = ref.watch(settingsProvider.select((settings) => settings.currencySymbol));
  final l10n = notificationLocalizations(localeCode);
  return NotificationService(
    ref.watch(notificationGatewayProvider),
    buildAlert: (reminder, alert) => alertRequestFor(reminder, alert, l10n, currencySymbol: currencySymbol),
  );
});

/// Reminder writes that keep notifications in step; what features call.
final reminderSchedulerProvider = Provider((ref) => ReminderScheduler(
      reminders: ref.watch(remindersRepositoryProvider),
      notifications: ref.watch(notificationServiceProvider),
      settleSchedules: ref.watch(settleScheduleRepositoryProvider),
      removeEntry: (entryId) => deleteEntryReversingBalances(
        entries: ref.read(entriesRepositoryProvider),
        accounts: ref.read(accountsRepositoryProvider),
        entryId: entryId,
      ),
    ));

/// Pending due reminders, earliest (overdue) first.
final upcomingRemindersProvider = StreamProvider((ref) => ref.watch(remindersRepositoryProvider).watchUpcoming());

/// Paid and skipped reminders, latest first.
final reminderHistoryProvider = StreamProvider((ref) => ref.watch(remindersRepositoryProvider).watchHistory());

/// Whether notifications and exact alarms are allowed; invalidate after asking.
final notificationPermissionProvider = FutureProvider((ref) => ref.watch(notificationServiceProvider).checkPermission());


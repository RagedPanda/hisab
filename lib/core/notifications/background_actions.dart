import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/db/database.dart';
import '../../data/repositories/accounts_repository.dart';
import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/entries_repository.dart';
import '../../data/repositories/entry_removal.dart';
import '../../data/repositories/payee_category_repository.dart';
import '../../data/repositories/reminders_repository.dart';
import '../../data/repositories/settle_schedule_repository.dart';
import '../../data/repositories/sms_log_repository.dart';
import '../../data/sms/reminder_payment_adapter.dart';
import '../../data/sms/sms_ingest_service.dart';
import '../../data/sms/sms_linked_reminder_scheduler.dart';
import '../../data/sms/sms_reminder_linker.dart';
import '../../data/sms/sms_sync_cursor.dart';
import '../home_currency.dart';
import '../settings.dart';
import 'notification_service.dart';
import 'plugin_notification_gateway.dart';
import 'reminder_alert_text.dart';
import 'reminder_payload.dart';
import 'reminder_scheduler.dart';
import 'sms_entry_payload.dart';

/// Builds the reminder scheduler outside the widget tree: in the background
/// action isolate, and in main() before the first frame. Wired like
/// reminderSchedulerProvider, so undoing an SMS payment behaves the same.
ReminderScheduler buildReminderScheduler(AppDatabase db, AppSettings settings) {
  final l10n = notificationLocalizations(settings.localeCode);
  final smsLog = SmsLogRepository(db);
  return SmsLinkedReminderScheduler(
    reminders: RemindersRepository(db),
    settleSchedules: SettleScheduleRepository(db),
    smsLog: smsLog,
    notifications: NotificationService(
      PluginNotificationGateway(notificationSetupTexts(l10n)),
      buildAlert: (reminder, alert) => alertRequestFor(reminder, alert, l10n, currencySymbol: settings.currencySymbol),
    ),
    removeEntry: (entryId) => deleteEntryReversingBalances(entries: EntriesRepository(db), accounts: AccountsRepository(db), entryId: entryId),
  );
}

/// The SMS ingest service outside the widget tree (the background action
/// isolate), wired like smsIngestServiceProvider so Undo also reopens a
/// reminder the SMS had paid.
SmsIngestService buildSmsIngestService(AppDatabase db, AppSettings settings, SharedPreferences prefs, ReminderScheduler scheduler) {
  final smsLog = SmsLogRepository(db);
  final accounts = AccountsRepository(db);
  return SmsIngestService(
    smsLog: smsLog,
    accounts: accounts,
    categories: CategoriesRepository(db),
    entries: EntriesRepository(db),
    cursor: SmsSyncCursor(prefs),
    homeCurrencyCode: () => homeCurrencyCodeOf(settings.currencyCode),
    reminderLinker: SmsReminderLinker(
      smsLog: smsLog,
      reminders: ReminderPaymentAdapter(reminders: RemindersRepository(db), scheduler: scheduler, accounts: accounts),
    ),
    payeeCategories: PayeeCategoryRepository(db),
  );
}

/// Notification actions that do not open the app (reminder Snooze, SMS
/// entry Undo) arrive here, in a fresh background isolate, even when Hisab
/// is not running. No UI work happens here.
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  handleBackgroundAction(payload: response.payload, actionId: response.actionId);
}

/// What a background action asks for, or null when it is not one this
/// isolate handles. Pure, so the routing is unit tested.
sealed class BackgroundAction {
  const BackgroundAction();

  static BackgroundAction? of({required String? payload, required String? actionId}) {
    final reminderId = reminderIdFromPayload(payload);
    if (reminderId != null && actionId == kSnoozeActionId) return SnoozeReminder(reminderId);
    final smsEntry = smsEntryFromPayload(payload);
    if (smsEntry != null && actionId == kSmsUndoActionId) return UndoSmsEntry(smsEntry);
    return null;
  }
}

class SnoozeReminder extends BackgroundAction {
  const SnoozeReminder(this.reminderId);
  final String reminderId;
}

class UndoSmsEntry extends BackgroundAction {
  const UndoSmsEntry(this.ref);
  final SmsEntryRef ref;
}

Future<void> handleBackgroundAction({required String? payload, required String? actionId}) async {
  final action = BackgroundAction.of(payload: payload, actionId: actionId);
  if (action == null) return;
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settings = AppSettings.fromPrefs(prefs);
  final db = AppDatabase();
  try {
    await runBackgroundAction(action, db: db, settings: settings, prefs: prefs);
  } finally {
    await db.close();
  }
}

/// Applies [action] to [db]; split out so tests run it on an in-memory database.
Future<void> runBackgroundAction(BackgroundAction action, {required AppDatabase db, required AppSettings settings, required SharedPreferences prefs, ReminderScheduler? scheduler}) async {
  final reminders = scheduler ?? buildReminderScheduler(db, settings);
  switch (action) {
    case SnoozeReminder(:final reminderId):
      await reminders.snooze(reminderId);
    case UndoSmsEntry(:final ref):
      await buildSmsIngestService(db, settings, prefs, reminders).undoAutoAddIfCurrent(smsId: ref.smsId, entryId: ref.entryId);
  }
}

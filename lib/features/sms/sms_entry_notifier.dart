import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/home_currency.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/notifications/reminder_alert_text.dart';
import '../../core/notifications/sms_entry_alert.dart';
import '../../core/providers.dart';
import '../../data/repositories/entries_repository.dart';
import '../../data/repositories/payee_category_repository.dart';
import '../../data/repositories/sms_log_repository.dart';
import '../../data/sms/sms_ingest_service.dart';
import '../../domain/sms/payee_category_memory.dart';
import '../../l10n/category_names.dart';
import '../../l10n/generated/app_localizations.dart';

/// Whether an automatic add is announced by notification rather than the
/// in-app snackbar: whenever Hisab is not on screen.
bool announcesInNotification(AppLifecycleState? state) => state != null && state != AppLifecycleState.resumed;

/// Posts the "added from SMS" notification (payee, category, account, with
/// Change category and Undo) for an entry added while Hisab is not on screen.
class SmsEntryNotifier {
  SmsEntryNotifier({
    required this.entries,
    required this.smsLog,
    required this.payeeCategories,
    required this.notifications,
    required this.l10n,
    required this.moneyFormat,
  });

  final EntriesRepository entries;
  final SmsLogRepository smsLog;
  final PayeeCategoryRepository payeeCategories;
  final NotificationService notifications;
  final AppLocalizations l10n;
  final MoneyFormat moneyFormat;

  Future<void> notify(SmsAutoAdded added) async {
    final details = await entries.getEntry(added.entryId);
    if (details == null || details.entry.deletedAt != null) return;
    final payee = parsedSmsPayee((await smsLog.getById(added.smsId))?.parsedJson);
    final memory = payee == null ? const <String, String>{} : await payeeCategories.memoryFor(kind: payee.kind, raw: payee.counterparty);
    final category = details.category;
    await notifications.showSmsEntry(smsEntryAlertFor(
      ref: (smsId: added.smsId, entryId: added.entryId),
      amountMinor: added.amountMinor,
      payee: added.payee,
      categoryName: category == null ? null : categoryDisplayName(category, Locale(l10n.localeName)),
      accountName: details.account?.name,
      asksForCategory: payee != null && asksForPayeeCategory(payee, memory),
      l10n: l10n,
      moneyFormat: moneyFormat,
    ));
  }
}

final smsEntryNotifierProvider = Provider((ref) {
  final settings = ref.watch(settingsProvider);
  return SmsEntryNotifier(
    entries: ref.watch(entriesRepositoryProvider),
    smsLog: ref.watch(smsLogRepositoryProvider),
    payeeCategories: ref.watch(payeeCategoryRepositoryProvider),
    notifications: ref.watch(notificationServiceProvider),
    l10n: notificationLocalizations(settings.localeCode),
    moneyFormat: ref.watch(homeMoneyFormatProvider),
  );
});

import '../../l10n/generated/app_localizations.dart';
import '../money.dart';
import 'notification_gateway.dart';
import 'sms_entry_payload.dart';

/// The notification for an entry added from a bank SMS: the amount in the
/// title, then payee, category and account ("Swiggy · Food delivery · HDFC
/// Bank ••1234"), and a hint to pick a category when the payee is a new
/// person ([asksForCategory]). Missing parts are left out.
SmsEntryAlert smsEntryAlertFor({
  required SmsEntryRef ref,
  required int amountMinor,
  required String? payee,
  required String? categoryName,
  required String? accountName,
  required bool asksForCategory,
  required AppLocalizations l10n,
  required MoneyFormat moneyFormat,
}) {
  final summary = [payee, categoryName, accountName].where((part) => part != null && part.trim().isNotEmpty).join(' · ');
  return SmsEntryAlert(
    id: smsEntryNotificationId(ref.smsId),
    title: l10n.smsAutoAddedOne(formatMinor(amountMinor, format: moneyFormat, showDecimals: false)),
    body: [if (summary.isNotEmpty) summary, if (asksForCategory) l10n.smsEntryNewPayeeHint].join('\n'),
    payload: smsEntryPayload(smsId: ref.smsId, entryId: ref.entryId),
    changeCategoryLabel: l10n.smsEntryChangeCategory,
    undoLabel: l10n.undo,
  );
}

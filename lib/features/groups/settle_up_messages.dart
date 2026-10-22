import 'package:intl/intl.dart';

import '../../domain/recurring/recurrence.dart';
import '../../domain/split/debt_simplifier.dart';
import '../../domain/split/settle_reminder.dart';
import '../../domain/split/settle_up_links.dart';
import '../../l10n/generated/app_localizations.dart';

/// One transfer as the names and formatted amount a message mentions.
typedef TransferWords = ({String from, String to, String amount});

/// The prewritten message for one transfer, from my point of view, with a
/// short footer. [role] decides the wording: you owe me, I owe you, or a
/// neutral line about two other people.
String settleUpMessage(AppLocalizations l10n, {required SettleRole role, required TransferWords transfer, required String groupName}) {
  final body = switch (role) {
    SettleRole.remind => l10n.reminderOwesMe(transfer.from, transfer.amount, groupName),
    SettleRole.pay => l10n.reminderIOwe(transfer.to, transfer.amount, groupName),
    SettleRole.others => l10n.reminderOwes(transfer.from, transfer.to, transfer.amount, groupName),
  };
  return '$body\n\n${l10n.sharedFromHisab}';
}

/// One message listing every transfer, for "Remind everyone who owes you".
String remindEveryoneMessage(AppLocalizations l10n, {required List<TransferWords> transfers, required String groupName}) {
  final lines = [for (final transfer in transfers) l10n.owesLine(transfer.from, transfer.to, transfer.amount)];
  return '${l10n.reminderEveryone(groupName)}\n${lines.join('\n')}\n\n${l10n.sharedFromHisab}';
}

/// Title and body of a scheduled settle-up notification, or null when
/// nothing is outstanding (a settled group gets no notification).
/// [nameOf] resolves member ids, [formatAmount] formats minor units.
({String title, String body})? settleReminderNotification(
  AppLocalizations l10n, {
  required SettleReminderFacts facts,
  required String groupName,
  required String Function(String memberId) nameOf,
  required String Function(int amountMinor) formatAmount,
  String? withMemberId,
}) {
  if (facts.isSettled) return null;
  final lines = withMemberId != null
      ? [
          if (facts.owedToMeMinor > 0) l10n.settleReminderOwesYou(nameOf(withMemberId), formatAmount(facts.owedToMeMinor)),
          if (facts.iOweMinor > 0) l10n.settleReminderYouOwe(nameOf(withMemberId), formatAmount(facts.iOweMinor)),
        ]
      : [
          if (facts.owedToMe.length == 1) l10n.settleReminderOwesYou(nameOf(facts.owedToMe.single.from), formatAmount(facts.owedToMeMinor)),
          if (facts.owedToMe.length > 1) l10n.settleReminderPeopleOweYou(facts.owedToMe.length, formatAmount(facts.owedToMeMinor)),
          if (facts.iOwe.length == 1) l10n.settleReminderYouOwe(nameOf(facts.iOwe.single.to), formatAmount(facts.iOweMinor)),
          if (facts.iOwe.length > 1) l10n.settleReminderYouOweTotal(formatAmount(facts.iOweMinor)),
        ];
  return (title: l10n.settleReminderTitle(groupName), body: lines.join(' · '));
}

/// The text to share from a settle-up reminder: the single-person message
/// when one transfer is involved, otherwise one line per transfer.
String? settleReminderNudge(
  AppLocalizations l10n, {
  required SettleReminderFacts facts,
  required String? myMemberId,
  required String groupName,
  required String Function(String memberId) nameOf,
  required String Function(int amountMinor) formatAmount,
}) {
  final transfers = [...facts.owedToMe, ...facts.iOwe];
  if (transfers.isEmpty) return null;
  TransferWords wordsOf(Transfer transfer) => (from: nameOf(transfer.from), to: nameOf(transfer.to), amount: formatAmount(transfer.amountMinor));
  if (transfers.length == 1) {
    return settleUpMessage(l10n, role: settleRoleFor(transfers.single, myMemberId), transfer: wordsOf(transfers.single), groupName: groupName);
  }
  return remindEveryoneMessage(l10n, transfers: [for (final transfer in transfers) wordsOf(transfer)], groupName: groupName);
}

/// Full weekday name for ISO [weekday] (1 = Monday) in [locale].
String weekdayName(int weekday, String? locale) => DateFormat.EEEE(locale).format(DateTime(2024, 1, weekday));

/// One line describing a settle-up schedule, e.g. "Reminder on day 1 every month".
String settleScheduleSummary(AppLocalizations l10n, SettleReminderSchedule schedule, {String? locale}) => switch (schedule.frequency) {
      RecurrenceFrequency.weekly => l10n.settleReminderWeeklySummary(weekdayName(schedule.weekday ?? DateTime.monday, locale)),
      _ when schedule.dayOfMonth == kLastDayOfMonth => l10n.settleReminderMonthlyLastDaySummary,
      _ => l10n.settleReminderMonthlySummary('${schedule.dayOfMonth ?? 1}'),
    };

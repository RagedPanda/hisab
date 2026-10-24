import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/repositories/groups_repository.dart';
import '../../domain/split/settle_reminder.dart';
import '../../l10n/l10n.dart';
import '../reminders/reminder_actions.dart';
import 'settle_reminder_service.dart';
import 'settle_reminder_sheet.dart';
import 'settle_up_messages.dart';
import 'settle_up_sheet.dart';

/// The text to share with the people in the group's settle-up schedule, or
/// null when there is nothing outstanding with them. It goes to the other
/// people, so it names them by their own names, never "You".
String? settleScheduleNudgeFor(AppLocalizations l10n, GroupDetail detail, SettleReminderSchedule schedule, {required MoneyFormat moneyFormat}) {
  final memberById = {for (final member in detail.allMembers) member.id: member};
  return settleReminderNudge(
    l10n,
    facts: settleReminderFacts(detail.balances.suggested, myMemberId: detail.me?.id, withMemberId: schedule.memberId),
    myMemberId: detail.me?.id,
    groupName: detail.group.name,
    nameOf: (id) => memberById[id]?.name ?? l10n.unknown,
    formatAmount: (amountMinor) => formatMinor(amountMinor, format: moneyFormat),
  );
}

/// "Remind me to settle up" on the Balances tab: shows the group's schedule,
/// opens the schedule sheet, and shares a nudge while something is owed.
class SettleScheduleTile extends ConsumerWidget {
  const SettleScheduleTile({super.key, required this.detail, required this.moneyFormat});
  final GroupDetail detail;
  final MoneyFormat moneyFormat;

  Future<void> _edit(BuildContext context, WidgetRef ref, SettleReminderSchedule? existing) async {
    final choice = await showSettleReminderSheet(
      context,
      otherMembers: [for (final member in detail.members) if (!member.isMe) member],
      existing: existing,
    );
    if (choice == null || !context.mounted) return;
    if (choice.schedule != null) {
      final l10n = context.l10n;
      await askReminderPermissionsIfNeeded(context, title: l10n.settleReminderPrePromptTitle, body: l10n.settleReminderPrePromptBody);
    }
    await ref.read(settleReminderServiceProvider).setSchedule(detail.group.id, choice.schedule);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final schedule = ref.watch(settleScheduleProvider(detail.group.id)).value;
    final nudge = schedule == null ? null : settleScheduleNudgeFor(l10n, detail, schedule, moneyFormat: moneyFormat);
    return ListTile(
      leading: Icon(schedule == null ? Icons.notifications_none_outlined : Icons.notifications_active_outlined),
      title: Text(l10n.settleReminderSheetTitle),
      subtitle: Text(schedule == null ? l10n.settleReminderOffLabel : settleScheduleSummary(l10n, schedule, locale: Localizations.localeOf(context).toString())),
      trailing: nudge == null
          ? const Icon(Icons.chevron_right)
          : IconButton(
              tooltip: l10n.settleReminderShareNudge,
              icon: const Icon(Icons.ios_share),
              onPressed: () => ref.read(textSharerProvider)(nudge),
            ),
      onTap: () => _edit(context, ref, schedule),
    );
  }
}

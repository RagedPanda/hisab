import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/notifications/reminder_alert_text.dart';
import '../../core/notifications/reminder_scheduler.dart';
import '../../core/providers.dart';
import '../../core/settings.dart';
import '../../data/repositories/groups_repository.dart';
import '../../data/repositories/settle_schedule_repository.dart';
import '../../domain/split/settle_reminder.dart';
import '../../l10n/l10n.dart';
import 'member_display.dart';
import 'settle_up_messages.dart';

/// What a group's settle-up notification says right now, about [memberId]
/// (or everyone); null when that is all settled. Amounts use the group's own
/// currency label when it has one, written as [moneyFormatFor] says.
SettleReminderText? settleReminderTextFor(
  AppLocalizations l10n,
  GroupDetail detail, {
  String? memberId,
  required MoneyFormat Function(String? currencyLabel) moneyFormatFor,
}) {
  final moneyFormat = moneyFormatFor(detail.group.currencyLabel);
  final memberById = {for (final member in detail.allMembers) member.id: member};
  return settleReminderNotification(
    l10n,
    facts: settleReminderFacts(detail.balances.suggested, myMemberId: detail.me?.id, withMemberId: memberId),
    groupName: detail.group.name,
    nameOf: (id) => memberById[id] == null ? l10n.unknown : memberShortName(l10n, memberById[id]!),
    formatAmount: (amountMinor) => formatMinor(amountMinor, format: moneyFormat),
    withMemberId: memberId,
  );
}

/// Turns a group's settle-up schedule on, changes or off, and keeps the
/// stored notification text in step with the group's balances. Alerts go
/// through the shared [ReminderScheduler].
class SettleReminderService {
  SettleReminderService({
    required this.groups,
    required this.schedules,
    required this.scheduler,
    required this.l10n,
    required this.moneyFormatFor,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final GroupsRepository groups;
  final SettleScheduleRepository schedules;
  final ReminderScheduler scheduler;
  final AppLocalizations l10n;
  /// Number format for a group's amounts, from its currency label.
  final MoneyFormat Function(String? currencyLabel) moneyFormatFor;
  final DateTime Function() _clock;

  Future<SettleReminderText?> _textFor(String groupId, String? memberId) async {
    final detail = await groups.getGroupDetail(groupId);
    return detail == null ? null : settleReminderTextFor(l10n, detail, memberId: memberId, moneyFormatFor: moneyFormatFor);
  }

  /// Saves [schedule] for the group, or turns it off when null.
  Future<void> setSchedule(String groupId, SettleReminderSchedule? schedule) async {
    final now = _clock();
    if (schedule == null) {
      await schedules.remove(groupId, now: now);
    } else {
      await schedules.save(groupId, schedule, now: now, text: await _textFor(groupId, schedule.memberId));
    }
    await scheduler.refresh(settleScheduleReminderId(groupId));
  }

  /// Rewords the group's pending alert after its balances changed.
  Future<void> refreshGroup(String groupId) async {
    final row = await schedules.getRow(settleScheduleReminderId(groupId));
    if (row == null) return;
    await schedules.refreshRow(row, now: _clock(), text: await _textFor(groupId, row.memberId));
    await scheduler.refresh(row.id);
  }

  /// Rolls every schedule past its last reminder on to the next date and
  /// rewords it; run on app start before alerts are re-posted.
  Future<void> refreshAll() async {
    for (final row in await schedules.liveRows()) {
      final groupId = row.groupId;
      await schedules.refreshRow(row, now: _clock(), text: groupId == null ? null : await _textFor(groupId, row.memberId));
    }
  }
}

final settleReminderServiceProvider = Provider((ref) {
  final settings = ref.watch(settingsProvider);
  final deviceLocale = ref.watch(deviceLocaleProvider);
  return SettleReminderService(
    groups: ref.watch(groupsRepositoryProvider),
    schedules: ref.watch(settleScheduleRepositoryProvider),
    scheduler: ref.watch(reminderSchedulerProvider),
    l10n: notificationLocalizations(settings.localeCode),
    moneyFormatFor: (currencyLabel) => groupMoneyFormatFor(currencyLabel, settings, deviceLocale),
  );
});

/// The group's settle-up schedule, or null when off.
final settleScheduleProvider = StreamProvider.family<SettleReminderSchedule?, String>(
    (ref, groupId) => ref.watch(settleScheduleRepositoryProvider).watchSchedule(groupId));

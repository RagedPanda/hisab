import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/money.dart';
import '../../core/notifications/alarm_timing.dart';
import '../../core/notifications/reminder_alert_text.dart';
import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../domain/reminders/reminder_buckets.dart';
import '../../domain/reminders/reminder_draft.dart';
import '../../domain/reminders/reminder_kind.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'reminder_actions.dart';
import 'new_reminder_sheet.dart';
import 'reminder_late_note.dart';
import 'reminder_editor.dart';
import 'paid_via_sms_label.dart';
import 'reminder_labels.dart';

/// How long a paid or skipped reminder can be reopened from History.
const kReminderUndoWindow = Duration(days: 7);

/// Bills, EMIs, card dues and renewals with their due dates; History holds
/// the paid and skipped ones. [highlightId] comes from a notification tap.
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key, this.highlightId});
  final String? highlightId;

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  var _showHistory = false;
  String? _pulseId;

  @override
  void initState() {
    super.initState();
    _pulseId = widget.highlightId;
    if (widget.highlightId != null) WidgetsBinding.instance.addPostFrameCallback((_) => _checkHighlight(widget.highlightId!));
  }

  Future<void> _checkHighlight(String id) async {
    final reminder = await ref.read(remindersRepositoryProvider).getById(id);
    if (!mounted) return;
    if (reminder != null && reminder.status != 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.reminderAlreadyDone)));
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _pulseId = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.remindersTitle)),
      floatingActionButton: _showHistory
          ? null
          : FloatingActionButton.extended(
              heroTag: 'add-reminder',
              onPressed: () => showNewReminderFlow(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.reminderFab),
            ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(l10n.upcoming)),
                ButtonSegment(value: true, label: Text(l10n.reminderTabHistory)),
              ],
              selected: {_showHistory},
              onSelectionChanged: (selection) => setState(() => _showHistory = selection.first),
            ),
          ),
        ),
        Expanded(child: _showHistory ? const _HistoryList() : _UpcomingList(pulseId: _pulseId)),
      ]),
    );
  }
}

class _UpcomingList extends ConsumerWidget {
  const _UpcomingList({this.pulseId});
  final String? pulseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reminders = ref.watch(upcomingRemindersProvider).value ?? const <Reminder>[];
    final permission = ref.watch(notificationPermissionProvider).value;
    final hasAlerts = reminders.any((r) => r.notifyAtMinute != null);
    final notificationsOff = permission != null && !permission.notificationsAllowed && hasAlerts;
    final now = DateTime.now();
    final buckets = groupByBucket(reminders.where((r) => r.dueAt != null), (Reminder r) => r.dueAt!, now);
    final banner = notificationsOff
        ? const _NotificationsOffBanner()
        : remindersMayArriveLate(permission, hasAlerts: hasAlerts)
            ? const ReminderLateNote()
            : null;
    if (reminders.isEmpty) {
      return EmptyState(
        icon: Icons.alarm,
        title: l10n.remindersEmptyTitle,
        message: l10n.remindersEmptyBody,
        action: FilledButton.tonal(onPressed: () => showNewReminderFlow(context), child: Text(l10n.reminderAdd)),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        ?banner,
        for (final bucket in ReminderBucket.values)
          if (buckets[bucket]?.isNotEmpty ?? false) ...[
            SectionHeader(reminderBucketLabel(l10n, bucket), padding: const EdgeInsets.fromLTRB(4, 16, 4, 8)),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (final reminder in buckets[bucket]!) _UpcomingTile(reminder: reminder, now: now, highlighted: reminder.id == pulseId),
              ]),
            ),
          ],
      ],
    );
  }
}

class _NotificationsOffBanner extends ConsumerWidget {
  const _NotificationsOffBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.notifications_off_outlined, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(child: Text(context.l10n.notifOffBanner, style: TextStyle(color: scheme.onSecondaryContainer))),
          ]),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => turnOnReminderNotifications(context), child: Text(context.l10n.notifTurnOn)),
          ),
        ]),
      ),
    );
  }
}

enum _RowAction { edit, skip, delete }

class _UpcomingTile extends ConsumerWidget {
  const _UpcomingTile({required this.reminder, required this.now, required this.highlighted});
  final Reminder reminder;
  final DateTime now;
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final kind = ReminderKind.of(reminder.kind);
    final repeat = ReminderRepeat.fromKey(reminder.repeat);
    final snoozed = reminder.snoozedUntil != null && reminder.snoozedUntil!.isAfter(now);
    final overdue = reminder.dueAt!.isBefore(DateTime(now.year, now.month, now.day));
    final caption = [
      reminderDueCaption(l10n, dueAt: reminder.dueAt!, at: now, amountMinor: reminder.amountMinor, currencySymbol: symbol),
      if (snoozed) l10n.reminderSnoozedUntil(formatRowDate(reminder.snoozedUntil!, locale: locale)) else formatRowDate(reminder.dueAt!, locale: locale),
      if (repeat.repeats) reminderRepeatLabel(l10n, repeat),
      if (reminder.documentNumber.isNotEmpty) reminder.documentNumber,
    ].join(' · ');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      color: highlighted ? scheme.primary.withValues(alpha: .12) : Colors.transparent,
      child: ListTile(
        key: ValueKey('reminder-${reminder.id}'),
        leading: CircleAvatar(
          backgroundColor: overdue ? scheme.errorContainer : scheme.secondaryContainer,
          foregroundColor: overdue ? scheme.onErrorContainer : scheme.onSecondaryContainer,
          child: Icon(reminderKindIcon(kind), size: 20),
        ),
        title: Text(reminder.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: overdue ? TextStyle(color: scheme.error) : null),
        onTap: () => showReminderEditor(context, existing: reminder),
        contentPadding: const EdgeInsets.only(left: 16, right: 4),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            tooltip: kind.isMoney ? l10n.reminderMarkPaid : l10n.reminderMarkDone,
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () => markReminderPaid(context, ref, reminder),
          ),
          PopupMenuButton<_RowAction>(
            onSelected: (action) => switch (action) {
              _RowAction.edit => showReminderEditor(context, existing: reminder),
              _RowAction.skip => closeReminderWithUndo(context, ref, reminder, skip: true),
              _RowAction.delete => deleteReminderWithUndo(context, ref, reminder),
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: _RowAction.edit, child: Text(l10n.edit)),
              if (repeat.repeats) PopupMenuItem(value: _RowAction.skip, child: Text(l10n.reminderSkip)),
              PopupMenuItem(value: _RowAction.delete, child: Text(l10n.delete)),
            ],
          ),
        ]),
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final history = ref.watch(reminderHistoryProvider).value ?? const <Reminder>[];
    if (history.isEmpty) return EmptyState(icon: Icons.history, title: l10n.reminderHistoryEmpty);
    final locale = Localizations.localeOf(context).toString();
    final symbol = ref.watch(settingsProvider).currencySymbol;
    final paidBySms = ref.watch(smsPaidReminderIdsProvider).value ?? const <String>{};
    final paidAmounts = ref.watch(reminderPaidAmountsProvider).value ?? const <String, int>{};
    final now = DateTime.now();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            for (final reminder in history) _historyTile(context, ref, reminder, now: now, locale: locale, symbol: symbol, l10n: l10n, paidBySms: paidBySms.contains(reminder.id), paidAmountMinor: paidAmounts[reminder.id]),
          ]),
        ),
      ],
    );
  }

  Widget _historyTile(BuildContext context, WidgetRef ref, Reminder reminder,
      {required DateTime now, required String locale, required String symbol, required AppLocalizations l10n, required bool paidBySms, int? paidAmountMinor}) {
    final kind = ReminderKind.of(reminder.kind);
    final closedAt = reminder.doneAt ?? reminder.updatedAt;
    final date = formatRowDate(closedAt, locale: locale);
    final status = reminder.status == 'skipped'
        ? l10n.reminderSkippedOn(date)
        : kind.isMoney
            ? l10n.reminderPaidOn(date)
            : l10n.reminderDoneOn(date);
    // What the linked entry paid wins over the reminder's expected amount.
    final amount = paidAmountMinor ?? reminderAmountOrNone(reminder.amountMinor);
    final caption = amount == null ? status : '$status · ${formatMinor(amount, symbol: symbol)}';
    final canUndo = now.difference(closedAt) <= kReminderUndoWindow;
    return ListTile(
      leading: CircleAvatar(child: Icon(reminderKindIcon(kind), size: 20)),
      title: Text(reminder.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: paidBySms
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(caption, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              const PaidViaSmsLabel(),
            ])
          : Text(caption, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: canUndo ? TextButton(onPressed: () => ref.read(reminderSchedulerProvider).undoDone(reminder.id), child: Text(l10n.undo)) : null,
    );
  }
}

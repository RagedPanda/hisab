import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../domain/notifications/notification_kinds.dart';
import '../../l10n/l10n.dart';
import '../reminders/reminder_actions.dart';
import '../salary/salary_providers.dart';
import '../salary/salary_reminder.dart' show kSalaryLocation;
import '../shell/widgets/common.dart';
import '../shortcuts/launcher_sync.dart' show launcherChannelProvider;
import 'notification_settings_actions.dart';

const String kNotificationSettingsLocation = '/notifications';

/// Title, one-line description and icon of each kind's row.
({String title, String help, IconData icon}) notificationKindLabels(NotificationKind kind, AppLocalizations l10n) => switch (kind) {
      NotificationKind.reminders => (title: l10n.notifKindReminders, help: l10n.notifKindRemindersHelp, icon: Icons.alarm),
      NotificationKind.salary => (title: l10n.notifKindSalary, help: l10n.notifKindSalaryHelp, icon: Icons.payments_outlined),
      NotificationKind.bankSms => (title: l10n.notifKindBankSms, help: l10n.notifKindBankSmsHelp, icon: Icons.sms_outlined),
      NotificationKind.eveningSummary => (title: l10n.notifKindEveningSummary, help: l10n.notifKindEveningSummaryHelp, icon: Icons.nights_stay_outlined),
      NotificationKind.addExpenseShortcut => (title: l10n.addExpenseNotification, help: l10n.addExpenseNotificationHint, icon: Icons.add_circle_outline),
    };

/// Settings > Notifications: a switch per kind, each with a sample.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final allowed = ref.watch(notificationPermissionProvider).value?.notificationsAllowed;
    final kinds = notificationKindsShown(launcherSupported: ref.watch(launcherChannelProvider).isSupported);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 12), child: Text(l10n.notificationsIntro, style: Theme.of(context).textTheme.bodyMedium)),
          if (allowed == false)
            Card(
              key: const Key('notificationsBlocked'),
              child: ListTile(
                leading: const Icon(Icons.notifications_off_outlined),
                title: Text(l10n.notificationsBlocked),
                trailing: TextButton(onPressed: () => turnOnReminderNotifications(context), child: Text(l10n.notificationsAllow)),
              ),
            ),
          for (final kind in kinds) _KindCard(kind),
        ],
      ),
    );
  }
}

class _KindCard extends ConsumerWidget {
  const _KindCard(this.kind);
  final NotificationKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final labels = notificationKindLabels(kind, l10n);
    final prefs = ref.watch(notificationPrefsProvider);
    final on = notificationKindOn(kind, choices: prefs.choices, facts: notificationFactsOf(ref));
    final needsSetup = _setupNote(ref, l10n);
    final salaryMissing = kind == NotificationKind.salary && !ref.watch(salarySettingsProvider).isSetUp;
    return Card(
      key: Key('notificationKind-${kind.name}'),
      child: Column(children: [
        SwitchListTile(
          secondary: Icon(labels.icon),
          title: Text(labels.title),
          subtitle: Text(needsSetup == null ? labels.help : '${labels.help}\n$needsSetup'),
          value: on,
          onChanged: salaryMissing ? null : (value) => setNotificationKind(ref, kind, value),
        ),
        if (kind == NotificationKind.eveningSummary && on)
          ListTile(
            key: const Key('eveningSummaryTime'),
            leading: const SizedBox(width: 24),
            title: Text(l10n.eveningSummaryTime),
            trailing: SettingValue(_timeLabel(context, prefs.eveningSummaryMinute)),
            visualDensity: VisualDensity.compact,
            onTap: () async {
              final minute = prefs.eveningSummaryMinute;
              final picked = await showTimePicker(context: context, initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60));
              if (picked != null) await setEveningSummaryMinute(ref, picked.hour * 60 + picked.minute);
            },
          ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Wrap(spacing: 4, children: [
              if (salaryMissing) TextButton(onPressed: () => context.push(kSalaryLocation), child: Text(l10n.salarySetUp)),
              TextButton.icon(
                key: Key('notificationSample-${kind.name}'),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: Text(l10n.notificationsShowSample),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final sent = l10n.notificationsSampleSent;
                  await showNotificationSample(ref, kind);
                  showTimedSnackBar(messenger, sent);
                },
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  /// Why the kind would not notify yet, if it needs something set up first.
  String? _setupNote(WidgetRef ref, AppLocalizations l10n) => switch (kind) {
        NotificationKind.salary when !ref.watch(salarySettingsProvider).isSetUp => l10n.notifKindSalaryNeedsSetup,
        NotificationKind.bankSms when !ref.watch(settingsProvider).smsEnabled => l10n.notifKindBankSmsNeedsSetup,
        _ => null,
      };

  static String _timeLabel(BuildContext context, int minute) =>
      MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: minute ~/ 60, minute: minute % 60), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));
}

/// Settings > Automation row: "2 of 5 on".
class NotificationsSettingsTile extends ConsumerWidget {
  const NotificationsSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final choices = ref.watch(notificationPrefsProvider).choices;
    final facts = notificationFactsOf(ref);
    final kinds = notificationKindsShown(launcherSupported: ref.watch(launcherChannelProvider).isSupported);
    final on = kinds.where((kind) => notificationKindOn(kind, choices: choices, facts: facts)).length;
    return ListTile(
      key: const Key('settingsNotifications'),
      leading: const Icon(Icons.notifications_outlined),
      title: Text(l10n.notificationsTitle),
      subtitle: Text(l10n.notificationsSettingsSubtitle(on, kinds.length)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(kNotificationSettingsLocation),
    );
  }
}

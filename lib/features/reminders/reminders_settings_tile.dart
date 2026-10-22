import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../l10n/l10n.dart';

/// Settings > Automation row: "3 upcoming · notifications on".
class RemindersSettingsTile extends ConsumerWidget {
  const RemindersSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final count = ref.watch(upcomingRemindersProvider).value?.length ?? 0;
    final allowed = ref.watch(notificationPermissionProvider).value?.notificationsAllowed;
    final countLabel = l10n.remindersUpcomingCount(count);
    return ListTile(
      leading: const Icon(Icons.alarm),
      title: Text(l10n.remindersTitle),
      subtitle: Text(allowed == null ? countLabel : l10n.remindersSettingsSubtitle(countLabel, allowed ? l10n.remindersNotificationsOn : l10n.remindersNotificationsOff)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/reminders'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/reminder_alert_text.dart';
import '../../core/providers.dart';
import '../../domain/reminders/reminder_kind.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'reminder_editor.dart';
import 'reminder_labels.dart';

/// Pending reminders linked to one project (the Vehicle project's PUC and
/// insurance), shown on the project screen; nothing when there are none.
final projectRemindersProvider = StreamProvider.family(
  (ref, String projectId) => ref.watch(remindersRepositoryProvider).watchForProject(projectId),
);

class ProjectRemindersSection extends ConsumerWidget {
  const ProjectRemindersSection({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(projectRemindersProvider(projectId)).value ?? const [];
    if (reminders.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final moneyFormat = ref.watch(homeMoneyFormatProvider);
    final now = DateTime.now();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(l10n.documentRemindersOnProject, padding: const EdgeInsets.fromLTRB(4, 20, 4, 8)),
      Card(
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (final reminder in reminders)
            ListTile(
              key: ValueKey('project-reminder-${reminder.id}'),
              leading: Icon(reminderKindIcon(ReminderKind.of(reminder.kind))),
              title: Text(reminder.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                [
                  reminderDueCaption(l10n, dueAt: reminder.dueAt!, at: now, amountMinor: reminder.amountMinor, moneyFormat: moneyFormat),
                  if (reminder.documentNumber.isNotEmpty) reminder.documentNumber,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => showReminderEditor(context, existing: reminder),
            ),
        ]),
      ),
    ]);
  }
}

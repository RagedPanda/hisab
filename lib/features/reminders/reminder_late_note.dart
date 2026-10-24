import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import 'reminder_actions.dart';

/// Exact alarms are not allowed, so alerts fall back to inexact and may be
/// late (decision 22). Shown wherever reminders are set up; tapping opens
/// the "Alarms & reminders" setting.
class ReminderLateNote extends StatelessWidget {
  const ReminderLateNote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: const ValueKey('reminders-late-note'),
      borderRadius: BorderRadius.circular(8),
      onTap: () => allowExactReminderAlarms(ProviderScope.containerOf(context, listen: false)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
        child: Row(children: [
          Icon(Icons.schedule, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(context.l10n.remindersLateNote, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary))),
        ]),
      ),
    );
  }
}

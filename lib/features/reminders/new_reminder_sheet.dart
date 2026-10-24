import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../domain/projects/project_math.dart';
import '../../domain/reminders/document_presets.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';
import 'document_preset_labels.dart';
import 'reminder_editor.dart';

/// Start of the new-reminder flow: a blank reminder, or one of the
/// "Documents & renewals" presets, which opens the editor prefilled.
Future<void> showNewReminderFlow(BuildContext context) async {
  final choice = await showModalBottomSheet<_NewReminderChoice>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => _NewReminderBody(controller: controller),
    ),
  );
  if (choice == null || !context.mounted) return;
  final preset = choice.preset;
  if (preset == null) {
    await showReminderEditor(context);
    return;
  }
  final now = DateTime.now();
  await showReminderEditor(
    context,
    initial: draftFromPreset(preset, title: documentPresetName(context.l10n, preset), today: DateTime(now.year, now.month, now.day), projectId: choice.projectId),
  );
}

/// What the sheet returned; [preset] null means a blank reminder.
/// [projectId] is the project the preset suggests linking, if any.
class _NewReminderChoice {
  const _NewReminderChoice(this.preset, {this.projectId});
  final DocumentPreset? preset;
  final String? projectId;
}

class _NewReminderBody extends ConsumerWidget {
  const _NewReminderBody({required this.controller});
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final activeProjects = (ref.watch(projectViewsProvider).value ?? const []).where((view) => view.status == ProjectStatus.active);
    final theme = Theme.of(context);
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(l10n.reminderNew, style: theme.textTheme.titleLarge),
        ),
        ListTile(
          key: const ValueKey('new-reminder.blank'),
          leading: const SizedBox.square(dimension: 40, child: Icon(Icons.add_alarm_outlined)),
          title: Text(l10n.reminderAdd),
          subtitle: Text(l10n.reminderTitleHint),
          onTap: () => Navigator.of(context).pop(const _NewReminderChoice(null)),
        ),
        SectionHeader(l10n.documentRemindersSection, padding: const EdgeInsets.fromLTRB(16, 16, 16, 0)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
          child: Text(l10n.documentRemindersHint, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        for (final preset in documentPresets)
          ListTile(
            key: ValueKey('new-reminder.preset.${preset.key}'),
            leading: SizedBox.square(dimension: 40, child: Icon(documentPresetIcon(preset))),
            title: Text(documentPresetName(l10n, preset)),
            onTap: () => Navigator.of(context).pop(
              _NewReminderChoice(
                preset,
                projectId: suggestedPresetProjectId(preset, activeProjects, idOf: (view) => view.project.id, templateKeyOf: (view) => view.project.templateKey),
              ),
            ),
          ),
      ],
    );
  }
}

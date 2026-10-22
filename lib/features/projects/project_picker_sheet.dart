import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/repositories/projects_repository.dart';
import '../../domain/projects/project_picker.dart';
import '../../l10n/l10n.dart';
import '../shell/widgets/common.dart';

/// What the project picker returned; [projectId] null means "No project".
/// A dismissed picker returns no choice at all.
class ProjectChoice {
  const ProjectChoice(this.projectId);
  final String? projectId;
}

/// Bottom sheet listing the projects an entry can go to (or the Entries list
/// can be filtered by), with a "No project" row first.
Future<ProjectChoice?> showProjectPicker(BuildContext context, {String? selectedId, bool includeCompleted = false}) =>
    showModalBottomSheet<ProjectChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, controller) => _ProjectPickerBody(selectedId: selectedId, includeCompleted: includeCompleted, controller: controller),
      ),
    );

class _ProjectPickerBody extends ConsumerWidget {
  const _ProjectPickerBody({required this.selectedId, required this.includeCompleted, required this.controller});
  final String? selectedId;
  final bool includeCompleted;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final views = pickableProjects<ProjectView>(
      ref.watch(projectViewsProvider).value ?? const [],
      idOf: (view) => view.project.id,
      statusOf: (view) => view.status,
      currentId: selectedId,
      includeCompleted: includeCompleted,
    );
    final selectedIcon = Icon(Icons.check, color: Theme.of(context).colorScheme.primary);
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(l10n.chooseProject, style: Theme.of(context).textTheme.titleLarge),
        ),
        ListTile(
          key: const ValueKey('project.none'),
          leading: const SizedBox.square(dimension: 40, child: Icon(Icons.folder_off_outlined)),
          title: Text(l10n.noProject),
          trailing: selectedId == null ? selectedIcon : null,
          onTap: () => Navigator.of(context).pop(const ProjectChoice(null)),
        ),
        for (final view in views)
          ListTile(
            key: ValueKey('project.option.${view.project.id}'),
            leading: IconBadge(icon: view.project.icon, color: view.project.color),
            title: Text(view.project.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: view.project.id == selectedId ? selectedIcon : null,
            onTap: () => Navigator.of(context).pop(ProjectChoice(view.project.id)),
          ),
        if (views.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.noActiveProjects, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
      ],
    );
  }
}

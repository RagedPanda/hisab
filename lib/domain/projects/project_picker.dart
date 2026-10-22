/// Choosing which project an entry belongs to. Pure, no Flutter or Drift.
library;

import 'project_math.dart';

/// The project a new entry starts with: the one it was opened for (the
/// project detail FAB), else the last project used this session while that
/// project is still active. Group entries never default to a project.
String? initialEntryProjectId({
  String? explicitId,
  String? lastUsedId,
  required Set<String> activeIds,
  bool isGroup = false,
}) {
  if (explicitId != null) return explicitId;
  if (isGroup || lastUsedId == null) return null;
  return activeIds.contains(lastUsedId) ? lastUsedId : null;
}

/// Projects offered in a picker, in their given order: active ones (and
/// completed ones when [includeCompleted]) plus [currentId] whatever its
/// status, so an entry on a finished project still shows its project.
List<T> pickableProjects<T>(
  Iterable<T> projects, {
  required String Function(T project) idOf,
  required ProjectStatus Function(T project) statusOf,
  String? currentId,
  bool includeCompleted = false,
}) =>
    [
      for (final project in projects)
        if (idOf(project) == currentId ||
            statusOf(project) == ProjectStatus.active ||
            (includeCompleted && statusOf(project) == ProjectStatus.completed))
          project,
    ];

/// Field values that still belong once the entry moves to a project whose
/// fields have [fieldKeys]; readings for other fields are dropped.
Map<String, V> keepFieldValues<V>(Map<String, V> values, Iterable<String> fieldKeys) {
  final keys = fieldKeys.toSet();
  return {
    for (final MapEntry(:key, :value) in values.entries)
      if (keys.contains(key)) key: value,
  };
}

/// Whether an entry passes the Entries project filter; no filter passes all.
bool matchesProjectFilter({String? selectedId, String? entryProjectId}) => selectedId == null || entryProjectId == selectedId;

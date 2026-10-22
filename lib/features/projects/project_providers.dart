import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/db/database.dart';
import '../../data/repositories/entries_repository.dart';
import '../../data/repositories/projects_repository.dart';
import '../../domain/projects/project_metrics.dart';

/// One project with its roll-ups; null once it is deleted.
final projectViewProvider = StreamProvider.family<ProjectView?, String>((ref, projectId) {
  final monthStartDay = ref.watch(settingsProvider).monthStartDay;
  return ref.watch(projectsRepositoryProvider).watchView(projectId, monthStartDay: monthStartDay);
});

/// Every live entry tagged to a project, newest first.
final projectEntriesProvider = StreamProvider.family<List<EntryDetails>, String>(
  (ref, projectId) => ref.watch(entriesRepositoryProvider).watchEntries(projectId: projectId),
);

/// Live fields of a project, in their display order.
final projectFieldsProvider = StreamProvider.family<List<ProjectField>, String>(
  (ref, projectId) => ref.watch(projectFieldsRepositoryProvider).watchFields(projectId),
);

/// Metrics the project's fields allow, recomputed as entries and values change.
final projectMetricsProvider = StreamProvider.family<ProjectMetrics, String>(
  (ref, projectId) => ref.watch(projectFieldsRepositoryProvider).watchMetrics(projectId),
);

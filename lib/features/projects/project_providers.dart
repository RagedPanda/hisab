import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/repositories/entries_repository.dart';
import '../../data/repositories/projects_repository.dart';

/// One project with its roll-ups; null once it is deleted.
final projectViewProvider = StreamProvider.family<ProjectView?, String>((ref, projectId) {
  final monthStartDay = ref.watch(settingsProvider).monthStartDay;
  return ref.watch(projectsRepositoryProvider).watchView(projectId, monthStartDay: monthStartDay);
});

/// Every live entry tagged to a project, newest first.
final projectEntriesProvider = StreamProvider.family<List<EntryDetails>, String>(
  (ref, projectId) => ref.watch(entriesRepositoryProvider).watchEntries(projectId: projectId),
);

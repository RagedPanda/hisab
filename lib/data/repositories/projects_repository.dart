import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../domain/ledger/personal_totals.dart';
import '../../domain/projects/project_math.dart';
import '../db/database.dart';
import '../db/watch_tables.dart';

/// A project with the figures its card and detail screen show.
class ProjectView {
  const ProjectView({required this.project, required this.totals});
  final Project project;
  final ProjectTotals totals;

  ProjectStatus get status => ProjectStatus.parse(project.status);
}

class ProjectsRepository {
  ProjectsRepository(this.db);
  final AppDatabase db;

  SimpleSelectStatement<$ProjectsTable, Project> _liveQuery({bool includeArchived = true}) => db.select(db.projects)
    ..where((t) => includeArchived ? t.deletedAt.isNull() : t.deletedAt.isNull() & t.status.equals(ProjectStatus.archived.name).not())
    ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);

  Stream<List<Project>> watchAll({bool includeArchived = true}) => _liveQuery(includeArchived: includeArchived).watch();
  Future<List<Project>> getAll({bool includeArchived = true}) => _liveQuery(includeArchived: includeArchived).get();

  Stream<Project?> watchProject(String id) => (db.select(db.projects)..where((t) => t.id.equals(id))).watchSingleOrNull();
  Future<Project?> byId(String id) => (db.select(db.projects)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<String> create({
    required String name,
    required String icon,
    required int color,
    String? templateKey,
    DateTime? startDate,
    DateTime? endDate,
    int? budgetMinor,
    String currency = 'INR',
    String notes = '',
    String? id,
  }) async {
    final projectId = id ?? newId();
    await db.into(db.projects).insert(ProjectsCompanion.insert(
          id: projectId,
          name: name,
          icon: Value(icon),
          color: color,
          templateKey: Value(templateKey),
          startDate: Value(startDate),
          endDate: Value(endDate),
          budgetMinor: Value(budgetMinor),
          currency: Value(currency),
          notes: Value(notes),
        ));
    return projectId;
  }

  Future<void> update(String id, ProjectsCompanion changes) => (db.update(db.projects)..where((t) => t.id.equals(id))).write(changes.copyWith(updatedAt: Value(DateTime.now())));

  Future<void> setStatus(String id, ProjectStatus status) => update(id, ProjectsCompanion(status: Value(status.name)));

  /// Soft delete; the entries keep their link so [restore] brings everything back.
  Future<void> delete(String id) => update(id, ProjectsCompanion(deletedAt: Value(DateTime.now())));

  Future<void> restore(String id) => update(id, const ProjectsCompanion(deletedAt: Value(null)));

  /// Live entries of [projectId] reduced to ledger lines. Group entries count
  /// in full here: a project tracks what the thing cost, not only my share.
  Future<List<LedgerLine>> getLines(String projectId) async {
    final rows = await _projectEntries(projectId).get();
    return [for (final row in rows) _toLine(row)];
  }

  /// Ledger lines of every live project, keyed by project id.
  Future<Map<String, List<LedgerLine>>> getLinesByProject() async {
    final rows = await (db.select(db.entries)..where((t) => t.projectId.isNotNull() & t.deletedAt.isNull())).get();
    final byProject = <String, List<LedgerLine>>{};
    for (final row in rows) {
      byProject.putIfAbsent(row.projectId!, () => []).add(_toLine(row));
    }
    return byProject;
  }

  /// Every live project with its totals, recomputed whenever projects or
  /// entries change. [now] and [monthStartDay] come from the caller so the
  /// maths stays testable.
  Stream<List<ProjectView>> watchViews({bool includeArchived = true, DateTime Function()? now, int monthStartDay = 1}) =>
      db.watchTables([db.projects, db.entries], () => getViews(includeArchived: includeArchived, now: (now ?? DateTime.now)(), monthStartDay: monthStartDay));

  Future<List<ProjectView>> getViews({bool includeArchived = true, required DateTime now, int monthStartDay = 1}) async {
    final projects = await getAll(includeArchived: includeArchived);
    final lines = await getLinesByProject();
    final views = [
      for (final project in projects)
        ProjectView(
          project: project,
          totals: projectTotals(
            lines[project.id] ?? const [],
            budgetMinor: project.budgetMinor,
            startDate: project.startDate,
            endDate: project.endDate,
            now: now,
            startDay: monthStartDay,
          ),
        ),
    ]..sort((a, b) => compareProjects(statusA: a.status, updatedA: a.project.updatedAt, statusB: b.status, updatedB: b.project.updatedAt));
    return views;
  }

  Stream<ProjectView?> watchView(String id, {DateTime Function()? now, int monthStartDay = 1}) => db.watchTables([db.projects, db.entries], () async {
        final project = await byId(id);
        if (project == null || project.deletedAt != null) return null;
        final lines = await getLines(id);
        return ProjectView(
          project: project,
          totals: projectTotals(lines, budgetMinor: project.budgetMinor, startDate: project.startDate, endDate: project.endDate, now: (now ?? DateTime.now)(), startDay: monthStartDay),
        );
      });

  SimpleSelectStatement<$EntriesTable, Entry> _projectEntries(String projectId) => db.select(db.entries)..where((t) => t.projectId.equals(projectId) & t.deletedAt.isNull());

  LedgerLine _toLine(Entry entry) => LedgerLine(kind: entry.kind, amountMinor: entry.amountMinor, occurredAt: entry.occurredAt, categoryId: entry.categoryId);
}

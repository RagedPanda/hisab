import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../domain/projects/project_metrics.dart';
import '../../domain/projects/project_templates.dart';
import '../db/database.dart';
import '../db/watch_tables.dart';

/// The domain description of a stored field.
TemplateField fieldSpecOf(ProjectField row) => TemplateField(
      row.key,
      ProjectFieldType.values.firstWhere((type) => type.name == row.type, orElse: () => ProjectFieldType.text),
      scope: row.scope == ProjectFieldScope.project.name ? ProjectFieldScope.project : ProjectFieldScope.entry,
      unit: row.unit,
      choices: decodeChoices(row.choices),
    );

/// Rows for a template's default fields, in template order.
List<ProjectFieldsCompanion> templateFieldRows(String projectId, ProjectTemplate template) => [
      for (var i = 0; i < template.fields.length; i++)
        ProjectFieldsCompanion.insert(
          id: newId(),
          projectId: projectId,
          key: template.fields[i].key,
          type: template.fields[i].type.name,
          unit: Value(template.fields[i].unit),
          choices: Value(encodeChoices(template.fields[i].choices)),
          scope: Value(template.fields[i].scope.name),
          sortOrder: Value(i),
        ),
    ];

/// The stored id of one entry's value for one field; stable so a re-save
/// (or a sync from another device) overwrites instead of duplicating.
String entryFieldValueId(String entryId, String fieldKey) => '$entryId/$fieldKey';

/// Rows for the non-empty [values] an entry recorded.
List<EntryFieldValuesCompanion> entryFieldValueRows(String entryId, Map<String, FieldReading> values) => [
      for (final MapEntry(:key, :value) in values.entries)
        if (!value.isEmpty)
          EntryFieldValuesCompanion.insert(
            id: entryFieldValueId(entryId, key),
            entryId: entryId,
            fieldKey: key,
            numberValue: Value(value.number),
            textValue: Value(value.text?.trim()),
            dateValue: Value(value.date),
          ),
    ];

FieldReading readingOf(EntryFieldValue row) => FieldReading(number: row.numberValue, text: row.textValue, date: row.dateValue);

class ProjectFieldsRepository {
  ProjectFieldsRepository(this.db);
  final AppDatabase db;

  SimpleSelectStatement<$ProjectFieldsTable, ProjectField> _fieldsQuery(String projectId) => db.select(db.projectFields)
    ..where((t) => t.projectId.equals(projectId) & t.deletedAt.isNull())
    ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.updatedAt)]);

  Stream<List<ProjectField>> watchFields(String projectId) => _fieldsQuery(projectId).watch();
  Future<List<ProjectField>> getFields(String projectId) => _fieldsQuery(projectId).get();

  /// Adds the template's fields the project does not have yet (by key).
  Future<void> addTemplateFields(String projectId, ProjectTemplate template) => db.transaction(() async {
        final existing = {for (final field in await getFields(projectId)) field.key};
        for (final row in templateFieldRows(projectId, template)) {
          if (!existing.contains(row.key.value)) await db.into(db.projectFields).insert(row);
        }
      });

  /// Adds a user-defined field at the end of the list and returns its id.
  Future<String> addField({
    required String projectId,
    required String label,
    required ProjectFieldType type,
    ProjectFieldScope scope = ProjectFieldScope.entry,
    String? unit,
    List<String> choices = const [],
  }) async {
    final fields = await getFields(projectId);
    final id = newId();
    await db.into(db.projectFields).insert(ProjectFieldsCompanion.insert(
          id: id,
          projectId: projectId,
          key: 'custom_$id',
          label: Value(label.trim()),
          type: type.name,
          unit: Value(unit == null || unit.trim().isEmpty ? null : unit.trim()),
          choices: Value(encodeChoices(choices)),
          scope: Value(scope.name),
          sortOrder: Value(fields.isEmpty ? 0 : fields.map((field) => field.sortOrder).reduce((a, b) => a > b ? a : b) + 1),
        ));
    return id;
  }

  Future<void> _update(String id, ProjectFieldsCompanion changes) =>
      (db.update(db.projectFields)..where((t) => t.id.equals(id))).write(changes.copyWith(updatedAt: Value(DateTime.now())));

  /// Sets (or clears, with nulls) a project-scope field's value.
  Future<void> setProjectValue(String id, {double? number, String? text}) =>
      _update(id, ProjectFieldsCompanion(numberValue: Value(number), textValue: Value(text == null || text.trim().isEmpty ? null : text.trim())));

  /// Soft delete; values entries recorded stay so [restoreField] brings them back.
  Future<void> deleteField(String id) => _update(id, ProjectFieldsCompanion(deletedAt: Value(DateTime.now())));
  Future<void> restoreField(String id) => _update(id, const ProjectFieldsCompanion(deletedAt: Value(null)));

  /// Live values one entry recorded, keyed by field key.
  Future<Map<String, FieldReading>> valuesForEntry(String entryId) async {
    final rows = await (db.select(db.entryFieldValues)..where((t) => t.entryId.equals(entryId) & t.deletedAt.isNull())).get();
    return {for (final row in rows) row.fieldKey: readingOf(row)};
  }

  /// Every live entry of the project with the field values it recorded.
  Future<List<MetricEntry>> metricEntries(String projectId) async {
    final entries = await (db.select(db.entries)..where((t) => t.projectId.equals(projectId) & t.deletedAt.isNull())).get();
    if (entries.isEmpty) return const [];
    final values = await (db.select(db.entryFieldValues)..where((t) => t.entryId.isIn(entries.map((entry) => entry.id)) & t.deletedAt.isNull())).get();
    final byEntry = <String, Map<String, FieldReading>>{};
    for (final row in values) {
      byEntry.putIfAbsent(row.entryId, () => {})[row.fieldKey] = readingOf(row);
    }
    return [
      for (final entry in entries) MetricEntry(kind: entry.kind, amountMinor: entry.amountMinor, occurredAt: entry.occurredAt, values: byEntry[entry.id] ?? const {}),
    ];
  }

  Future<ProjectMetrics> getMetrics(String projectId) async {
    final fields = await getFields(projectId);
    if (fields.isEmpty) return const ProjectMetrics();
    final entries = await metricEntries(projectId);
    return projectMetrics(
      fields: fields.map(fieldSpecOf).toList(),
      projectValues: {for (final field in fields) if (field.numberValue != null) field.key: field.numberValue!},
      entries: entries,
      spentMinor: entries.where((entry) => entry.isExpense).fold(0, (sum, entry) => sum + entry.amountMinor),
    );
  }

  /// Metrics recomputed whenever fields, values or entries change.
  Stream<ProjectMetrics> watchMetrics(String projectId) => db.watchTables([db.projectFields, db.entryFieldValues, db.entries], () => getMetrics(projectId));
}

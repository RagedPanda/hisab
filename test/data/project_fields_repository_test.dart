import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/backup/backup_service.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/project_fields_repository.dart';
import 'package:hisab/data/repositories/projects_repository.dart';
import 'package:hisab/domain/projects/project_metrics.dart';
import 'package:hisab/domain/projects/project_templates.dart';

void main() {
  late AppDatabase db;
  late ProjectsRepository projects;
  late ProjectFieldsRepository fields;
  late EntriesRepository entries;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    projects = ProjectsRepository(db);
    fields = ProjectFieldsRepository(db);
    entries = EntriesRepository(db);
  });

  tearDown(() => db.close());

  Future<String> spend(String projectId, int amount, DateTime at, Map<String, FieldReading> values) async {
    final entry = EntriesRepository.newExpense(amountMinor: amount, occurredAt: at, projectId: projectId);
    final id = entry.id.value;
    await entries.saveEntry(entry, fieldValues: entryFieldValueRows(id, values));
    return id;
  }

  test('a template project starts with its fields; a blank one with none', () async {
    final car = await projects.create(name: 'Scotty', icon: 'directions_car', color: 0xFF2196F3, templateKey: 'vehicle');
    final blank = await projects.create(name: 'Misc', icon: 'folder', color: 0xFF2196F3);
    final carFields = await fields.getFields(car);
    expect(carFields.map((field) => field.key), ['odometer', 'litres']);
    expect(carFields.first.unit, 'km');
    expect(fieldSpecOf(carFields.first).type, ProjectFieldType.number);
    expect(await fields.getFields(blank), isEmpty);

    await fields.addTemplateFields(car, templateByKey('vehicle')!);
    expect(await fields.getFields(car), hasLength(2), reason: 'adding a template again does not duplicate fields');
  });

  test('custom fields go last, keep their options and can be deleted and restored', () async {
    final house = await projects.create(name: 'House', icon: 'construction', color: 0xFF795548, templateKey: 'construction');
    final id = await fields.addField(projectId: house, label: ' Floor ', type: ProjectFieldType.choice, choices: ['Ground', 'First']);
    final all = await fields.getFields(house);
    final custom = all.last;
    expect(custom.id, id);
    expect(custom.label, 'Floor');
    expect(custom.key, startsWith('custom_'));
    expect(fieldSpecOf(custom).choices, ['Ground', 'First']);

    await fields.deleteField(id);
    expect((await fields.getFields(house)).map((field) => field.id), isNot(contains(id)));
    await fields.restoreField(id);
    expect((await fields.getFields(house)).last.id, id);
  });

  test('entry values are replaced on re-save and left alone when not passed', () async {
    final car = await projects.create(name: 'Scotty', icon: 'directions_car', color: 0xFF2196F3, templateKey: 'vehicle');
    final entryId = await spend(car, 200000, DateTime(2026, 10, 1), {'odometer': const FieldReading(number: 1000), 'litres': const FieldReading(number: 20)});
    expect((await fields.valuesForEntry(entryId))['odometer']?.number, 1000);

    final details = (await entries.getEntry(entryId))!;
    await entries.saveEntry(details.entry.toCompanion(false), fieldValues: entryFieldValueRows(entryId, {'odometer': const FieldReading(number: 1100)}));
    final values = await fields.valuesForEntry(entryId);
    expect(values.keys, ['odometer']);
    expect(values['odometer']?.number, 1100);

    await entries.saveEntry(details.entry.toCompanion(false));
    expect((await fields.valuesForEntry(entryId)).keys, ['odometer']);
    expect(await db.select(db.entryFieldValues).get(), hasLength(2), reason: 'stable ids: one row per entry and key');
  });

  test('metrics come from entry values and project-scope values', () async {
    final car = await projects.create(name: 'Scotty', icon: 'directions_car', color: 0xFF2196F3, templateKey: 'vehicle');
    await spend(car, 200000, DateTime(2026, 10, 1), {'odometer': const FieldReading(number: 10000), 'litres': const FieldReading(number: 20)});
    await spend(car, 300000, DateTime(2026, 10, 5), const {});
    await spend(car, 200000, DateTime(2026, 10, 10), {'odometer': const FieldReading(number: 11000), 'litres': const FieldReading(number: 20)});
    final metrics = await fields.getMetrics(car);
    expect(metrics.distance?.perKmMinor, 500);
    expect(metrics.fuel?.litres, 40);
    expect(metrics.fuel?.perLitreMinor, 10000);

    final house = await projects.create(name: 'House', icon: 'construction', color: 0xFF795548, templateKey: 'construction');
    final area = (await fields.getFields(house)).firstWhere((field) => field.key == builtUpAreaFieldKey);
    await fields.setProjectValue(area.id, number: 1000);
    await spend(house, 5000000, DateTime(2026, 10, 1), {'stage': const FieldReading(text: 'foundation')});
    final houseMetrics = await fields.getMetrics(house);
    expect(houseMetrics.perAreaMinor, 5000);
    expect(houseMetrics.breakdowns.single.byOption, {'foundation': 5000000});
  });

  test('backups carry fields and entry values', () async {
    final car = await projects.create(name: 'Scotty', icon: 'directions_car', color: 0xFF2196F3, templateKey: 'vehicle');
    await spend(car, 100, DateTime(2026, 10, 1), {'odometer': const FieldReading(number: 5)});
    final payload = await BackupService(db).snapshot();
    final fresh = AppDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);
    await BackupService(fresh).importSnapshot(payload);
    expect(await fresh.select(fresh.projectFields).get(), hasLength(2));
    expect((await fresh.select(fresh.entryFieldValues).getSingle()).numberValue, 5);
  });
}

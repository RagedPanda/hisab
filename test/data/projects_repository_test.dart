import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/ids.dart';
import 'package:hisab/data/backup/backup_service.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/projects_repository.dart';
import 'package:hisab/domain/projects/project_math.dart';

void main() {
  late AppDatabase db;
  late ProjectsRepository projects;
  late EntriesRepository entries;
  final now = DateTime(2026, 10, 21, 12);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    projects = ProjectsRepository(db);
    entries = EntriesRepository(db);
  });

  tearDown(() => db.close());

  Future<void> spend(String projectId, int amount, DateTime at, {String? categoryId, String kind = 'expense'}) =>
      entries.saveEntry(EntriesRepository.newExpense(amountMinor: amount, occurredAt: at, projectId: projectId, categoryId: categoryId, kind: kind));

  test('create, read back and update a project', () async {
    final id = await projects.create(name: 'Scotty', icon: 'two_wheeler', color: 0xFF1E88E5, templateKey: 'vehicle', budgetMinor: 5000000);
    final project = (await projects.byId(id))!;
    expect(project.name, 'Scotty');
    expect(project.status, 'active');
    expect(project.budgetMinor, 5000000);

    await projects.update(id, const ProjectsCompanion(name: Value('Scotty 125'), budgetMinor: Value(null)));
    final updated = (await projects.byId(id))!;
    expect(updated.name, 'Scotty 125');
    expect(updated.budgetMinor, isNull);
    expect(updated.updatedAt.isAfter(project.updatedAt) || updated.updatedAt == project.updatedAt, isTrue);
  });

  test('views carry spend per project, per category and per month with budget progress', () async {
    final fuel = (await (db.select(db.categories)..where((t) => t.seedKey.equals('fuel'))).getSingle()).id;
    final service = (await (db.select(db.categories)..where((t) => t.seedKey.equals('vehicle_service'))).getSingle()).id;
    final bike = await projects.create(name: 'Scotty', icon: 'two_wheeler', color: 1, budgetMinor: 1000000);
    final trip = await projects.create(name: 'Goa', icon: 'flight', color: 2);
    await spend(bike, 300000, DateTime(2026, 9, 3), categoryId: fuel);
    await spend(bike, 120000, DateTime(2026, 10, 14), categoryId: service);
    await spend(bike, 20000, DateTime(2026, 10, 15), kind: 'income');
    await spend(trip, 900000, DateTime(2026, 10, 1));
    await entries.saveEntry(EntriesRepository.newExpense(amountMinor: 77700, occurredAt: DateTime(2026, 10, 2)));

    final views = await projects.getViews(now: now);
    final bikeView = views.firstWhere((view) => view.project.id == bike);
    final tripView = views.firstWhere((view) => view.project.id == trip);
    expect(bikeView.totals.spentMinor, 420000);
    expect(bikeView.totals.incomeMinor, 20000);
    expect(bikeView.totals.byCategory, {fuel: 300000, service: 120000});
    expect(bikeView.totals.byMonth, {DateTime(2026, 9, 1): 300000, DateTime(2026, 10, 1): 120000});
    expect(bikeView.totals.budget!.remainingMinor, 580000);
    expect(tripView.totals.spentMinor, 900000);
    expect(tripView.totals.byCategory, {'': 900000});
    expect(tripView.totals.budget, isNull);
  });

  test('deleted entries and soft-deleted projects drop out; restore brings the project back', () async {
    final id = await projects.create(name: 'Kitchen', icon: 'home', color: 1);
    final entryId = newId();
    await entries.saveEntry(EntriesRepository.newExpense(id: entryId, amountMinor: 50000, occurredAt: DateTime(2026, 10, 5), projectId: id));
    await spend(id, 25000, DateTime(2026, 10, 6));
    await entries.deleteEntry(entryId);
    expect((await projects.getViews(now: now)).single.totals.spentMinor, 25000);

    await projects.delete(id);
    expect(await projects.getViews(now: now), isEmpty);
    expect(await projects.getAll(), isEmpty);

    await projects.restore(id);
    final restored = (await projects.getViews(now: now)).single;
    expect(restored.project.id, id);
    expect(restored.totals.spentMinor, 25000, reason: 'entries keep their link through delete and undo');
  });

  test('status changes order the list and archived projects can be hidden', () async {
    final archived = await projects.create(name: 'Old car', icon: 'directions_car', color: 1);
    final done = await projects.create(name: 'Wedding', icon: 'celebration', color: 1);
    final active = await projects.create(name: 'Scotty', icon: 'two_wheeler', color: 1);
    await projects.setStatus(archived, ProjectStatus.archived);
    await projects.setStatus(done, ProjectStatus.completed);

    final all = await projects.getViews(now: now);
    expect(all.map((view) => view.project.id), [active, done, archived]);
    expect(all.map((view) => view.status), [ProjectStatus.active, ProjectStatus.completed, ProjectStatus.archived]);
    final visible = await projects.getViews(now: now, includeArchived: false);
    expect(visible.map((view) => view.project.id), [active, done]);
  });

  test('watchViews emits again when an entry is added to a project', () async {
    final id = await projects.create(name: 'Scotty', icon: 'two_wheeler', color: 1);
    final emissions = <int>[];
    final subscription = projects.watchViews(now: () => now).listen((views) => emissions.add(views.single.totals.spentMinor));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await spend(id, 15000, DateTime(2026, 10, 5));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await subscription.cancel();
    expect(emissions.first, 0);
    expect(emissions.last, 15000);
  });

  test('backup snapshot includes projects and restores them', () async {
    final id = await projects.create(name: 'Scotty', icon: 'two_wheeler', color: 1, budgetMinor: 5000000);
    final payload = await BackupService(db).snapshot();
    expect((payload['projects'] as List).single['name'], 'Scotty');

    final fresh = AppDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);
    await BackupService(fresh).importSnapshot(payload);
    final restored = await ProjectsRepository(fresh).byId(id);
    expect(restored?.budgetMinor, 5000000);
  });
}

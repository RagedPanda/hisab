import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/categories_repository.dart';
import 'package:hisab/domain/categories/category_catalog.dart';
import 'package:hisab/domain/categories/category_packs.dart';

void main() {
  late AppDatabase db;
  late CategoriesRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = CategoriesRepository(db);
    await repo.getAll();
  });

  tearDown(() => db.close());

  Future<Category> bySeed(String key) async => (await repo.findBySeedKey(key))!;

  test('addPack creates the missing categories under the pack parent and reuses existing ones', () async {
    final fuelBefore = await bySeed('fuel');
    final added = await repo.addPack(vehiclePack);

    final expectedNew = packOnlySeeds().where((seed) => flattenCatalog(vehiclePack.roots).any((s) => s.key == seed.key)).length;
    expect(added, expectedNew);
    final parent = await bySeed('vehicle');
    expect(parent.parentId, isNull);
    expect(parent.packKey, 'vehicle');
    final tyres = await bySeed('vehicle_tyres_battery');
    expect(tyres.parentId, parent.id);
    expect(tyres.packKey, 'vehicle');
    final fuelAfter = await bySeed('fuel');
    expect(fuelAfter.id, fuelBefore.id);
    expect(fuelAfter.packKey, isNull);
    final fuelRows = (await repo.getAll(includeArchived: true)).where((c) => c.seedKey == 'fuel');
    expect(fuelRows.length, 1);
  });

  test('adding a pack twice creates nothing the second time', () async {
    await repo.addPack(weddingPack);
    final countAfterFirst = (await repo.getAll(includeArchived: true)).length;
    expect(await repo.addPack(weddingPack), 0);
    expect((await repo.getAll(includeArchived: true)).length, countAfterFirst);
  });

  test('trip pack hangs new children under the existing travel parent', () async {
    final travel = await bySeed('travel');
    await repo.addPack(tripPack);
    expect((await bySeed('trip_sightseeing')).parentId, travel.id);
    expect((await bySeed('travel')).packKey, isNull);
  });

  test('renovation after construction reuses the shared construction seeds', () async {
    await repo.addPack(constructionPack);
    final cement = await bySeed('build_cement');
    await repo.addPack(renovationPack);
    expect((await bySeed('build_cement')).id, cement.id);
    expect((await bySeed('reno_bathroom')).parentId, (await bySeed('renovation')).id);
  });

  test('re-adding a pack restores its archived categories', () async {
    await repo.addPack(vehiclePack);
    final puc = await bySeed('vehicle_puc');
    await repo.setArchived(puc.id, true);
    await repo.addPack(vehiclePack);
    expect((await bySeed('vehicle_puc')).isArchived, isFalse);
  });
}

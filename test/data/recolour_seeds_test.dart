import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/domain/categories/category_catalog.dart';

void main() {
  test('opening an existing install moves untouched seeded colours to the new palette', () async {
    final dir = await Directory.systemTemp.createTemp('hisab_palette');
    final file = File('${dir.path}/hisab.sqlite');
    final first = AppDatabase(NativeDatabase(file));
    Future<void> paint(AppDatabase db, String key, int color) =>
        (db.update(db.categories)..where((t) => t.seedKey.equals(key))).write(CategoriesCompanion(color: Value(color)));
    await paint(first, 'travel', 0xFF039BE5); // old default
    await paint(first, 'flights', 0xFF039BE5); // child on the old default
    await paint(first, 'social', 0xFFC0CA33); // old default, now Family's colour
    await paint(first, 'family', 0xFFF4511E); // old default
    await paint(first, 'pets', 0xFF123456); // user's own pick
    await first.close();

    final reopened = AppDatabase(NativeDatabase(file));
    Future<int> colorOf(String key) async =>
        (await (reopened.select(reopened.categories)..where((t) => t.seedKey.equals(key))).getSingle()).color;
    expect(await colorOf('travel'), findSeed('travel')!.color);
    expect(await colorOf('flights'), findSeed('travel')!.color);
    expect(await colorOf('social'), findSeed('social')!.color);
    expect(await colorOf('family'), findSeed('family')!.color);
    expect(await colorOf('pets'), 0xFF123456);
    expect(await reopened.recolourRetiredSeeds(), 0, reason: 'a second pass changes nothing');
    await reopened.close();
    await dir.delete(recursive: true);
  });
}

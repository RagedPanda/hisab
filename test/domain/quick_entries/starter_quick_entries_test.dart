import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/categories/category_catalog.dart';
import 'package:hisab/domain/quick_entries/starter_quick_entries.dart';

void main() {
  test('every starter files under a category in the seeded catalog', () {
    final catalogKeys = {for (final seed in flattenCatalog()) seed.key};
    expect([for (final starter in kStarterQuickEntries) starter.categorySeedKey].where((key) => !catalogKeys.contains(key)), isEmpty);
  });

  test('starters go in list order with their category ids, missing ones left blank', () {
    final rows = starterQuickEntryRows(hasAnyQuickEntry: false, categoryIdBySeedKey: {'milk_dairy': 'c-milk'});
    expect([for (final row in rows) (row.starter.id, row.categoryId, row.sortOrder)], [
      ('seed.quick.milk', 'c-milk', 0),
      ('seed.quick.tea', null, 1),
      ('seed.quick.petrol', null, 2),
      ('seed.quick.auto', null, 3),
    ]);
  });

  test('an install that ever had a quick entry gets no starters', () {
    expect(starterQuickEntryRows(hasAnyQuickEntry: true, categoryIdBySeedKey: const {}), isEmpty);
  });
}

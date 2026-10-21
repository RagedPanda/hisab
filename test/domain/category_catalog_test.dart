import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/categories/category_catalog.dart';

void main() {
  test('catalog keys are unique and broad', () {
    final all = flattenCatalog().toList();
    final keys = all.map((s) => s.key).toSet();
    expect(keys.length, all.length, reason: 'duplicate category keys');
    expect(categoryCatalog.where((s) => s.kind == CategoryKind.expense).length, greaterThanOrEqualTo(15));
    expect(all.where((s) => s.kind == CategoryKind.expense).length, greaterThanOrEqualTo(100));
    expect(all.where((s) => s.kind == CategoryKind.income).length, greaterThanOrEqualTo(10));
    expect(all.where((s) => s.kind == CategoryKind.transfer).length, greaterThanOrEqualTo(4));
    expect(findSeed('milk_dairy')!.units, contains('L'));
    expect(all.every((s) => s.icon.isNotEmpty && s.name.isNotEmpty), isTrue);
  });
}

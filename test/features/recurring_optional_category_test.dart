import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/recurring_repository.dart';
import 'package:hisab/domain/recurring/recurrence.dart';

/// A recurring rule mirrors the one-off editor: a category is optional and a
/// rule saved without one posts entries that are uncategorised (null category).
void main() {
  late AppDatabase db;
  late RecurringRepository recurring;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    recurring = RecurringRepository(db);
  });
  tearDown(() => db.close());

  test('a rule saved with no category posts an uncategorised entry', () async {
    await recurring.saveRule(RecurringRepository.newRule(
      name: 'Milk',
      kind: 'expense',
      amountMinor: 7000,
      // No categoryId: the form now leaves it unset.
      frequency: RecurrenceFrequency.daily,
      startDate: DateTime(2026, 10, 23),
      autoPost: true,
    ));

    await recurring.postDue(now: DateTime(2026, 10, 23, 12));

    final entries = await (db.select(db.entries)..where((t) => t.source.equals('recurring'))).get();
    expect(entries, hasLength(1));
    expect(entries.single.categoryId, isNull, reason: 'a rule with no category materialises as uncategorised');
    expect(entries.single.amountMinor, 7000);
  });

  test('a rule saved with a category still posts that category', () async {
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: 'cat-rent',
          name: 'Rent',
          icon: 'home',
          color: 0xFF9E9E9E,
          kind: 'expense',
        ));
    await recurring.saveRule(RecurringRepository.newRule(
      name: 'Rent',
      kind: 'expense',
      amountMinor: 1500000,
      categoryId: 'cat-rent',
      frequency: RecurrenceFrequency.daily,
      startDate: DateTime(2026, 10, 23),
      autoPost: true,
    ));

    await recurring.postDue(now: DateTime(2026, 10, 23, 12));

    final entries = await (db.select(db.entries)..where((t) => t.source.equals('recurring'))).get();
    expect(entries, hasLength(1));
    expect(entries.single.categoryId, 'cat-rent');
  });
}

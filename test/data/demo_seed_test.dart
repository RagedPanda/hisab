import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/debug/demo_plan.dart';
import 'package:hisab/data/debug/demo_seed.dart';
import 'package:hisab/data/repositories/accounts_repository.dart';
import 'package:hisab/data/repositories/budgets_repository.dart';
import 'package:hisab/data/repositories/groups_repository.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));

  tearDown(() => db.close());

  Future<int> demoEntryCount() async => (await (db.select(db.entries)..where((entry) => entry.source.equals(kDemoSource))).get()).length;

  test('seeds accounts, entries, budgets and a split trip once', () async {
    expect(await hasDemoData(db), isFalse);

    final now = DateTime(2026, 10, 29, 12);
    await seedDemoData(db, entryCount: 30, now: now);

    expect(await hasDemoData(db), isTrue);
    expect(await demoEntryCount(), planDemoEntries(count: 30, now: now).length + 1, reason: 'the planned entries plus the trip hotel');
    expect((await AccountsRepository(db).getAll()).map((account) => account.name), containsAll(['HDFC Savings', 'Axis Credit Card']));
    expect(await BudgetsRepository(db).watchAll().first, hasLength(3));
    expect((await GroupsRepository(db).watchGroups().first).single.name, 'Goa trip');
  });

  test('running the seeder again adds nothing', () async {
    await seedDemoData(db, entryCount: 10, now: DateTime(2026, 10, 29, 12));
    final seeded = await demoEntryCount();

    await seedDemoData(db, entryCount: 10, now: DateTime(2026, 10, 29, 12));

    expect(await demoEntryCount(), seeded);
  });
}

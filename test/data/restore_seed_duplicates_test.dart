import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/backup/backup_service.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/accounts_repository.dart';
import 'package:hisab/data/repositories/categories_repository.dart';
import 'package:hisab/domain/categories/category_catalog.dart';

Future<List<Category>> liveCategories(AppDatabase db) => (db.select(db.categories)..where((t) => t.deletedAt.isNull())).get();

Future<List<Account>> liveAccounts(AppDatabase db) => (db.select(db.accounts)..where((t) => t.deletedAt.isNull())).get();

Future<String> addEntry(AppDatabase db, {required String categoryId, required String accountId}) async {
  const id = 'entry-1';
  await db
      .into(db.entries)
      .insert(
        EntriesCompanion.insert(
          id: id,
          kind: 'expense',
          amountMinor: 25000,
          occurredAt: DateTime(2026, 10, 1),
          categoryId: Value(categoryId),
          accountId: Value(accountId),
        ),
      );
  return id;
}

/// Inserts a second copy of the catalog the way an old restore did: same seed
/// keys, new ids, plus a second empty Cash account.
Future<void> insertDuplicateSeed(AppDatabase db) async {
  var order = 0;
  for (final seed in flattenCatalog()) {
    await db.into(db.categories).insert(seedCategoryRow(seed, id: 'dup-${seed.key}', order: order++));
  }
  await db.into(db.accounts).insert(AccountsCompanion.insert(id: 'dup-cash', name: 'Cash', type: 'cash', color: 0xFF43A047));
}

void main() {
  final catalogSize = flattenCatalog().length;

  test('restoring a backup onto a fresh install keeps one seed and one Cash account', () async {
    final original = AppDatabase(NativeDatabase.memory());
    final food = (await CategoriesRepository(original).findBySeedKey('food'))!;
    final cash = (await liveAccounts(original)).single;
    final entryId = await addEntry(original, categoryId: food.id, accountId: cash.id);
    final backup = await BackupService(original).snapshot();
    await original.close();

    final reinstalled = AppDatabase(NativeDatabase.memory());
    expect((await liveCategories(reinstalled)).length, catalogSize);
    await BackupService(reinstalled).importSnapshot(backup);

    expect((await liveCategories(reinstalled)).length, catalogSize);
    expect((await liveAccounts(reinstalled)).map((a) => a.id), [cash.id]);
    final entry = await (reinstalled.select(reinstalled.entries)..where((t) => t.id.equals(entryId))).getSingle();
    expect(entry.categoryId, food.id);
    expect((await CategoriesRepository(reinstalled).findBySeedKey('food'))!.id, food.id);
    final live = await liveCategories(reinstalled);
    final liveIds = live.map((c) => c.id).toSet();
    expect(live.where((c) => c.parentId != null && !liveIds.contains(c.parentId)), isEmpty, reason: 'every child points at a live parent');

    // Restoring the same backup again changes nothing.
    await BackupService(reinstalled).importSnapshot(backup);
    expect((await liveCategories(reinstalled)).length, catalogSize);
    expect((await liveAccounts(reinstalled)).length, 1);
    await reinstalled.close();
  });

  test('lookups by key survive duplicates an old restore left behind', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await liveCategories(db);
    await insertDuplicateSeed(db);
    await db
        .into(db.accounts)
        .insert(AccountsCompanion.insert(id: 'hdfc-a', name: 'HDFC', type: 'bank', color: 1, smsKey: const Value('hdfc:1234')));
    await db
        .into(db.accounts)
        .insert(AccountsCompanion.insert(id: 'hdfc-b', name: 'HDFC', type: 'bank', color: 1, smsKey: const Value('hdfc:1234')));

    expect(await CategoriesRepository(db).findBySeedKey('food'), isNotNull);
    expect(await AccountsRepository(db).findBySmsKey('hdfc:1234'), isNotNull);
    await db.close();
  });

  test('startup folds duplicates into the copy that has entries and keeps used accounts', () async {
    final dir = await Directory.systemTemp.createTemp('hisab_dedupe');
    final file = File('${dir.path}/hisab.sqlite');
    final first = AppDatabase(NativeDatabase(file));
    await liveCategories(first);
    await insertDuplicateSeed(first);
    await addEntry(first, categoryId: 'dup-food', accountId: 'dup-cash');
    expect((await liveCategories(first)).length, catalogSize * 2);
    await first.close();

    final reopened = AppDatabase(NativeDatabase(file));
    expect((await liveCategories(reopened)).length, catalogSize);
    final keptFood = (await CategoriesRepository(reopened).findBySeedKey('food'))!;
    expect(keptFood.id, 'dup-food');
    final cashAccounts = await liveAccounts(reopened);
    expect(cashAccounts.map((a) => a.id), ['dup-cash'], reason: 'the empty seeded Cash goes, the used one stays');
    await reopened.close();
    await dir.delete(recursive: true);
  });

  test('startup repoints recurring rules and keeps a Cash account a rule uses', () async {
    final dir = await Directory.systemTemp.createTemp('hisab_dedupe_rules');
    final file = File('${dir.path}/hisab.sqlite');
    final first = AppDatabase(NativeDatabase(file));
    await liveCategories(first);
    await insertDuplicateSeed(first);
    await addEntry(first, categoryId: 'dup-food', accountId: 'dup-cash');
    await first
        .into(first.entries)
        .insert(
          EntriesCompanion.insert(
            id: 'entry-2',
            kind: 'expense',
            amountMinor: 100,
            occurredAt: DateTime(2026, 10, 2),
            categoryId: const Value('dup-food'),
          ),
        );
    final seededFood = (await liveCategories(first)).firstWhere((c) => c.seedKey == 'food' && c.id != 'dup-food');
    final seededCash = (await liveAccounts(first)).firstWhere((a) => a.id != 'dup-cash');
    await first
        .into(first.recurringRules)
        .insert(
          RecurringRulesCompanion.insert(
            id: 'rule-1',
            kind: 'expense',
            amountMinor: 50000,
            frequency: 'monthly',
            startDate: DateTime(2026, 10, 1),
            categoryId: Value(seededFood.id),
            accountId: Value(seededCash.id),
          ),
        );
    await first.close();

    final reopened = AppDatabase(NativeDatabase(file));
    final rule = await (reopened.select(reopened.recurringRules)..where((t) => t.id.equals('rule-1'))).getSingle();
    final keptFood = (await CategoriesRepository(reopened).findBySeedKey('food'))!;
    expect((await liveCategories(reopened)).length, catalogSize);
    expect(keptFood.id, 'dup-food', reason: 'the copy with more references wins');
    expect(rule.categoryId, 'dup-food', reason: 'the rule follows its category into the kept copy');
    expect((await liveAccounts(reopened)).map((a) => a.id).toSet(), {
      'dup-cash',
      seededCash.id,
    }, reason: 'a Cash account a rule uses is not dropped');
    await reopened.close();
    await dir.delete(recursive: true);
  });
}

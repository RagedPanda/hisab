import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/backup/backup_service.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/quick_entries_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late QuickEntriesRepository quickEntries;
  final now = DateTime(2026, 10, 29, 9);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    quickEntries = QuickEntriesRepository(db);
  });

  tearDown(() => db.close());

  Future<List<String>> labels() async => [for (final quick in await quickEntries.watchAll().first) quick.label];
  Future<Category> seeded(String seedKey) => (db.select(db.categories)..where((t) => t.seedKey.equals(seedKey))).getSingle();

  test('new quick entries go to the end, and reorder, rename and delete stick', () async {
    final milk = await quickEntries.add(label: ' Milk ', amountMinor: 3200);
    final tea = await quickEntries.add(label: 'Tea', amountMinor: 1500);
    final auto = await quickEntries.add(label: 'Auto');
    expect(await labels(), ['Milk', 'Tea', 'Auto']);

    await quickEntries.reorder([auto, milk, tea]);
    expect(await labels(), ['Auto', 'Milk', 'Tea']);

    await quickEntries.rename(tea, 'Chai');
    await quickEntries.delete(milk);
    expect(await labels(), ['Auto', 'Chai']);
    expect(await quickEntries.find(milk), isNull);
    expect((await quickEntries.find(auto))!.amountMinor, isNull);
  });

  group('entryFromQuickEntry', () {
    Future<QuickEntry> saved({int? amountMinor = 3200, String? categoryId, String? accountId}) async => (await quickEntries.find(await quickEntries.add(
          label: 'Milk',
          amountMinor: amountMinor,
          categoryId: categoryId,
          accountId: accountId,
          payee: 'Gwala Ji',
          tags: 'home',
        )))!;

    test('copies the amount, category, payee and tags into a new expense now', () async {
      final accounts = await db.select(db.accounts).get();
      final food = await seeded('food');
      final entry = entryFromQuickEntry(await saved(categoryId: food.id, accountId: accounts.single.id),
          accounts: accounts, category: food, configuredAccountId: '', now: now, id: 'entry-1')!;
      expect(entry.id.value, 'entry-1');
      expect(entry.amountMinor.value, 3200);
      expect(entry.kind.value, 'expense');
      expect(entry.categoryId.value, food.id);
      expect(entry.accountId.value, accounts.single.id);
      expect(entry.payee.value, 'Gwala Ji');
      expect(entry.tags.value, 'home');
      expect(entry.occurredAt.value, now);
    });

    test('falls back to the default account when its own is gone', () async {
      final accounts = await db.select(db.accounts).get();
      final entry = entryFromQuickEntry(await saved(accountId: 'deleted-account'), accounts: accounts, category: null, configuredAccountId: '', now: now, id: 'entry-1')!;
      expect(entry.accountId.value, accounts.single.id);
    });

    test('drops a category that is archived or of another kind', () async {
      final accounts = await db.select(db.accounts).get();
      final salary = await seeded('salary');
      final food = (await seeded('food')).copyWith(isArchived: true);
      for (final category in [salary, food]) {
        final entry = entryFromQuickEntry(await saved(categoryId: category.id), accounts: accounts, category: category, configuredAccountId: '', now: now, id: 'entry-1')!;
        expect(entry.categoryId.value, isNull, reason: category.name);
      }
    });

    test('gives nothing without an amount or without any account', () async {
      final accounts = await db.select(db.accounts).get();
      expect(entryFromQuickEntry(await saved(amountMinor: null), accounts: accounts, category: null, configuredAccountId: '', now: now, id: 'entry-1'), isNull);
      expect(entryFromQuickEntry(await saved(), accounts: const [], category: null, configuredAccountId: '', now: now, id: 'entry-1'), isNull);
    });
  });

  test('quick entries survive a backup round trip', () async {
    final id = await quickEntries.add(label: 'Milk', amountMinor: 3200, tags: 'home');
    final payload = await BackupService(db).snapshot();

    final fresh = AppDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);
    await BackupService(fresh).importSnapshot(payload);
    final restored = await QuickEntriesRepository(fresh).find(id);
    expect(restored?.label, 'Milk');
    expect(restored?.amountMinor, 3200);
    expect(restored?.tags, 'home');
  });
}

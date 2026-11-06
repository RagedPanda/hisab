import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/entries_repository.dart';
import 'package:hisab/data/repositories/quick_entries_repository.dart';
import 'package:hisab/data/repositories/tags_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late EntriesRepository entries;
  late QuickEntriesRepository quickEntries;
  late TagsRepository tags;
  final longAgo = DateTime(2026, 1, 1);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    entries = EntriesRepository(db);
    quickEntries = QuickEntriesRepository(db);
    tags = TagsRepository(db);
  });

  tearDown(() => db.close());

  Future<void> seed(String id, String tagsText) => entries.saveEntry(
        EntriesRepository.newExpense(id: id, amountMinor: 100, occurredAt: DateTime(2026, 10, 1)).copyWith(tags: Value(tagsText)),
      );

  Future<Entry> entry(String id) => (db.select(db.entries)..where((t) => t.id.equals(id))).getSingle();

  /// Backdates every entry so a test can see which ones an edit touched.
  Future<void> backdateAll() => db.update(db.entries).write(EntriesCompanion(updatedAt: Value(longAgo)));

  test('counts every live entry\'s tags, ignoring deleted entries', () async {
    await seed('a', 'trip, food');
    await seed('b', 'Food');
    await seed('c', 'food');
    await seed('gone', 'trip');
    await entries.deleteEntry('gone');
    expect(await tags.watchTagCounts().first, [(tag: 'food', count: 3), (tag: 'trip', count: 1)]);
  });

  test('rename touches only the entries carrying the tag, in one go, and stamps them for sync', () async {
    await seed('a', 'goa, food');
    await seed('b', '#Goa #trip');
    await seed('c', 'food');
    await backdateAll();

    final before = await tags.renameTag('goa', 'Goa 2026');
    expect(((await entry('a')).tags, (await entry('b')).tags, (await entry('c')).tags), ('Goa 2026, food', 'Goa 2026, trip', 'food'));
    expect((await entry('a')).updatedAt.isAfter(longAgo), isTrue);
    expect((await entry('c')).updatedAt, longAgo, reason: 'untouched rows keep their stamp');
    expect(before.entries, {'a': 'goa, food', 'b': '#Goa #trip'});
  });

  test('renaming onto an existing tag merges without duplicates', () async {
    await seed('a', 'goa, trip');
    await seed('b', 'Trip');
    await seed('c', 'goa');
    await tags.renameTag('goa', 'trip');
    expect(((await entry('a')).tags, (await entry('b')).tags, (await entry('c')).tags), ('trip', 'Trip', 'trip'));
    expect(await tags.watchTagCounts().first, [(tag: 'trip', count: 3)]);
  });

  test('delete removes the tag and keeps the entries; restore puts it back', () async {
    await seed('a', 'trip, food');
    await seed('b', 'TRIP');
    final before = await tags.deleteTag('trip');
    expect(((await entry('a')).tags, (await entry('b')).tags, (await entry('a')).deletedAt), ('food', '', null));

    await backdateAll();
    await tags.restore(before);
    expect(((await entry('a')).tags, (await entry('b')).tags), ('trip, food', 'TRIP'));
    expect((await entry('b')).updatedAt.isAfter(longAgo), isTrue, reason: 'the undo syncs too');
  });

  test('quick entries follow the edit, so a chip never brings the old tag back', () async {
    final quickId = await quickEntries.add(label: 'Beach shack', tags: 'goa, food');
    final before = await tags.renameTag('goa', 'beach');
    expect((await quickEntries.find(quickId))!.tags, 'beach, food');
    expect(before.quickEntries, {quickId: 'goa, food'});

    await tags.deleteTag('food');
    expect((await quickEntries.find(quickId))!.tags, 'beach');
  });

  test('an edit that fails part way leaves nothing changed', () async {
    await seed('a', 'goa');
    await seed('b', 'goa');
    var calls = 0;
    await expectLater(
      db.transaction(() async {
        await tags.renameTag('goa', 'beach');
        calls++;
        throw StateError('boom');
      }),
      throwsStateError,
    );
    expect(calls, 1);
    expect(((await entry('a')).tags, (await entry('b')).tags), ('goa', 'goa'));
  });
}

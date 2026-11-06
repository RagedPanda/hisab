import 'package:drift/drift.dart';

import '../../domain/entries/tag_edits.dart';
import '../db/database.dart';

/// Tags text as it was on each row a tag edit changed, by row id, so the
/// edit can be undone.
typedef TagsBefore = ({Map<String, String> entries, Map<String, String> quickEntries});

/// Tags across the user's data: what is in use, and renaming, merging and
/// removing a tag everywhere. Entries and quick entries both carry tags, so
/// an edit covers both and a quick entry never brings an old tag back. Every
/// changed row gets a new `updatedAt`, so the edit reaches backups and
/// restores like any other edit.
class TagsRepository {
  TagsRepository(this.db);
  final AppDatabase db;

  /// Every tag on a live entry, with how many entries carry it.
  Stream<List<TagCount>> watchTagCounts() {
    final query = db.selectOnly(db.entries)
      ..addColumns([db.entries.tags])
      ..where(db.entries.deletedAt.isNull() & db.entries.tags.equals('').not());
    return query.watch().map((rows) => countTags([for (final row in rows) row.read(db.entries.tags)!]));
  }

  /// Renames [from] to [to] everywhere, merging into [to] where a row
  /// already has it (see [withTagRenamed]).
  Future<TagsBefore> renameTag(String from, String to) => _rewrite((raw) => withTagRenamed(raw, from, to));

  /// Removes [tag] everywhere; the rows themselves stay.
  Future<TagsBefore> deleteTag(String tag) => _rewrite((raw) => withoutTag(raw, tag));

  /// Puts back the tags text a [renameTag] or [deleteTag] replaced.
  Future<void> restore(TagsBefore before) => db.transaction(() async {
        final now = DateTime.now();
        for (final MapEntry(key: id, value: tags) in before.entries.entries) {
          await (db.update(db.entries)..where((t) => t.id.equals(id))).write(EntriesCompanion(tags: Value(tags), updatedAt: Value(now)));
        }
        for (final MapEntry(key: id, value: tags) in before.quickEntries.entries) {
          await (db.update(db.quickEntries)..where((t) => t.id.equals(id))).write(QuickEntriesCompanion(tags: Value(tags), updatedAt: Value(now)));
        }
      });

  Future<TagsBefore> _rewrite(String Function(String raw) edit) => db.transaction(() async {
        final now = DateTime.now();
        final entries = await (db.select(db.entries)..where((t) => t.deletedAt.isNull() & t.tags.equals('').not())).get();
        final quickEntries = await (db.select(db.quickEntries)..where((t) => t.deletedAt.isNull() & t.tags.equals('').not())).get();
        final entriesBefore = <String, String>{};
        final quickBefore = <String, String>{};
        for (final entry in entries) {
          final edited = edit(entry.tags);
          if (edited == entry.tags) continue;
          entriesBefore[entry.id] = entry.tags;
          await (db.update(db.entries)..where((t) => t.id.equals(entry.id))).write(EntriesCompanion(tags: Value(edited), updatedAt: Value(now)));
        }
        for (final quick in quickEntries) {
          final edited = edit(quick.tags);
          if (edited == quick.tags) continue;
          quickBefore[quick.id] = quick.tags;
          await (db.update(db.quickEntries)..where((t) => t.id.equals(quick.id))).write(QuickEntriesCompanion(tags: Value(edited), updatedAt: Value(now)));
        }
        return (entries: entriesBefore, quickEntries: quickBefore);
      });
}

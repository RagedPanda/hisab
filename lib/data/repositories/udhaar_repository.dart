import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../domain/ledger/balance_effects.dart';
import '../../domain/udhaar/udhaar.dart';
import '../db/database.dart';
import 'accounts_repository.dart';
import 'entries_repository.dart';
import 'entry_removal.dart';

/// What the udhaar form saves: one lent, borrowed or repaid amount.
typedef UdhaarDraft = ({
  String personId,
  String personName,
  UdhaarKind kind,
  int amountMinor,
  DateTime occurredAt,
  String? accountId,
  String note,
});

/// Udhaar entries (see `domain/udhaar/udhaar.dart`): one-sided transfers with
/// a person, so they move an account balance but never count as spending.
class UdhaarRepository {
  UdhaarRepository(this.db);
  final AppDatabase db;

  late final EntriesRepository _entries = EntriesRepository(db);
  late final AccountsRepository _accounts = AccountsRepository(db);

  SimpleSelectStatement<$EntriesTable, Entry> _live() =>
      db.select(db.entries)..where((t) => t.deletedAt.isNull() & t.personId.isNotNull() & t.udhaarKind.isNotNull());

  /// Every live udhaar entry, for balances.
  Stream<List<UdhaarLine>> watchLines() => _live().watch().map((rows) => [for (final row in rows) ?udhaarLineOf(row)]);

  /// [personId]'s udhaar entries, newest first.
  Stream<List<Entry>> watchPersonEntries(String personId) => (_live()
        ..where((t) => t.personId.equals(personId))
        ..orderBy([(t) => OrderingTerm.desc(t.occurredAt), (t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  /// The live udhaar entry [id], or null.
  Future<Entry?> getEntry(String id) => (_live()..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Saves [draft] as entry [id] (a new one when null) and moves the account
  /// balance by the difference from what the entry was before. Returns the id.
  Future<String> save(UdhaarDraft draft, {String? id}) async {
    final previous = id == null ? null : await getEntry(id);
    final entryId = id ?? newId();
    final accounts = udhaarAccounts(draft.kind, draft.accountId);
    final entry = EntriesCompanion.insert(
      id: entryId,
      kind: 'transfer',
      amountMinor: draft.amountMinor,
      occurredAt: draft.occurredAt,
      accountId: Value(accounts.from),
      toAccountId: Value(accounts.to),
      payee: Value(draft.personName.trim()),
      note: Value(draft.note.trim()),
      personId: Value(draft.personId),
      udhaarKind: Value(draft.kind.storageKey),
    );
    await _entries.saveEntry(entry);
    await _accounts.applyBalanceDeltas(editDeltas(
      previous: previous == null ? null : snapshotOfEntry(previous),
      next: EntrySnapshot(kind: 'transfer', amountMinor: draft.amountMinor, accountId: accounts.from, toAccountId: accounts.to),
    ));
    return entryId;
  }

  /// Deletes entry [id] and gives its amount back to the account.
  Future<void> delete(String id) => deleteEntryReversingBalances(entries: _entries, accounts: _accounts, entryId: id);

  /// Brings back entry [id] after [delete] and moves its amount out again.
  Future<void> restore(String id) async {
    final row = await (db.select(db.entries)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null || row.deletedAt == null) return;
    await (db.update(db.entries)..where((t) => t.id.equals(id))).write(EntriesCompanion(deletedAt: const Value(null), updatedAt: Value(DateTime.now())));
    await _accounts.applyBalanceDeltas(postingDeltas(snapshotOfEntry(row)));
  }

  /// The UPI ID the user gave themselves in any group, to suggest when the
  /// udhaar reminder first asks for one; null when there is none.
  Future<String?> myGroupUpiId() async {
    final row = await (db.select(db.members)
          ..where((t) => t.isMe.equals(true) & t.deletedAt.isNull() & t.upiId.isNotNull())
          ..limit(1))
        .getSingleOrNull();
    return row?.upiId;
  }

  /// Renames [personId]'s udhaar entries, which carry the name as their payee
  /// so lists and search show it.
  Future<void> renamePerson(String personId, String name) =>
      (db.update(db.entries)..where((t) => t.personId.equals(personId) & t.udhaarKind.isNotNull()))
          .write(EntriesCompanion(payee: Value(name.trim()), updatedAt: Value(DateTime.now())));
}

/// [row] as an udhaar line, or null when it is not an udhaar entry.
UdhaarLine? udhaarLineOf(Entry row) {
  final kind = UdhaarKind.parse(row.udhaarKind);
  final personId = row.personId;
  if (kind == null || personId == null) return null;
  return (personId: personId, kind: kind, amountMinor: row.amountMinor, occurredAt: row.occurredAt);
}

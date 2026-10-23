import '../../domain/ledger/balance_effects.dart';
import '../db/database.dart';
import 'accounts_repository.dart';
import 'entries_repository.dart';

/// The balance-relevant fields of a stored [entry].
EntrySnapshot snapshotOfEntry(Entry entry) => EntrySnapshot(
      kind: entry.kind,
      amountMinor: entry.amountMinor,
      accountId: entry.accountId,
      toAccountId: entry.toAccountId,
      source: entry.source,
      groupId: entry.groupId,
    );

/// Deletes entry [entryId] (with its splits, so group balances drop it) and
/// reverses its effect on account balances: a full undo of having posted it.
/// Does nothing when the entry is already gone.
Future<void> deleteEntryReversingBalances({
  required EntriesRepository entries,
  required AccountsRepository accounts,
  required String entryId,
}) async {
  final details = await entries.getEntry(entryId);
  if (details == null || details.entry.deletedAt != null) return;
  await entries.deleteEntry(entryId);
  await accounts.applyBalanceDeltas(deleteDeltas(snapshotOfEntry(details.entry)));
}

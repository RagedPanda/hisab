/// How an entry moves account balances. Pure: the editor and repositories
/// apply the deltas returned here; nothing in this file touches I/O.
///
/// Rules:
/// * expense  -> debit the account
/// * income   -> credit the account
/// * transfer -> debit the from-account, credit the to-account
/// * SMS entries never move balances (the bank already reported the balance)
/// * group expenses never move balances (they are a ledger between people)
library;

/// The fields of an entry that decide its balance effect.
class EntrySnapshot {
  const EntrySnapshot({
    required this.kind,
    required this.amountMinor,
    this.accountId,
    this.toAccountId,
    this.source = 'manual',
    this.groupId,
  });

  final String kind;
  final int amountMinor;
  final String? accountId;
  final String? toAccountId;
  final String source;
  final String? groupId;

  bool get movesBalances => source != 'sms' && groupId == null;
}

/// Account id -> signed delta caused by posting [entry].
Map<String, int> postingDeltas(EntrySnapshot entry) {
  if (!entry.movesBalances || entry.amountMinor == 0) return const {};
  final account = entry.accountId;
  final deltas = <String, int>{};
  switch (entry.kind) {
    case 'expense':
      if (account != null) deltas[account] = -entry.amountMinor;
    case 'income':
      if (account != null) deltas[account] = entry.amountMinor;
    case 'transfer':
      if (account != null) _add(deltas, account, -entry.amountMinor);
      if (entry.toAccountId != null) _add(deltas, entry.toAccountId!, entry.amountMinor);
  }
  return _withoutZeros(deltas);
}

/// Deltas that undo a previously posted [entry].
Map<String, int> reversalDeltas(EntrySnapshot entry) =>
    {for (final e in postingDeltas(entry).entries) e.key: -e.value};

/// Net deltas for replacing [previous] (null when creating) with [next].
Map<String, int> editDeltas({EntrySnapshot? previous, required EntrySnapshot next}) {
  final merged = <String, int>{};
  if (previous != null) reversalDeltas(previous).forEach((id, delta) => _add(merged, id, delta));
  postingDeltas(next).forEach((id, delta) => _add(merged, id, delta));
  return _withoutZeros(merged);
}

/// Net deltas for deleting a posted [previous] entry.
Map<String, int> deleteDeltas(EntrySnapshot previous) => reversalDeltas(previous);

void _add(Map<String, int> deltas, String id, int delta) => deltas[id] = (deltas[id] ?? 0) + delta;

Map<String, int> _withoutZeros(Map<String, int> deltas) => {for (final e in deltas.entries) if (e.value != 0) e.key: e.value};

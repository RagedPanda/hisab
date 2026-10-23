/// Balances and debt simplification for a group. Pure functions.
library;

import 'split_calculator.dart';

/// One expense in a group ledger: who paid how much, and what each member owes.
class LedgerExpense {
  /// One member paid the whole bill: the sum of the shares.
  LedgerExpense({required String paidByMemberId, required this.shares}) : payers = [SplitShare(paidByMemberId, _sumOf(shares))];

  /// Several members chipped in; their amounts add up to the bill.
  const LedgerExpense.multi({required this.payers, required this.shares});

  /// Who paid and how much.
  final List<SplitShare> payers;
  final List<SplitShare> shares;

  static int _sumOf(List<SplitShare> amounts) => amounts.fold(0, (sum, amount) => sum + amount.amountMinor);

  /// What each member is up or down on this expense alone (paid minus share).
  Map<String, int> get netByMember {
    final net = <String, int>{};
    for (final payer in payers) {
      net.update(payer.memberId, (value) => value + payer.amountMinor, ifAbsent: () => payer.amountMinor);
    }
    for (final share in shares) {
      net.update(share.memberId, (value) => value - share.amountMinor, ifAbsent: () => -share.amountMinor);
    }
    return net;
  }
}

/// A payment from one member to another that settles debt.
class LedgerSettlement {
  const LedgerSettlement({
    required this.fromMemberId,
    required this.toMemberId,
    required this.amountMinor,
  });
  final String fromMemberId;
  final String toMemberId;
  final int amountMinor;
}

/// A suggested or recorded transfer: [from] pays [to].
class Transfer {
  const Transfer(this.from, this.to, this.amountMinor);
  final String from;
  final String to;
  final int amountMinor;

  @override
  String toString() => '$from->$to:$amountMinor';

  @override
  bool operator ==(Object other) =>
      other is Transfer &&
      other.from == from &&
      other.to == to &&
      other.amountMinor == amountMinor;

  @override
  int get hashCode => Object.hash(from, to, amountMinor);
}

/// Net position per member. Positive = the group owes them; negative = they owe.
Map<String, int> computeNetBalances({
  required Iterable<String> memberIds,
  required List<LedgerExpense> expenses,
  required List<LedgerSettlement> settlements,
}) {
  final net = {for (final id in memberIds) id: 0};
  void add(String id, int delta) => net.update(id, (v) => v + delta, ifAbsent: () => delta);

  for (final expense in expenses) {
    expense.netByMember.forEach(add);
  }
  for (final s in settlements) {
    add(s.fromMemberId, s.amountMinor);
    add(s.toMemberId, -s.amountMinor);
  }
  return net;
}

/// Minimal set of transfers that zeroes every balance (greedy largest
/// creditor vs largest debtor). This is Splitwise's "simplify debts".
List<Transfer> simplifyDebts(Map<String, int> net) {
  final creditors = net.entries.where((e) => e.value > 0).map((e) => [e.key, e.value]).toList();
  final debtors = net.entries.where((e) => e.value < 0).map((e) => [e.key, -e.value]).toList();
  int byAmountThenId(List<Object> a, List<Object> b) {
    final cmp = (b[1] as int).compareTo(a[1] as int);
    return cmp != 0 ? cmp : (a[0] as String).compareTo(b[0] as String);
  }

  creditors.sort(byAmountThenId);
  debtors.sort(byAmountThenId);

  final transfers = <Transfer>[];
  var ci = 0;
  var di = 0;
  while (ci < creditors.length && di < debtors.length) {
    final credit = creditors[ci][1] as int;
    final debt = debtors[di][1] as int;
    final amount = credit < debt ? credit : debt;
    transfers.add(Transfer(debtors[di][0] as String, creditors[ci][0] as String, amount));
    creditors[ci][1] = credit - amount;
    debtors[di][1] = debt - amount;
    if (creditors[ci][1] == 0) ci++;
    if (debtors[di][1] == 0) di++;
  }
  return transfers;
}

/// Direct pairwise debts without simplification: within every expense the
/// members who are down pay the members who are up (with one payer, each
/// sharer owes the payer their share); settlements reduce the debt.
List<Transfer> pairwiseDebts({
  required List<LedgerExpense> expenses,
  required List<LedgerSettlement> settlements,
}) {
  // key "a|b" with a < b lexicographically; value > 0 means a owes b.
  final owed = <String, int>{};
  void add(String from, String to, int amount) {
    if (from == to || amount == 0) return;
    final ordered = from.compareTo(to) < 0;
    final key = ordered ? '$from|$to' : '$to|$from';
    final signed = ordered ? amount : -amount;
    owed.update(key, (v) => v + signed, ifAbsent: () => signed);
  }

  for (final expense in expenses) {
    for (final transfer in simplifyDebts(expense.netByMember)) {
      add(transfer.from, transfer.to, transfer.amountMinor);
    }
  }
  for (final s in settlements) {
    add(s.fromMemberId, s.toMemberId, -s.amountMinor);
  }
  final result = <Transfer>[];
  for (final entry in owed.entries) {
    if (entry.value == 0) continue;
    final ids = entry.key.split('|');
    result.add(entry.value > 0
        ? Transfer(ids[0], ids[1], entry.value)
        : Transfer(ids[1], ids[0], -entry.value));
  }
  result.sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
  return result;
}

/// A member can leave a group only once nothing is owed to or by them:
/// their net is zero and no outstanding transfer names them. With
/// simplification off a member can net to zero while still sitting in the
/// middle of two pairwise debts, so the net alone is not enough.
bool isMemberSettled({required String memberId, required Map<String, int> net, required List<Transfer> transfers}) =>
    (net[memberId] ?? 0) == 0 && transfers.every((t) => t.from != memberId && t.to != memberId);

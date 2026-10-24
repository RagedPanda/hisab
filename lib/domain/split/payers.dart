/// Several members paying one group expense. Pure functions.
library;

import 'split_calculator.dart';

/// Payer rows worth storing, in the given order: members who put in
/// nothing are dropped.
List<SplitShare> payersFrom(Map<String, int> amountByMember) => [
      for (final MapEntry(key: memberId, value: amount) in amountByMember.entries)
        if (amount > 0) SplitShare(memberId, amount),
    ];

/// What the payers still have to cover of [totalMinor]; negative when they
/// put in more than the bill.
int unassignedMinor(int totalMinor, Iterable<SplitShare> payers) =>
    totalMinor - payers.fold(0, (sum, payer) => sum + payer.amountMinor);

/// The member who put in the most (the first one on a tie). Kept on the
/// entry as its main payer so single-payer readers keep working.
String? primaryPayerId(List<SplitShare> payers) {
  SplitShare? top;
  for (final payer in payers) {
    if (top == null || payer.amountMinor > top.amountMinor) top = payer;
  }
  return top?.memberId;
}

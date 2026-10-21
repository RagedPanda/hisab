/// Totals across groups from per-group net balances (positive = owed to me). Pure.
library;

({int owedToMe, int iOwe}) groupNetTotals(Iterable<int> nets) {
  var owedToMe = 0;
  var iOwe = 0;
  for (final net in nets) {
    if (net > 0) owedToMe += net;
    if (net < 0) iOwe -= net;
  }
  return (owedToMe: owedToMe, iOwe: iOwe);
}

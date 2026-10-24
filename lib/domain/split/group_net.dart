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

/// What I am owed and owe in one currency, never mixed with another.
typedef CurrencyTotals = ({String symbol, int owedToMe, int iOwe});

/// Totals per currency from per-group net balances, each tagged with the
/// symbol its group is shown in. Amounts in different currencies are never
/// added together. The [appSymbol] total always comes first (zero when no
/// group uses it); other currencies follow in symbol order. Pure.
List<CurrencyTotals> groupNetTotalsByCurrency(Iterable<({String symbol, int net})> nets, {required String appSymbol}) {
  final netsBySymbol = <String, List<int>>{appSymbol: []};
  for (final entry in nets) {
    netsBySymbol.putIfAbsent(entry.symbol, () => []).add(entry.net);
  }
  final otherSymbols = netsBySymbol.keys.where((symbol) => symbol != appSymbol).toList()..sort();
  return [
    for (final symbol in [appSymbol, ...otherSymbols])
      () {
        final totals = groupNetTotals(netsBySymbol[symbol]!);
        return (symbol: symbol, owedToMe: totals.owedToMe, iOwe: totals.iOwe);
      }(),
  ];
}

/// One side of the summary ("owed to me" or "I owe"): the first (app
/// currency) amount always, others only when non-zero, so a single-currency
/// list shows exactly one amount. Pure.
List<({String symbol, int minor})> summarySideAmounts(List<CurrencyTotals> totals, {required bool owedToMe}) => [
      for (final (index, total) in totals.indexed)
        if (index == 0 || (owedToMe ? total.owedToMe : total.iOwe) != 0) (symbol: total.symbol, minor: owedToMe ? total.owedToMe : total.iOwe),
    ];

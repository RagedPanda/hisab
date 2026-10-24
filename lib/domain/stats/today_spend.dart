/// "Today" on the Home summary card. Pure.
library;

import '../../core/dates.dart';
import '../ledger/personal_totals.dart';
import 'spend_series.dart';

/// What I spent today: expense lines from local midnight up to the next one,
/// counted with the same rules as the month's spend (my share of group
/// entries, transfers and income left out).
///
/// Null when [shownRange] (the month the card shows) does not contain [now],
/// because "today" does not belong on a past or future month.
int? todaySpendMinor({required Iterable<LedgerLine> lines, required DateRange shownRange, required DateTime now}) {
  if (!shownRange.contains(now)) return null;
  return totalsByKind(linesWithin(lines, dayRange(now))).expense;
}

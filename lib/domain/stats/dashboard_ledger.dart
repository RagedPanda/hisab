/// The ledger window the dashboard works from: the trailing month ranges and
/// every line inside them, kept together so a card derived from one emission
/// never labels one month's figures with another month's name.
library;

import '../../core/dates.dart';
import '../ledger/personal_totals.dart';

class DashboardLedger {
  const DashboardLedger({required this.ranges, required this.lines});

  /// Oldest first; the last range is the selected month.
  final List<DateRange> ranges;
  final List<LedgerLine> lines;

  DateRange get range => ranges.last;
  DateRange get previousRange => ranges[ranges.length - 2];
}

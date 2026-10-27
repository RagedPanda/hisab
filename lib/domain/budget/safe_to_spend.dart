/// "Safe to spend per day" for Home: what is left of the overall monthly
/// budget spread over the days left in the cycle. Pure.
library;

import '../../core/dates.dart';
import 'budget_math.dart';

class SafeToSpend {
  const SafeToSpend({required this.perDayMinor, required this.overByMinor, required this.daysLeft});

  /// Whole minor units per day; 0 once the budget is used up.
  final int perDayMinor;

  /// How far spend has gone past the budget; 0 when within it.
  final int overByMinor;

  /// Days left in the cycle, today included.
  final int daysLeft;

  bool get isOver => overByMinor > 0;
}

/// (budget − spent) ÷ days left in [cycle], today included, rounded down so
/// following it never tips the month over. Null without a monthly budget
/// ([limitMinor] null) or when [cycle] is not the one containing [now].
SafeToSpend? safeToSpend({required int? limitMinor, required int spentMinor, required DateRange cycle, required DateTime now}) {
  if (limitMinor == null || !cycle.contains(now)) return null;
  final progress = BudgetProgress(limitMinor: limitMinor, spentMinor: spentMinor, elapsedFraction: 0);
  final daysLeft = daysLeftInPeriod(end: cycle.end, now: now);
  final remaining = progress.remainingMinor;
  return SafeToSpend(
    perDayMinor: remaining <= 0 || daysLeft == 0 ? 0 : remaining ~/ daysLeft,
    overByMinor: progress.isOver ? -remaining : 0,
    daysLeft: daysLeft,
  );
}

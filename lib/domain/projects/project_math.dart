/// Roll-ups for a project: what it has cost so far, by category and by
/// month, and how that compares with its budget. Pure.
library;

import '../../core/dates.dart';
import '../budget/budget_math.dart';
import '../ledger/personal_totals.dart';

/// Lifecycle of a project. Stored in the database by [name].
enum ProjectStatus {
  active,
  completed,
  archived;

  static ProjectStatus parse(String value) => values.firstWhere((status) => status.name == value, orElse: () => ProjectStatus.active);
}

/// Spend of one project, derived from its ledger lines.
class ProjectTotals {
  const ProjectTotals({
    required this.spentMinor,
    required this.incomeMinor,
    required this.byCategory,
    required this.byMonth,
    required this.entryCount,
    this.budget,
  });

  static const empty = ProjectTotals(spentMinor: 0, incomeMinor: 0, byCategory: {}, byMonth: {}, entryCount: 0);

  final int spentMinor;

  /// Money that came back into the project (a refund, a sale), shown but not
  /// netted off the spend so the budget bar stays honest.
  final int incomeMinor;

  /// Expense per category id; entries without a category key on ''.
  final Map<String, int> byCategory;

  /// Expense per month, keyed by the month's first day (see [monthRange]).
  final Map<DateTime, int> byMonth;
  final int entryCount;

  /// Progress against the project budget; null when no budget is set.
  final BudgetProgress? budget;
}

/// Expense total per month of [lines], keyed by the start of the month that
/// contains the entry, honouring the user's month start day.
Map<DateTime, int> expenseByMonth(Iterable<LedgerLine> lines, {int startDay = 1}) {
  final totals = <DateTime, int>{};
  for (final line in lines.where((line) => line.kind == 'expense')) {
    final month = monthRange(line.occurredAt, startDay: startDay).start;
    totals.update(month, (value) => value + line.amountMinor, ifAbsent: () => line.amountMinor);
  }
  return totals;
}

/// How far through a project's planned window [now] is, 0..1. A project with
/// no dates has no pace, so its progress reads as "all time" (fraction 1).
double projectElapsedFraction({DateTime? startDate, DateTime? endDate, required DateTime now}) {
  if (startDate == null || endDate == null) return 1;
  return elapsedFraction(start: startDate, end: endDate, now: now);
}

ProjectTotals projectTotals(
  Iterable<LedgerLine> lines, {
  int? budgetMinor,
  DateTime? startDate,
  DateTime? endDate,
  required DateTime now,
  int startDay = 1,
}) {
  final list = lines.toList();
  final kinds = totalsByKind(list);
  return ProjectTotals(
    spentMinor: kinds.expense,
    incomeMinor: kinds.income,
    byCategory: totalsByCategory(list),
    byMonth: expenseByMonth(list, startDay: startDay),
    entryCount: list.length,
    budget: budgetMinor == null
        ? null
        : BudgetProgress(
            limitMinor: budgetMinor,
            spentMinor: kinds.expense,
            elapsedFraction: projectElapsedFraction(startDate: startDate, endDate: endDate, now: now),
          ),
  );
}

/// Months of a project in order, from its first expense (or [startDate]) to
/// [now] (or [endDate] if it ended earlier), so trend bars show empty months
/// too. Capped at [maxMonths], keeping the most recent.
List<DateTime> projectMonths({
  required Map<DateTime, int> byMonth,
  DateTime? startDate,
  DateTime? endDate,
  required DateTime now,
  int startDay = 1,
  int maxMonths = 24,
}) {
  final firstSpend = byMonth.keys.fold<DateTime?>(null, (earliest, month) => earliest == null || month.isBefore(earliest) ? month : earliest);
  final firstCandidates = [if (startDate != null) monthRange(startDate, startDay: startDay).start, ?firstSpend];
  if (firstCandidates.isEmpty) return const [];
  final first = firstCandidates.reduce((a, b) => a.isBefore(b) ? a : b);
  final lastAnchor = endDate != null && endDate.isBefore(now) ? endDate : now;
  final lastSpend = byMonth.keys.fold<DateTime?>(null, (latest, month) => latest == null || month.isAfter(latest) ? month : latest);
  var last = monthRange(lastAnchor, startDay: startDay).start;
  if (lastSpend != null && lastSpend.isAfter(last)) last = lastSpend;
  final months = <DateTime>[];
  var cursor = first;
  while (!cursor.isAfter(last)) {
    months.add(cursor);
    cursor = monthRange(DateTime(cursor.year, cursor.month + 1, cursor.day), startDay: startDay).start;
  }
  return months.length > maxMonths ? months.sublist(months.length - maxMonths) : months;
}

/// Order for project lists: active first, then completed, then archived;
/// within a status the most recently updated first.
int compareProjects({required ProjectStatus statusA, required DateTime updatedA, required ProjectStatus statusB, required DateTime updatedB}) {
  final byStatus = statusA.index.compareTo(statusB.index);
  return byStatus != 0 ? byStatus : updatedB.compareTo(updatedA);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/budget/budget_math.dart';
import 'package:hisab/domain/ledger/personal_totals.dart';
import 'package:hisab/domain/projects/project_math.dart';

LedgerLine _expense(int amount, DateTime at, {String? category}) => LedgerLine(kind: 'expense', amountMinor: amount, occurredAt: at, categoryId: category);

void main() {
  final now = DateTime(2026, 10, 21, 12);
  final lines = [
    _expense(300000, DateTime(2026, 8, 3), category: 'fuel'),
    _expense(120000, DateTime(2026, 9, 14), category: 'vehicle_service'),
    _expense(250000, DateTime(2026, 10, 2), category: 'fuel'),
    LedgerLine(kind: 'income', amountMinor: 50000, occurredAt: DateTime(2026, 10, 10)),
  ];

  group('projectTotals', () {
    test('sums spend, splits by category and by month, counts entries', () {
      final totals = projectTotals(lines, now: now);
      expect(totals.spentMinor, 670000);
      expect(totals.incomeMinor, 50000);
      expect(totals.byCategory, {'fuel': 550000, 'vehicle_service': 120000});
      expect(totals.byMonth, {DateTime(2026, 8, 1): 300000, DateTime(2026, 9, 1): 120000, DateTime(2026, 10, 1): 250000});
      expect(totals.entryCount, 4);
      expect(totals.budget, isNull);
    });

    test('month buckets follow the month start day', () {
      final totals = projectTotals(lines, now: now, startDay: 5);
      expect(totals.byMonth, {DateTime(2026, 7, 5): 300000, DateTime(2026, 9, 5): 370000});
    });

    test('budget progress paces by the project window when dates are set', () {
      final totals = projectTotals(lines, budgetMinor: 1000000, startDate: DateTime(2026, 8, 1), endDate: DateTime(2026, 12, 1), now: DateTime(2026, 10, 1));
      final budget = totals.budget!;
      expect(budget.spentMinor, 670000);
      expect(budget.remainingMinor, 330000);
      expect(budget.elapsedFraction, closeTo(0.5, 0.01));
      expect(budget.band, BudgetBand.onTrack);
    });

    test('budget without dates has no pace and reads as all-time', () {
      final totals = projectTotals(lines, budgetMinor: 600000, now: now);
      expect(totals.budget!.elapsedFraction, 1);
      expect(totals.budget!.isOver, isTrue);
      expect(totals.budget!.band, BudgetBand.over);
    });

    test('empty project is all zeros', () {
      final totals = projectTotals(const [], now: now, budgetMinor: 1000);
      expect(totals.spentMinor, 0);
      expect(totals.byCategory, isEmpty);
      expect(totals.byMonth, isEmpty);
      expect(totals.budget!.usedPercent, 0);
    });
  });

  group('projectMonths', () {
    test('runs from the first spend to the current month including gaps', () {
      final months = projectMonths(byMonth: {DateTime(2026, 7, 1): 100, DateTime(2026, 9, 1): 100}, now: now);
      expect(months, [DateTime(2026, 7, 1), DateTime(2026, 8, 1), DateTime(2026, 9, 1), DateTime(2026, 10, 1)]);
    });

    test('starts at the project start date when that is earlier', () {
      final months = projectMonths(byMonth: {DateTime(2026, 9, 1): 100}, startDate: DateTime(2026, 8, 15), now: now);
      expect(months.first, DateTime(2026, 8, 1));
      expect(months.last, DateTime(2026, 10, 1));
    });

    test('stops at the end date of a finished project', () {
      final months = projectMonths(byMonth: {DateTime(2026, 3, 1): 100}, endDate: DateTime(2026, 5, 20), now: now);
      expect(months, [DateTime(2026, 3, 1), DateTime(2026, 4, 1), DateTime(2026, 5, 1)]);
    });

    test('is empty without dates or spend, and keeps the most recent months when capped', () {
      expect(projectMonths(byMonth: const {}, now: now), isEmpty);
      final capped = projectMonths(byMonth: {DateTime(2024, 1, 1): 100}, now: now, maxMonths: 3);
      expect(capped, [DateTime(2026, 8, 1), DateTime(2026, 9, 1), DateTime(2026, 10, 1)]);
    });
  });

  group('ordering and status', () {
    test('active before completed before archived, newest first within a status', () {
      final older = DateTime(2026, 1, 1);
      final newer = DateTime(2026, 6, 1);
      expect(compareProjects(statusA: ProjectStatus.completed, updatedA: newer, statusB: ProjectStatus.active, updatedB: older), greaterThan(0));
      expect(compareProjects(statusA: ProjectStatus.archived, updatedA: newer, statusB: ProjectStatus.completed, updatedB: older), greaterThan(0));
      expect(compareProjects(statusA: ProjectStatus.active, updatedA: newer, statusB: ProjectStatus.active, updatedB: older), lessThan(0));
    });

    test('unknown stored status falls back to active', () {
      expect(ProjectStatus.parse('completed'), ProjectStatus.completed);
      expect(ProjectStatus.parse('garbage'), ProjectStatus.active);
    });
  });

  group('dashboard and chart shapes', () {
    test('month totals fill gaps with zero and honour the month start day', () {
      final bars = projectMonthTotals({DateTime(2026, 8, 5): 500}, [DateTime(2026, 7, 5), DateTime(2026, 8, 5)], startDay: 5);
      expect(bars.map((bar) => bar.expense), [0, 500]);
      expect(bars.last.range.start, DateTime(2026, 8, 5));
      expect(bars.last.range.end, DateTime(2026, 9, 5));
    });

    test('active rows skip completed and archived and count the overflow', () {
      final statuses = [ProjectStatus.active, ProjectStatus.completed, ProjectStatus.active, ProjectStatus.active, ProjectStatus.archived, ProjectStatus.active];
      final rows = activeProjectRows(statuses, statusOf: (status) => status, max: 3);
      expect(rows.shown, [ProjectStatus.active, ProjectStatus.active, ProjectStatus.active]);
      expect(rows.more, 1);
      expect(activeProjectRows([ProjectStatus.completed], statusOf: (status) => status).shown, isEmpty);
    });
  });
}

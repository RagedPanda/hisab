import 'package:drift/drift.dart';

import '../../core/salary_settings.dart';
import '../../domain/recurring/recurrence.dart';
import '../../domain/salary/salary_schedule.dart';
import '../db/database.dart';
import '../repositories/recurring_repository.dart';

/// I/O edge for the salary-day rule: creates the recurring income rule,
/// loads recent incomes and settles the waiting occurrence once the salary
/// is seen. All decisions are in `lib/domain/salary`.
class SalaryService {
  SalaryService(this.db) : recurring = RecurringRepository(db);
  final AppDatabase db;
  final RecurringRepository recurring;

  /// The seeded Salary income category, if the user still has it.
  Future<String?> salaryCategoryId() async {
    final row = await (db.select(db.categories)
          ..where((t) => t.seedKey.equals('salary') & t.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    return row?.id;
  }

  /// Creates or updates the monthly salary income rule. Confirm-first, so the
  /// salary is never counted before it actually arrives; [reconcile] settles
  /// the occurrence when a matching income shows up. Returns the rule id.
  Future<String> saveSalaryRule({
    required SalarySettings settings,
    required String name,
    required DateTime today,
    int monthStartDay = 1,
  }) async {
    final rule = RecurringRepository.newRule(
      id: settings.ruleId.isEmpty ? null : settings.ruleId,
      name: name,
      kind: 'income',
      amountMinor: settings.amountMinor,
      categoryId: await salaryCategoryId(),
      accountId: settings.accountId,
      frequency: RecurrenceFrequency.monthly,
      dayOfMonth: settings.salaryDay,
      startDate: DateTime(today.year, today.month, today.day, 9),
      autoPost: false,
    );
    return recurring.saveRule(rule, monthStartDay: monthStartDay);
  }

  /// Ends the salary rule when the user removes the salary setup.
  Future<void> removeSalaryRule(String ruleId) => recurring.delete(ruleId);

  SimpleSelectStatement<$EntriesTable, Entry> _incomesSince(DateTime since) =>
      db.select(db.entries)..where((t) => t.kind.equals('income') & t.deletedAt.isNull() & t.occurredAt.isBiggerOrEqualValue(since));

  static List<IncomeCandidate> _candidates(List<Entry> rows) => [
        for (final row in rows)
          IncomeCandidate(id: row.id, occurredAt: row.occurredAt, amountMinor: row.amountMinor, accountId: row.accountId, recurringId: row.recurringId),
      ];

  /// Income entries since [since], as salary candidates.
  Future<List<IncomeCandidate>> recentIncomes(DateTime since) async => _candidates(await _incomesSince(since).get());

  /// Live version of [recentIncomes]: emits again whenever an income is
  /// added, edited or deleted (including SMS-added entries).
  Stream<List<IncomeCandidate>> watchRecentIncomes(DateTime since) => _incomesSince(since).watch().map(_candidates);

  /// Evaluates the current pay cycle and, when the salary arrived on its own
  /// (SMS or a hand-typed entry), links it to the rule and consumes the
  /// rule's waiting occurrence so it is not offered for confirmation again.
  Future<SalaryStatus?> reconcile(SalarySettings settings, {required DateTime now, int monthStartDay = 1}) async {
    if (!settings.isSetUp) return null;
    final status = settings.evaluate(now: now, incomes: await recentIncomes(salaryLookbackStart(now)));
    final rule = await recurring.getRule(settings.ruleId);
    if (rule != null && rule.deletedAt == null && shouldClaimSalaryOccurrence(status, ruleNextDue: rule.nextDue, ruleId: rule.id, windowDays: clampSalaryMatchWindowDays(settings.matchWindowDays))) {
      await db.transaction(() async {
        await recurring.linkEntry(status.received!.id, rule.id);
        await recurring.skipNext(rule.id, monthStartDay: monthStartDay);
      });
    }
    return status;
  }
}


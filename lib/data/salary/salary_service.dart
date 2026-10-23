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
  /// the occurrence when a matching income shows up. The rule is named
  /// [kSalaryRuleName] (lists translate it) and its due date carries the
  /// weekend and holiday shift. A new rule, or a changed salary day, starts
  /// from [today] and nothing before it counts as late; any other edit keeps
  /// the rule's due date and waiting occurrence. Returns [settings] with the
  /// rule's id, anchor and start, ready to save.
  Future<SalarySettings> saveSalaryRule({
    required SalarySettings settings,
    required DateTime today,
    int monthStartDay = 1,
  }) async {
    final existing = settings.ruleId.isEmpty ? null : await recurring.getRule(settings.ruleId);
    final live = existing != null && existing.deletedAt == null ? existing : null;
    final categoryId = await salaryCategoryId();
    if (live != null && !shouldRestartSalaryRule(ruleDay: live.dayOfMonth, salaryDay: settings.salaryDay)) {
      return _updateSalaryRule(live, settings, categoryId: categoryId);
    }
    final draft = RecurringRepository.newRule(
      id: live?.id,
      name: kSalaryRuleName,
      kind: 'income',
      amountMinor: settings.amountMinor,
      categoryId: categoryId,
      accountId: settings.accountId,
      frequency: RecurrenceFrequency.monthly,
      dayOfMonth: settings.salaryDay,
      startDate: DateTime(today.year, today.month, today.day, 9),
      autoPost: false,
    );
    final ruleId = await recurring.saveRule(draft, monthStartDay: monthStartDay);
    final rule = await recurring.getRule(ruleId);
    final nextDue = rule?.nextDue;
    final anchor = nextDue == null ? null : salaryRuleAnchorFor(nextDue, postedCount: rule!.postedCount, salaryDay: settings.salaryDay);
    final saved = settings.copyWith(ruleId: ruleId, ruleAnchor: anchor, trackedSince: DateTime(today.year, today.month, today.day));
    if (rule != null) await _alignDue(saved, rule);
    // A shift can pull the first cycle before today (day 31 set up on a
    // Saturday the 31st is due Friday the 30th); that cycle is not tracked,
    // so the rule must not wait for it either.
    final aligned = await recurring.getRule(ruleId);
    final firstDue = aligned?.nextDue;
    if (firstDue != null && isBeforeSalaryTracking(firstDue, trackedSince: saved.trackedSince)) {
      await recurring.skipNext(ruleId, monthStartDay: monthStartDay);
      final advanced = await recurring.getRule(ruleId);
      if (advanced != null) await _alignDue(saved, advanced);
    }
    return saved;
  }

  /// Applies an edit that keeps the schedule: amount, account and category
  /// change, the due date and lifetime count stay, and the due date only
  /// moves if the weekend or holiday shift changed.
  Future<SalarySettings> _updateSalaryRule(RecurringRule rule, SalarySettings settings, {required String? categoryId}) async {
    await (db.update(db.recurringRules)..where((t) => t.id.equals(rule.id))).write(RecurringRulesCompanion(
          name: const Value(kSalaryRuleName),
          amountMinor: Value(settings.amountMinor),
          categoryId: Value(categoryId),
          accountId: Value(settings.accountId),
          updatedAt: Value(DateTime.now()),
        ));
    final nextDue = rule.nextDue;
    final anchor = settings.ruleAnchor ?? (nextDue == null ? null : salaryRuleAnchorFor(nextDue, postedCount: rule.postedCount, salaryDay: settings.salaryDay));
    final saved = settings.copyWith(ruleId: rule.id, ruleAnchor: anchor);
    await _alignDue(saved, rule);
    return saved;
  }

  /// Moves the rule's due date onto its pay cycle's shifted date (the
  /// recurring engine only knows the unshifted day of month). The cycle uses
  /// the rule's own day, so a setup out of step with its rule cannot move
  /// the rule onto a day it does not repeat on.
  Future<void> _alignDue(SalarySettings settings, RecurringRule rule) async {
    final stored = rule.nextDue;
    if (stored == null) return;
    final ruleDay = rule.dayOfMonth;
    final aligned = alignedSalaryRuleDue(
      stored,
      postedCount: rule.postedCount,
      salaryDay: ruleDay != null && ruleDay > 0 ? ruleDay : settings.salaryDay,
      anchor: settings.ruleAnchor,
      shift: settings.shift,
      holidays: settings.holidaySet,
    );
    if (aligned == stored) return;
    await (db.update(db.recurringRules)..where((t) => t.id.equals(rule.id))).write(RecurringRulesCompanion(nextDue: Value(aligned)));
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
    final stored = await recurring.getRule(settings.ruleId);
    if (stored == null || stored.deletedAt != null) return status;
    // Confirming or skipping in the recurring list steps the unshifted date.
    await _alignDue(settings, stored);
    final rule = (await recurring.getRule(stored.id))!;
    if (shouldClaimSalaryOccurrence(status, ruleNextDue: rule.nextDue, ruleId: rule.id, windowDays: clampSalaryMatchWindowDays(settings.matchWindowDays))) {
      await db.transaction(() async {
        await recurring.linkEntry(status.received!.id, rule.id);
        await recurring.skipNext(rule.id, monthStartDay: monthStartDay);
        final advanced = await recurring.getRule(rule.id);
        if (advanced != null) await _alignDue(settings, advanced);
      });
    }
    return status;
  }
}


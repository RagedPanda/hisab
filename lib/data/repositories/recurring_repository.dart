import 'package:drift/drift.dart';

import '../../core/dates.dart';
import '../../core/ids.dart';
import '../../domain/ledger/balance_effects.dart';
import '../../domain/recurring/catch_up_schedule.dart';
import '../../domain/recurring/recurrence.dart';
import '../../domain/recurring/repeat_draft.dart';
import '../db/database.dart';
import 'accounts_repository.dart';

export '../../domain/recurring/repeat_draft.dart' show RecurringStatus;

/// A rule with the rows its list tile shows.
class RecurringRuleView {
  const RecurringRuleView({required this.rule, this.category, this.account, this.toAccount});
  final RecurringRule rule;
  final Category? category;
  final Account? account;
  final Account? toAccount;
}

/// The schedule part of a stored rule, for the pure maths in `lib/domain/recurring`.
RecurrenceSpec specOf(RecurringRule rule) => RecurrenceSpec(
      frequency: RecurrenceFrequency.parse(rule.frequency),
      interval: rule.interval,
      start: rule.startDate,
      dayOfMonth: rule.dayOfMonth,
      weekday: rule.weekday,
      endDate: rule.endDate,
      maxCount: rule.maxCount,
    );

/// Same as [specOf] for a rule that has not been written yet.
RecurrenceSpec specOfCompanion(RecurringRulesCompanion rule) => RecurrenceSpec(
      frequency: RecurrenceFrequency.parse(rule.frequency.value),
      interval: rule.interval.present ? rule.interval.value : 1,
      start: rule.startDate.value,
      dayOfMonth: rule.dayOfMonth.present ? rule.dayOfMonth.value : null,
      weekday: rule.weekday.present ? rule.weekday.value : null,
      endDate: rule.endDate.present ? rule.endDate.value : null,
      maxCount: rule.maxCount.present ? rule.maxCount.value : null,
    );

/// Id of the entry a rule posts for the occurrence on [occurrence]'s day.
/// Deterministic, so posting the same occurrence twice is a no-op.
String occurrenceEntryId(String ruleId, DateTime occurrence) =>
    stableId('recurring:$ruleId:${occurrence.year}-${occurrence.month}-${occurrence.day}');

/// The entry a rule produces for one occurrence.
EntriesCompanion entryForOccurrence(RecurringRule rule, DateTime occurrence) => EntriesCompanion.insert(
      id: occurrenceEntryId(rule.id, occurrence),
      kind: rule.kind,
      amountMinor: rule.amountMinor,
      currency: Value(rule.currency),
      occurredAt: occurrence,
      categoryId: Value(rule.kind == 'transfer' ? null : rule.categoryId),
      accountId: Value(rule.accountId),
      toAccountId: Value(rule.kind == 'transfer' ? rule.toAccountId : null),
      note: Value(rule.note),
      payee: Value(rule.payee),
      projectId: Value(rule.kind == 'transfer' ? null : rule.projectId),
      source: const Value('recurring'),
      recurringId: Value(rule.id),
    );

class RecurringRepository {
  RecurringRepository(this.db);
  final AppDatabase db;

  late final $AccountsTable _toAccounts = db.alias(db.accounts, 'rule_to_accounts');

  JoinedSelectStatement<HasResultSet, dynamic> _viewsQuery() => db.select(db.recurringRules).join([
        leftOuterJoin(db.categories, db.categories.id.equalsExp(db.recurringRules.categoryId) & db.categories.deletedAt.isNull()),
        leftOuterJoin(db.accounts, db.accounts.id.equalsExp(db.recurringRules.accountId)),
        leftOuterJoin(_toAccounts, _toAccounts.id.equalsExp(db.recurringRules.toAccountId)),
      ])
        ..where(db.recurringRules.deletedAt.isNull())
        ..orderBy([OrderingTerm.asc(db.recurringRules.nextDue), OrderingTerm.asc(db.recurringRules.name)]);

  List<RecurringRuleView> _toViews(List<TypedResult> rows) => [
        for (final row in rows)
          RecurringRuleView(
            rule: row.readTable(db.recurringRules),
            category: row.readTableOrNull(db.categories),
            account: row.readTableOrNull(db.accounts),
            toAccount: row.readTableOrNull(_toAccounts),
          ),
      ];

  /// Every live rule, soonest due first; the UI groups them by status.
  Stream<List<RecurringRuleView>> watchViews() => _viewsQuery().watch().map(_toViews);

  Future<List<RecurringRuleView>> getViews() async => _toViews(await _viewsQuery().get());

  Future<RecurringRule?> getRule(String id) => (db.select(db.recurringRules)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Inserts or replaces a rule, deriving its next due date from the
  /// schedule. [postedOn] is the date of an entry the user just saved as the
  /// rule's first occurrence; when it is on schedule it counts as posted.
  /// An edited rule keeps its lifetime count and restarts from its start date.
  Future<String> saveRule(RecurringRulesCompanion rule, {int monthStartDay = 1, DateTime? postedOn}) async {
    final id = rule.id.present ? rule.id.value : newId();
    final existing = await getRule(id);
    final spec = specOfCompanion(rule);
    var postedCount = existing?.postedCount ?? 0;
    var nextDue = firstOnOrAfter(spec, spec.start, monthStartDay: monthStartDay);
    if (postedOn != null && isSameDay(nextDue, postedOn)) {
      postedCount++;
      nextDue = nextAfter(spec, nextDue, monthStartDay: monthStartDay);
    }
    final allowed = allowsOccurrence(spec, nextDue, postedCount: postedCount);
    final requested = rule.status.present ? rule.status.value : (existing?.status ?? RecurringStatus.active);
    final status = !allowed ? RecurringStatus.ended : (requested == RecurringStatus.ended ? RecurringStatus.active : requested);
    await db.into(db.recurringRules).insertOnConflictUpdate(rule.copyWith(
          id: Value(id),
          postedCount: Value(postedCount),
          skippedCount: Value(existing?.skippedCount ?? 0),
          nextDue: Value(allowed ? nextDue : null),
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ));
    return id;
  }

  /// Links an entry to the rule it started.
  Future<void> linkEntry(String entryId, String ruleId) => (db.update(db.entries)..where((t) => t.id.equals(entryId)))
      .write(EntriesCompanion(recurringId: Value(ruleId), updatedAt: Value(DateTime.now())));

  Future<void> setStatus(String id, String status) => (db.update(db.recurringRules)..where((t) => t.id.equals(id)))
      .write(RecurringRulesCompanion(status: Value(status), updatedAt: Value(DateTime.now())));

  /// Pauses or resumes. A resumed rule picks up from today: occurrences that
  /// fell due while it was paused are skipped, not back-posted.
  Future<void> setPaused(String id, bool paused, {required DateTime now, int monthStartDay = 1}) async {
    final rule = await getRule(id);
    if (rule == null || rule.status == RecurringStatus.ended) return;
    if (paused) return setStatus(id, RecurringStatus.paused);
    final spec = specOf(rule);
    var nextDue = rule.nextDue ?? firstOnOrAfter(spec, now, monthStartDay: monthStartDay);
    if (startOfDay(nextDue).isBefore(startOfDay(now))) nextDue = firstOnOrAfter(spec, now, monthStartDay: monthStartDay);
    final allowed = allowsOccurrence(spec, nextDue, postedCount: rule.postedCount);
    await (db.update(db.recurringRules)..where((t) => t.id.equals(id))).write(RecurringRulesCompanion(
          status: Value(allowed ? RecurringStatus.active : RecurringStatus.ended),
          nextDue: Value(allowed ? nextDue : null),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> delete(String id) => (db.update(db.recurringRules)..where((t) => t.id.equals(id)))
      .write(RecurringRulesCompanion(deletedAt: Value(DateTime.now()), updatedAt: Value(DateTime.now())));

  Future<void> restore(String id) => (db.update(db.recurringRules)..where((t) => t.id.equals(id)))
      .write(RecurringRulesCompanion(deletedAt: const Value(null), updatedAt: Value(DateTime.now())));

  /// Posts every due occurrence of active auto-post rules up to [now],
  /// catching up missed ones. Idempotent: entry ids are derived from the rule
  /// and the day, so running twice (start and resume racing) posts once.
  /// Returns how many entries were written.
  Future<int> postDue({required DateTime now, int monthStartDay = 1}) => db.transaction(() async {
        final rules = await (db.select(db.recurringRules)
              ..where((t) => t.deletedAt.isNull() & t.status.equals(RecurringStatus.active) & t.autoPost.equals(true) & t.nextDue.isSmallerOrEqualValue(now)))
            .get();
        var written = 0;
        for (final rule in rules) {
          final spec = specOf(rule);
          final due = dueOccurrences(spec, nextDue: rule.nextDue!, now: now, postedCount: rule.postedCount, monthStartDay: monthStartDay);
          for (final occurrence in due) {
            if (await _post(rule, occurrence)) written++;
          }
          await _advance(rule, consumed: due.length, monthStartDay: monthStartDay);
        }
        return written;
      });

  /// One foreground catch-up: posts what is due at [now] and returns when the
  /// open app should run the next one.
  Future<DateTime> catchUp({required DateTime now, int monthStartDay = 1}) async {
    await postDue(now: now, monthStartDay: monthStartDay);
    return nextWake(now: now);
  }

  /// When an open app should next run [postDue]: see [nextWakeAt].
  Future<DateTime> nextWake({required DateTime now}) async {
    final rules = await (db.select(db.recurringRules)..where((t) => t.deletedAt.isNull())).get();
    return nextWakeAt([for (final rule in rules) (status: rule.status, nextDue: rule.nextDue)], now);
  }

  /// Posts the oldest waiting occurrence of a confirm-first rule.
  Future<String?> confirmNext(String id, {int monthStartDay = 1}) => db.transaction(() async {
        final rule = await getRule(id);
        if (rule == null || rule.nextDue == null) return null;
        await _post(rule, rule.nextDue!);
        await _advance(rule, consumed: 1, monthStartDay: monthStartDay);
        return occurrenceEntryId(rule.id, rule.nextDue!);
      });

  /// Skips the oldest waiting occurrence without posting it.
  Future<void> skipNext(String id, {int monthStartDay = 1}) => db.transaction(() async {
        final rule = await getRule(id);
        if (rule == null || rule.nextDue == null) return;
        await _advance(rule, consumed: 1, skipped: 1, monthStartDay: monthStartDay);
      });

  /// Writes the entry for one occurrence unless it already exists, and moves
  /// account balances the way a hand-typed entry would.
  Future<bool> _post(RecurringRule rule, DateTime occurrence) async {
    final entry = entryForOccurrence(rule, occurrence);
    final exists = await (db.select(db.entries)..where((t) => t.id.equals(entry.id.value))).getSingleOrNull();
    if (exists != null) return false;
    await db.into(db.entries).insert(entry);
    final snapshot = EntrySnapshot(kind: rule.kind, amountMinor: rule.amountMinor, accountId: rule.accountId, toAccountId: rule.kind == 'transfer' ? rule.toAccountId : null, source: 'recurring');
    await AccountsRepository(db).applyBalanceDeltas(postingDeltas(snapshot));
    return true;
  }

  Future<void> _advance(RecurringRule rule, {required int consumed, int skipped = 0, required int monthStartDay}) async {
    final next = advance(specOf(rule), nextDue: rule.nextDue!, postedCount: rule.postedCount, consumed: consumed, monthStartDay: monthStartDay);
    await (db.update(db.recurringRules)..where((t) => t.id.equals(rule.id))).write(RecurringRulesCompanion(
          nextDue: Value(next.nextDue),
          postedCount: Value(next.postedCount),
          skippedCount: skipped == 0 ? const Value.absent() : Value(rule.skippedCount + skipped),
          status: next.nextDue == null ? const Value(RecurringStatus.ended) : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ));
  }

  /// A new rule built from the fields of an entry template.
  static RecurringRulesCompanion newRule({
    String? id,
    String name = '',
    required String kind,
    required int amountMinor,
    String? categoryId,
    String? accountId,
    String? toAccountId,
    String? payee,
    String? projectId,
    String note = '',
    required RecurrenceFrequency frequency,
    int interval = 1,
    int? dayOfMonth,
    int? weekday,
    required DateTime startDate,
    DateTime? endDate,
    int? maxCount,
    bool autoPost = true,
    bool isSubscription = false,
    String remindDaysBefore = '',
  }) =>
      RecurringRulesCompanion.insert(
        id: id ?? newId(),
        name: Value(name),
        kind: kind,
        amountMinor: amountMinor,
        categoryId: Value(categoryId),
        accountId: Value(accountId),
        toAccountId: Value(toAccountId),
        payee: Value(payee),
        projectId: Value(projectId),
        note: Value(note),
        frequency: frequency.name,
        interval: Value(interval),
        dayOfMonth: Value(dayOfMonth),
        weekday: Value(weekday),
        startDate: startDate,
        endDate: Value(endDate),
        maxCount: Value(maxCount),
        autoPost: Value(autoPost),
        isSubscription: Value(isSubscription),
        remindDaysBefore: Value(remindDaysBefore),
      );
}

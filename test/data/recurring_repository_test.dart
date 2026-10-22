import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/backup/backup_service.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/accounts_repository.dart';
import 'package:hisab/data/repositories/recurring_repository.dart';
import 'package:hisab/domain/recurring/recurrence.dart';

void main() {
  late AppDatabase db;
  late RecurringRepository recurring;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    recurring = RecurringRepository(db);
  });

  tearDown(() => db.close());

  Future<List<Entry>> recurringEntries() =>
      (db.select(db.entries)..where((t) => t.source.equals('recurring'))..orderBy([(t) => OrderingTerm.asc(t.occurredAt)])).get();

  RecurringRulesCompanion rent({String? accountId, int? maxCount, bool autoPost = true, DateTime? start}) => RecurringRepository.newRule(
        name: 'Rent',
        kind: 'expense',
        amountMinor: 1500000,
        accountId: accountId,
        frequency: RecurrenceFrequency.monthly,
        dayOfMonth: 5,
        startDate: start ?? DateTime(2026, 7, 5, 9),
        maxCount: maxCount,
        autoPost: autoPost,
      );

  test('saveRule sets the first due date and counts an on-schedule first entry', () async {
    final id = await recurring.saveRule(rent(), postedOn: DateTime(2026, 7, 5, 18));
    final rule = (await recurring.getRule(id))!;
    expect(rule.postedCount, 1);
    expect(rule.nextDue, DateTime(2026, 8, 5, 9));
    expect(rule.status, RecurringStatus.active);
  });

  test('saveRule does not count an entry dated off the schedule', () async {
    final id = await recurring.saveRule(rent(), postedOn: DateTime(2026, 7, 3));
    final rule = (await recurring.getRule(id))!;
    expect(rule.postedCount, 0);
    expect(rule.nextDue, DateTime(2026, 7, 5, 9));
  });

  test('postDue catches up every missed month once and moves the balance', () async {
    final account = await AccountsRepository(db).create(name: 'Salary account', type: 'bank', color: 1, balanceMinor: 10000000);
    final id = await recurring.saveRule(rent(accountId: account.id));

    final written = await recurring.postDue(now: DateTime(2026, 10, 6));
    expect(written, 4);
    final posted = await recurringEntries();
    expect(posted.map((entry) => entry.occurredAt.month), [7, 8, 9, 10]);
    expect(posted.every((entry) => entry.recurringId == id), isTrue);
    final rule = (await recurring.getRule(id))!;
    expect(rule.nextDue, DateTime(2026, 11, 5, 9));
    expect(rule.postedCount, 4);
    final balance = (await AccountsRepository(db).getAll()).firstWhere((row) => row.id == account.id).balanceMinor;
    expect(balance, 10000000 - 4 * 1500000);

    expect(await recurring.postDue(now: DateTime(2026, 10, 6)), 0, reason: 'running again posts nothing');
    expect((await recurringEntries()).length, 4);
  });

  test('postDue is idempotent even when the rule pointer is stale', () async {
    final id = await recurring.saveRule(rent());
    await recurring.postDue(now: DateTime(2026, 7, 6));
    await (db.update(db.recurringRules)..where((t) => t.id.equals(id))).write(RecurringRulesCompanion(nextDue: Value(DateTime(2026, 7, 5, 9))));
    expect(await recurring.postDue(now: DateTime(2026, 7, 6)), 0);
    expect((await recurringEntries()).length, 1);
  });

  test('postDue leaves confirm-first and paused rules alone', () async {
    await recurring.saveRule(rent(autoPost: false));
    final paused = await recurring.saveRule(rent());
    await recurring.setPaused(paused, true, now: DateTime(2026, 7, 1));
    expect(await recurring.postDue(now: DateTime(2026, 9, 1)), 0);
  });

  test('a rule ends after maxCount occurrences', () async {
    final id = await recurring.saveRule(rent(maxCount: 2));
    await recurring.postDue(now: DateTime(2027, 1, 1));
    expect((await recurringEntries()).length, 2);
    final rule = (await recurring.getRule(id))!;
    expect(rule.status, RecurringStatus.ended);
    expect(rule.nextDue, isNull);
  });

  test('confirmNext posts the oldest waiting occurrence; skipNext drops one without posting', () async {
    final id = await recurring.saveRule(rent(autoPost: false));
    final entryId = await recurring.confirmNext(id);
    expect(entryId, occurrenceEntryId(id, DateTime(2026, 7, 5, 9)));
    await recurring.skipNext(id);
    final rule = (await recurring.getRule(id))!;
    expect(rule.nextDue, DateTime(2026, 9, 5, 9));
    expect(rule.postedCount, 2, reason: 'a skipped occurrence still uses one of the repeat count');
    expect((await recurringEntries()).length, 1);
  });

  test('resuming skips occurrences missed while paused', () async {
    final id = await recurring.saveRule(rent());
    await recurring.setPaused(id, true, now: DateTime(2026, 7, 1));
    await recurring.setPaused(id, false, now: DateTime(2026, 10, 10));
    final rule = (await recurring.getRule(id))!;
    expect(rule.status, RecurringStatus.active);
    expect(rule.nextDue, DateTime(2026, 11, 5, 9));
  });

  test('a deleted rule is hidden and restorable', () async {
    final id = await recurring.saveRule(rent());
    await recurring.delete(id);
    expect(await recurring.getViews(), isEmpty);
    await recurring.restore(id);
    expect((await recurring.getViews()).single.rule.id, id);
  });

  test('linkEntry tags the entry that started a rule', () async {
    final id = await recurring.saveRule(rent());
    await recurring.postDue(now: DateTime(2026, 7, 6));
    final entry = (await recurringEntries()).single;
    await (db.update(db.entries)..where((t) => t.id.equals(entry.id))).write(const EntriesCompanion(recurringId: Value(null)));
    await recurring.linkEntry(entry.id, id);
    expect((await recurringEntries()).single.recurringId, id);
  });

  test('backup snapshot includes recurring rules and restores them', () async {
    final id = await recurring.saveRule(rent());
    final payload = await BackupService(db).snapshot();
    expect((payload['recurringRules'] as List).single['name'], 'Rent');

    final fresh = AppDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);
    await BackupService(fresh).importSnapshot(payload);
    final restored = await RecurringRepository(fresh).getRule(id);
    expect(restored?.nextDue, DateTime(2026, 7, 5, 9));
  });
}

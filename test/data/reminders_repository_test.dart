import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/backup/backup_service.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/reminders_repository.dart';
import 'package:hisab/domain/reminders/reminder_draft.dart';
import 'package:hisab/domain/reminders/reminder_kind.dart';

void main() {
  late AppDatabase db;
  late RemindersRepository reminders;
  var now = DateTime(2026, 10, 22, 10);

  setUp(() {
    now = DateTime(2026, 10, 22, 10);
    db = AppDatabase(NativeDatabase.memory());
    reminders = RemindersRepository(db, clock: () => now);
  });

  tearDown(() => db.close());

  ReminderDraft rent({String? id, ReminderRepeat repeat = ReminderRepeat.monthly, DateTime? due}) => ReminderDraft(
        id: id,
        kind: ReminderKind.bill,
        title: ' Rent ',
        amountMinor: 2500000,
        dueAt: due ?? DateTime(2026, 10, 31, 18),
        repeat: repeat,
        remindDaysBefore: const [0, 3],
        matchKeywords: 'Landlord|NEFT',
      );

  test('save stores a normalised row and update keeps the id', () async {
    final id = await reminders.save(rent());
    var row = (await reminders.getById(id))!;
    expect(row.title, 'Rent');
    expect(row.dueAt, DateTime(2026, 10, 31));
    expect(row.repeatDay, 31);
    expect(row.remindDaysBefore, '3,0');
    expect(row.matchKeywords, 'landlord|neft');
    expect(row.status, ReminderStatus.pending);
    expect(row.notifyAtMinute, 540);

    await reminders.snooze(id, DateTime(2026, 10, 23));
    await reminders.save(rent(id: id, repeat: ReminderRepeat.yearly));
    row = (await reminders.getById(id))!;
    expect(row.repeat, 'yearly');
    expect(row.snoozedUntil, isNull, reason: 'editing the timing clears a snooze');
    expect(await reminders.getUpcoming(), hasLength(1));
  });

  test('upcoming lists pending due reminders by due date and skips settle-up rows', () async {
    await db.into(db.reminders).insert(RemindersCompanion.insert(id: 's1', kind: 'settle_up', dueAt: Value(DateTime(2026, 10, 1))));
    final late = await reminders.save(rent(due: DateTime(2026, 12, 1)));
    final soon = await reminders.save(rent(due: DateTime(2026, 10, 20)));
    expect((await reminders.getUpcoming()).map((r) => r.id), [soon, late]);
    expect((await reminders.getUpcoming(until: DateTime(2026, 11, 5))).map((r) => r.id), [soon]);
    expect(await reminders.getById('s1'), isNull);
  });

  test('markDone closes a repeating reminder, links the entry and spawns the next month', () async {
    final id = await reminders.save(rent(due: DateTime(2026, 1, 31)));
    final nextId = await reminders.markDone(id, entryId: 'e1');
    final closed = await (db.select(db.reminders)..where((t) => t.id.equals(id))).getSingle();
    expect(closed.status, ReminderStatus.done);
    expect(closed.entryId, 'e1');
    expect(closed.doneAt, now);
    expect(closed.nextId, nextId);
    final next = (await reminders.getById(nextId!))!;
    expect(next.dueAt, DateTime(2026, 2, 28));
    expect(next.title, 'Rent');
    expect(next.status, ReminderStatus.pending);
    expect(next.entryId, isNull);
    expect((await reminders.getUpcoming()).map((r) => r.id), [nextId]);

    // Feb 28 rolls back to the 31st in March.
    final march = await reminders.markDone(nextId);
    expect((await reminders.getById(march!))!.dueAt, DateTime(2026, 3, 31));
  });

  test('markDone on a one-off spawns nothing; a closed reminder is not closed twice', () async {
    final id = await reminders.save(rent(repeat: ReminderRepeat.once));
    expect(await reminders.markDone(id), isNull);
    expect(await reminders.getUpcoming(), isEmpty);
    expect(await reminders.markDone(id), isNull);
    expect(await reminders.watchHistory().first, hasLength(1));
  });

  test('skip spawns the next occurrence and is listed in history as skipped', () async {
    final id = await reminders.save(rent(due: DateTime(2026, 10, 31)));
    final nextId = await reminders.skip(id);
    expect((await reminders.getById(nextId!))!.dueAt, DateTime(2026, 11, 30));
    final history = await reminders.watchHistory().first;
    expect(history.single.status, ReminderStatus.skipped);
  });

  test('undoDone reopens the reminder and removes the spawned occurrence', () async {
    final id = await reminders.save(rent());
    final nextId = await reminders.markDone(id, entryId: 'e1');
    expect(await reminders.undoDone(id), nextId);
    final reopened = (await reminders.getById(id))!;
    expect(reopened.status, ReminderStatus.pending);
    expect(reopened.entryId, isNull);
    expect(reopened.nextId, isNull);
    expect(await reminders.getById(nextId!), isNull);
    expect((await reminders.getUpcoming()).map((r) => r.id), [id]);
  });

  test('delete hides and restore brings back', () async {
    final id = await reminders.save(rent());
    await reminders.delete(id);
    expect(await reminders.getUpcoming(), isEmpty);
    await reminders.restore(id);
    expect(await reminders.getUpcoming(), hasLength(1));
  });

  test('getSchedulable skips reminders without a notification time', () async {
    await reminders.save(rent());
    await reminders.save(ReminderDraft(kind: ReminderKind.custom, title: 'Quiet', dueAt: DateTime(2026, 11, 1), notifyAtMinute: null));
    expect((await reminders.getSchedulable()).map((r) => r.title), ['Rent']);
  });

  test('due reminders survive a backup round trip', () async {
    final id = await reminders.save(rent());
    final snapshot = await BackupService(db).snapshot();
    final other = AppDatabase(NativeDatabase.memory());
    addTearDown(other.close);
    await BackupService(other).importSnapshot(snapshot);
    final restored = (await RemindersRepository(other).getById(id))!;
    expect(restored.title, 'Rent');
    expect(restored.amountMinor, 2500000);
    expect(restored.remindDaysBefore, '3,0');
  });

  test('reminderDraftFrom keeps every field so an editor save is lossless', () async {
    final id = await reminders.save(ReminderDraft(
      kind: ReminderKind.card,
      title: 'HDFC card',
      dueAt: DateTime(2026, 11, 5),
      amountMinor: 1234500,
      accountId: 'acc1',
      categoryId: 'cat1',
      recurringId: 'rule1',
      assetId: 'asset1',
      repeat: ReminderRepeat.monthly,
      remindDaysBefore: const [3, 0],
      notifyAtMinute: 600,
      matchKeywords: 'hdfc',
      toleranceMinor: 500,
      notes: 'autopay off',
    ));
    final draft = reminderDraftFrom((await reminders.getById(id))!);
    expect(draft.id, id);
    expect(draft.kind, ReminderKind.card);
    expect(draft.recurringId, 'rule1');
    expect(draft.assetId, 'asset1');
    expect(draft.remindDaysBefore, [3, 0]);
    expect(draft.notifyAtMinute, 600);
    expect(draft.toleranceMinor, 500);
    expect(draft.notes, 'autopay off');
    await reminders.save(draft);
    final again = (await reminders.getById(id))!;
    expect(again.recurringId, 'rule1');
    expect(again.matchKeywords, 'hdfc');
  });

  test('a pre-v6 backup reminder restores with column defaults', () async {
    final legacy = {
      'id': 'old1',
      'kind': 'settle_up',
      'groupId': 'g1',
      'memberId': 'm1',
      'dueAt': DateTime(2026, 10, 1).millisecondsSinceEpoch,
      'channel': 'share',
      'message': 'Pay up',
      'updatedAt': DateTime(2026, 10, 1).millisecondsSinceEpoch,
    };
    final filled = reminderJsonWithDefaults(legacy);
    expect(filled['title'], '');
    expect(filled['status'], ReminderStatus.pending);
    expect(filled['message'], 'Pay up');
    expect(reminderJsonWithDefaults({...legacy, 'title': 'Kept'})['title'], 'Kept');

    final written = await BackupService(db).importSnapshot({'app': 'hisab', 'reminders': [legacy]});
    expect(written, greaterThan(0));
    final row = await (db.select(db.reminders)..where((t) => t.id.equals('old1'))).getSingle();
    expect(row.kind, 'settle_up');
    expect(row.repeat, 'once');
    expect(await reminders.getById('old1'), isNull, reason: 'settle-up rows stay out of due reminders');
  });

  test('ReminderKind.of treats unknown keys as custom', () {
    expect(ReminderKind.of('emi'), ReminderKind.emi);
    expect(ReminderKind.of('mystery'), ReminderKind.custom);
  });

  test('an amount of 0 is stored as no amount (owner decision 23)', () async {
    final id = await reminders.save(ReminderDraft(kind: ReminderKind.bill, title: 'Water', amountMinor: 0, dueAt: DateTime(2026, 11, 2), remindDaysBefore: const [0]));
    expect((await reminders.getById(id))!.amountMinor, isNull);
    expect(reminderAmountOrNone(0), isNull);
    expect(reminderAmountOrNone(null), isNull);
    expect(reminderAmountOrNone(15000), 15000);
  });
}

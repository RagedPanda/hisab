import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../domain/reminders/reminder_draft.dart';
import '../../domain/reminders/reminder_kind.dart';
import '../../domain/reminders/reminder_schedule.dart';
import '../db/database.dart';

/// Due reminders (bills, EMIs, card dues, documents...) on the shared
/// `reminders` table. Settle-up rows written by GroupsRepository are never
/// returned. Notifications are not touched here; ReminderScheduler pairs
/// every write with the matching NotificationService call.
class RemindersRepository {
  RemindersRepository(this.db, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  final AppDatabase db;
  final DateTime Function() _clock;

  Expression<bool> _isLiveDue($RemindersTable t) => t.deletedAt.isNull() & t.kind.isIn(dueReminderKindKeys) & t.dueAt.isNotNull();

  SimpleSelectStatement<$RemindersTable, Reminder> _pending({DateTime? until}) => db.select(db.reminders)
    ..where((t) => _isLiveDue(t) & t.status.equals(ReminderStatus.pending) & (until == null ? const Constant(true) : t.dueAt.isSmallerOrEqualValue(until)))
    ..orderBy([(t) => OrderingTerm.asc(t.dueAt), (t) => OrderingTerm.asc(t.title)]);

  /// Pending reminders, earliest due first (overdue ones lead), optionally only up to [until].
  Stream<List<Reminder>> watchUpcoming({DateTime? until}) => _pending(until: until).watch();
  Future<List<Reminder>> getUpcoming({DateTime? until}) => _pending(until: until).get();

  /// Pending reminders that want a notification; what rescheduleAll posts.
  Future<List<Reminder>> getSchedulable() => (_pending()..where((t) => t.notifyAtMinute.isNotNull())).get();

  /// Paid and skipped reminders, most recent first.
  Stream<List<Reminder>> watchHistory({int limit = 100}) => (db.select(db.reminders)
        ..where((t) => _isLiveDue(t) & t.status.isIn([ReminderStatus.done, ReminderStatus.skipped]))
        ..orderBy([(t) => OrderingTerm.desc(t.doneAt), (t) => OrderingTerm.desc(t.dueAt)])
        ..limit(limit))
      .watch();

  /// Pending reminders linked to [projectId], earliest due first.
  Stream<List<Reminder>> watchForProject(String projectId) => (_pending()..where((t) => t.projectId.equals(projectId))).watch();
  Future<List<Reminder>> getForProject(String projectId) => (_pending()..where((t) => t.projectId.equals(projectId))).get();

  /// What each paid reminder's linked entry actually paid, by reminder id. A
  /// bank SMS within tolerance (₹2,150 on a ₹2,100 bill) or an edited entry
  /// differs from the reminder's amount; History shows the paid one.
  Stream<Map<String, int>> watchPaidAmounts() {
    final query = db.select(db.reminders).join([innerJoin(db.entries, db.entries.id.equalsExp(db.reminders.entryId))])
      ..where(db.reminders.status.equals(ReminderStatus.done) & db.reminders.deletedAt.isNull() & db.entries.deletedAt.isNull());
    return query.watch().map((rows) => {for (final row in rows) row.readTable(db.reminders).id: row.readTable(db.entries).amountMinor});
  }

  Future<Reminder?> getById(String id) => (db.select(db.reminders)..where((t) => t.id.equals(id) & _isLiveDue(t))).getSingleOrNull();
  Stream<Reminder?> watchById(String id) => (db.select(db.reminders)..where((t) => t.id.equals(id) & _isLiveDue(t))).watchSingleOrNull();

  /// Creates or updates a reminder from [draft]; returns its id. Editing keeps
  /// status and history fields but clears a snooze, since the timing changed.
  Future<String> save(ReminderDraft draft) async {
    final id = draft.id ?? newId();
    final now = _clock();
    final fields = RemindersCompanion(
      kind: Value(draft.kind.key),
      title: Value(draft.title.trim()),
      notes: Value(draft.notes.trim()),
      amountMinor: Value(reminderAmountOrNone(draft.amountMinor)),
      toleranceMinor: Value(draft.toleranceMinor),
      matchKeywords: Value(draft.matchKeywords.trim().toLowerCase()),
      categoryId: Value(draft.categoryId),
      accountId: Value(draft.accountId),
      recurringId: Value(draft.recurringId),
      assetId: Value(draft.assetId),
      dueAt: Value(draft.dueDay),
      repeat: Value(draft.repeat.key),
      repeatDay: Value(draft.repeatDay),
      remindDaysBefore: Value(formatRemindDaysBefore(draft.remindDaysBefore)),
      notifyAtMinute: Value(draft.notifyAtMinute),
      projectId: Value(draft.projectId),
      documentNumber: Value(draft.documentNumber.trim()),
      presetKey: Value(draft.presetKey),
      snoozedUntil: const Value(null),
      channel: const Value('notification'),
      updatedAt: Value(now),
    );
    if (draft.id == null) {
      await db.into(db.reminders).insert(fields.copyWith(id: Value(id)));
    } else {
      await (db.update(db.reminders)..where((t) => t.id.equals(id))).write(fields);
    }
    return id;
  }

  /// Closes the reminder as [status] (done or skipped), linking [entryId], and
  /// for repeating reminders inserts the next occurrence. Returns the next
  /// occurrence's id, or null when the reminder does not repeat (or is not pending).
  Future<String?> _close(String id, String status, {String? entryId}) => db.transaction(() async {
        final reminder = await getById(id);
        if (reminder == null || reminder.status != ReminderStatus.pending) return null;
        final now = _clock();
        final nextDue = nextDueDate(reminder.dueAt!, ReminderRepeat.fromKey(reminder.repeat), anchorDay: reminder.repeatDay);
        final nextId = nextDue == null ? null : newId();
        if (nextId != null) {
          await db.into(db.reminders).insert(reminder.copyWith(
                id: nextId,
                dueAt: Value(nextDue),
                status: ReminderStatus.pending,
                doneAt: const Value(null),
                entryId: const Value(null),
                snoozedUntil: const Value(null),
                nextId: const Value(null),
                sentAt: const Value(null),
                updatedAt: now,
              ));
        }
        await (db.update(db.reminders)..where((t) => t.id.equals(id))).write(RemindersCompanion(
              status: Value(status),
              doneAt: Value(now),
              entryId: Value(entryId),
              snoozedUntil: const Value(null),
              nextId: Value(nextId),
              updatedAt: Value(now),
            ));
        return nextId;
      });

  /// Marks the reminder paid (or done, for documents), optionally linked to
  /// the entry that paid it; repeating reminders get their next occurrence.
  Future<String?> markDone(String id, {String? entryId}) => _close(id, ReminderStatus.done, entryId: entryId);

  /// Skips this occurrence; repeating reminders get their next occurrence.
  Future<String?> skip(String id) => _close(id, ReminderStatus.skipped);

  /// Reopens a paid or skipped reminder and removes the occurrence it spawned.
  /// Returns that occurrence's id so its notifications can be cancelled.
  Future<String?> undoDone(String id) => db.transaction(() async {
        final reminder = await getById(id);
        if (reminder == null || reminder.status == ReminderStatus.pending) return null;
        final now = _clock();
        final spawnedId = reminder.nextId;
        if (spawnedId != null) await delete(spawnedId);
        await (db.update(db.reminders)..where((t) => t.id.equals(id))).write(RemindersCompanion(
              status: const Value(ReminderStatus.pending),
              doneAt: const Value(null),
              entryId: const Value(null),
              nextId: const Value(null),
              updatedAt: Value(now),
            ));
        return spawnedId;
      });

  /// Silences the reminder until [until], when it notifies again.
  Future<void> snooze(String id, DateTime until) => (db.update(db.reminders)..where((t) => t.id.equals(id)))
      .write(RemindersCompanion(snoozedUntil: Value(until), updatedAt: Value(_clock())));

  Future<void> delete(String id) => (db.update(db.reminders)..where((t) => t.id.equals(id)))
      .write(RemindersCompanion(deletedAt: Value(_clock()), updatedAt: Value(_clock())));

  /// Reverses a soft delete (undo from the snackbar).
  Future<void> restore(String id) => (db.update(db.reminders)..where((t) => t.id.equals(id)))
      .write(RemindersCompanion(deletedAt: const Value(null), updatedAt: Value(_clock())));
}

/// The editable draft of a stored [reminder], keeping every link a feature
/// set (recurring rule, asset, keywords) so a save from the editor is lossless.
ReminderDraft reminderDraftFrom(Reminder reminder) => ReminderDraft(
      id: reminder.id,
      kind: ReminderKind.of(reminder.kind),
      title: reminder.title,
      dueAt: reminder.dueAt ?? reminder.updatedAt,
      notes: reminder.notes,
      amountMinor: reminder.amountMinor,
      categoryId: reminder.categoryId,
      accountId: reminder.accountId,
      recurringId: reminder.recurringId,
      assetId: reminder.assetId,
      repeat: ReminderRepeat.fromKey(reminder.repeat),
      remindDaysBefore: parseRemindDaysBefore(reminder.remindDaysBefore),
      notifyAtMinute: reminder.notifyAtMinute,
      matchKeywords: reminder.matchKeywords,
      toleranceMinor: reminder.toleranceMinor,
      projectId: reminder.projectId,
      documentNumber: reminder.documentNumber,
      presetKey: reminder.presetKey,
    );

/// Fills the due-reminder fields a pre-v6 (or pre-v7) backup row lacks with their column
/// defaults, so older backups still restore.
Map<String, dynamic> reminderJsonWithDefaults(Map<String, dynamic> json) => {
      'title': '',
      'notes': '',
      'toleranceMinor': 0,
      'matchKeywords': '',
      'repeat': ReminderRepeat.once.key,
      'remindDaysBefore': '0',
      'status': ReminderStatus.pending,
      'documentNumber': '',
      ...json,
    };

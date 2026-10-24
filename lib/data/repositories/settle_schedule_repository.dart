import 'package:drift/drift.dart';

import '../../domain/reminders/reminder_kind.dart';
import '../../domain/split/settle_reminder.dart';
import '../db/database.dart';

/// Notification texts of a scheduled settle-up reminder; null when the group
/// is settled, which keeps the schedule but posts nothing.
typedef SettleReminderText = ({String title, String body});

/// Scheduled settle-up reminders ("remind me to settle with Ravi on the
/// 1st"), one per group, stored as rows of the shared reminders table so the
/// shared NotificationService posts them and backup already covers them.
/// The texts are worked out by the caller (they need the group's balances
/// and the app language) and stored on the row for the alert to show.
class SettleScheduleRepository {
  SettleScheduleRepository(this.db);
  final AppDatabase db;

  SimpleSelectStatement<$RemindersTable, Reminder> _live() =>
      db.select(db.reminders)..where((t) => t.kind.equals(kSettleScheduleKind) & t.deletedAt.isNull());

  /// The live row of reminder [reminderId], if it is a settle-up schedule.
  Future<Reminder?> getRow(String reminderId) => (_live()..where((t) => t.id.equals(reminderId))).getSingleOrNull();

  /// Every group's live schedule row.
  Future<List<Reminder>> liveRows() => _live().get();

  /// Rows that should have an alert posted: pending, timed and not settled.
  Future<List<Reminder>> schedulable() async => [
        for (final row in await liveRows())
          if (isSchedulable(row)) row,
      ];

  static bool isSchedulable(Reminder row) => row.status == ReminderStatus.pending && row.dueAt != null && row.title.isNotEmpty;

  static SettleReminderSchedule? scheduleOfRow(Reminder row) =>
      settleScheduleFromStored(repeat: row.repeat, repeatDay: row.repeatDay, memberId: row.memberId);

  Future<SettleReminderSchedule?> scheduleOf(String groupId) async {
    final row = await getRow(settleScheduleReminderId(groupId));
    return row == null ? null : scheduleOfRow(row);
  }

  Stream<SettleReminderSchedule?> watchSchedule(String groupId) => (_live()..where((t) => t.id.equals(settleScheduleReminderId(groupId))))
      .watchSingleOrNull()
      .map((row) => row == null ? null : scheduleOfRow(row));

  /// Creates or replaces the group's schedule, due next after [now]. Returns the stored row.
  Future<Reminder> save(String groupId, SettleReminderSchedule schedule, {required DateTime now, SettleReminderText? text}) async {
    final id = settleScheduleReminderId(groupId);
    await db.into(db.reminders).insertOnConflictUpdate(RemindersCompanion(
          id: Value(id),
          kind: const Value(kSettleScheduleKind),
          groupId: Value(groupId),
          memberId: Value(schedule.memberId),
          repeat: Value(settleScheduleRepeat(schedule)),
          repeatDay: Value(settleScheduleRepeatDay(schedule)),
          dueAt: Value(nextSettleReminderAt(schedule, now: now)),
          notifyAtMinute: const Value(kSettleReminderHour * 60),
          remindDaysBefore: const Value('0'),
          status: const Value(ReminderStatus.pending),
          snoozedUntil: const Value(null),
          title: Value(text?.title ?? ''),
          notes: Value(text?.body ?? ''),
          updatedAt: Value(now),
          deletedAt: const Value(null),
        ));
    return (await getRow(id))!;
  }

  /// Rolls a row whose reminder has passed on to its next date and stores
  /// fresh [text]. Returns the row as stored; writes nothing when neither changed.
  Future<Reminder> refreshRow(Reminder row, {required DateTime now, SettleReminderText? text}) async {
    final schedule = scheduleOfRow(row);
    final passed = row.dueAt == null || !row.dueAt!.isAfter(now);
    final snoozeOver = row.snoozedUntil == null || !row.snoozedUntil!.isAfter(now);
    final rolls = passed && snoozeOver && schedule != null;
    final unchanged = !rolls && row.title == (text?.title ?? '') && row.notes == (text?.body ?? '') && (row.snoozedUntil == null || !snoozeOver);
    // Nothing to write: keeps watchers of the reminders table from looping.
    if (unchanged) return row;
    await (db.update(db.reminders)..where((t) => t.id.equals(row.id))).write(RemindersCompanion(
          dueAt: rolls ? Value(nextSettleReminderAt(schedule, now: now)) : const Value.absent(),
          snoozedUntil: snoozeOver ? const Value(null) : const Value.absent(),
          title: Value(text?.title ?? ''),
          notes: Value(text?.body ?? ''),
          updatedAt: Value(now),
        ));
    return (await getRow(row.id))!;
  }

  /// Turns the group's schedule off.
  Future<void> remove(String groupId, {required DateTime now}) =>
      (db.update(db.reminders)..where((t) => t.id.equals(settleScheduleReminderId(groupId))))
          .write(RemindersCompanion(deletedAt: Value(now), updatedAt: Value(now)));
}

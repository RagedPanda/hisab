import '../../data/repositories/reminders_repository.dart';
import '../../domain/reminders/reminder_draft.dart';
import '../../domain/reminders/reminder_kind.dart';
import 'notification_service.dart';
import 'reminder_payload.dart';

/// Reminder writes paired with their notifications: every method stores the
/// change through [RemindersRepository] and then brings the posted alerts in
/// line through [NotificationService]. Features that create or change
/// reminders (card dues, documents, salary, SMS matching...) call this, not
/// the repository, so notifications never drift from the table.
class ReminderScheduler {
  ReminderScheduler({
    required this.reminders,
    required this.notifications,
    this.removeEntry,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final RemindersRepository reminders;
  final NotificationService notifications;

  /// Deletes an entry and reverses its balance effect; [undoDone] uses it to
  /// take back the entry that marking paid recorded. Null leaves entries alone.
  final Future<void> Function(String entryId)? removeEntry;
  final DateTime Function() _clock;

  /// Re-posts the alerts of [id] from its stored row (or cancels them when it
  /// is closed or gone). Call after changing a reminder row directly.
  Future<void> refresh(String id) async {
    final reminder = await reminders.getById(id);
    if (reminder == null) {
      await notifications.cancel(id);
    } else {
      await notifications.schedule(reminder);
    }
  }

  /// Creates or updates a reminder and schedules its alerts; returns its id.
  Future<String> save(ReminderDraft draft) async {
    final id = await reminders.save(draft);
    await refresh(id);
    return id;
  }

  /// Marks paid/done (linking [entryId]); repeating reminders roll to their
  /// next due date, which is scheduled. Returns the next occurrence's id.
  Future<String?> markDone(String id, {String? entryId}) async {
    final nextId = await reminders.markDone(id, entryId: entryId);
    await _afterClose(id, nextId);
    return nextId;
  }

  /// Skips this occurrence; repeating reminders roll on like [markDone].
  Future<String?> skip(String id) async {
    final nextId = await reminders.skip(id);
    await _afterClose(id, nextId);
    return nextId;
  }

  /// Reopens a paid or skipped reminder and drops the occurrence it spawned.
  /// A full reversal: the entry recorded when marking it paid is deleted too,
  /// so account and group balances return to what they were.
  Future<void> undoDone(String id) async {
    final closed = await reminders.getById(id);
    final linkedEntryId = closed?.status == ReminderStatus.pending ? null : closed?.entryId;
    final spawnedId = await reminders.undoDone(id);
    if (spawnedId != null) await notifications.cancel(spawnedId);
    if (linkedEntryId != null) await removeEntry?.call(linkedEntryId);
    await refresh(id);
  }

  /// Silences the reminder for [duration] (one day by default); it notifies again then.
  Future<void> snooze(String id, {Duration duration = kSnoozeDuration}) async {
    await reminders.snooze(id, _clock().add(duration));
    await refresh(id);
  }

  Future<void> delete(String id) async {
    await reminders.delete(id);
    await notifications.cancel(id);
  }

  /// Undoes [delete].
  Future<void> restore(String id) async {
    await reminders.restore(id);
    await refresh(id);
  }

  /// Re-posts every pending reminder's alerts. Run on app start (after reboot,
  /// app update or a time-zone change) and after a backup restore.
  Future<int> rescheduleAll() async => notifications.rescheduleAll(await reminders.getSchedulable());

  Future<void> _afterClose(String id, String? nextId) async {
    await notifications.cancel(id);
    if (nextId != null) await refresh(nextId);
  }
}

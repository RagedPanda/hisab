import '../../core/notifications/reminder_scheduler.dart';
import '../repositories/sms_log_repository.dart';

/// [ReminderScheduler] for the app: Undo of a paid reminder also forgets the
/// bank SMS that paid it. Undo is a full reversal (owner decision 9), so the
/// reopened occurrence can be paid again, by another SMS too.
class SmsLinkedReminderScheduler extends ReminderScheduler {
  SmsLinkedReminderScheduler({
    required super.reminders,
    required super.notifications,
    required this.smsLog,
    super.removeEntry,
    super.settleSchedules,
    super.clock,
  });

  final SmsLogRepository smsLog;

  @override
  Future<void> undoDone(String id) async {
    await super.undoDone(id);
    await smsLog.clearMatchedReminder(id);
  }
}

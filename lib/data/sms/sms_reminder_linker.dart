import '../../domain/reminders/sms_reminder_match.dart';
import '../../domain/sms/parsed_transaction.dart';
import '../repositories/sms_log_repository.dart';

/// What the linker needs from the reminders store, so the ingest pipeline
/// does not depend on how reminders are persisted or scheduled.
abstract interface class ReminderPaymentPort {
  /// Pending reminders that could be paid by money leaving an account.
  Future<List<ReminderMatchCandidate>> pendingCandidates();

  /// Marks [reminderId] done by [entryId], records it in the reminder's
  /// history and advances it to its next due date.
  Future<void> markPaidBySms({required String reminderId, required String entryId});
}

/// After an SMS becomes an entry, pays the reminder it matches (if any) and
/// links the SMS to it. Returns the reminder id it paid, or null.
class SmsReminderLinker {
  SmsReminderLinker({required this.smsLog, required this.reminders, this.policy = const SmsMatchPolicy()});

  final SmsLogRepository smsLog;
  final ReminderPaymentPort reminders;
  final SmsMatchPolicy policy;

  Future<String?> linkEntry({required String smsId, required ParsedTransaction parsed, required String entryId}) async {
    final row = await smsLog.getById(smsId);
    if (row?.matchedReminderId != null) return null;
    final match = matchSmsToReminder(
      parsed,
      await reminders.pendingCandidates(),
      alreadyMatchedReminderIds: await smsLog.matchedReminderIds(),
      policy: policy,
    );
    if (match == null) return null;
    await reminders.markPaidBySms(reminderId: match.reminderId, entryId: entryId);
    await smsLog.setMatchedReminder(smsId, match.reminderId);
    return match.reminderId;
  }
}

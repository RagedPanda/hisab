import '../../core/notifications/reminder_scheduler.dart';
import '../../domain/reminders/reminder_kind.dart';
import '../../domain/reminders/sms_reminder_match.dart';
import '../db/database.dart';
import '../repositories/accounts_repository.dart';
import '../repositories/reminders_repository.dart';
import 'sms_reminder_linker.dart';

/// The matcher's view of a stored reminder; [account] is the account it is
/// paid from, which supplies the bank and last digits.
ReminderMatchCandidate reminderMatchCandidate(Reminder reminder, Account? account) => ReminderMatchCandidate(
      id: reminder.id,
      kind: reminder.kind,
      title: reminder.title,
      dueAt: reminder.dueAt!,
      amountMinor: reminder.amountMinor,
      toleranceMinor: reminder.toleranceMinor,
      matchKeywords: parseMatchKeywords(reminder.matchKeywords),
      bankName: account?.bankName,
      accountLast4: account?.last4,
    );

/// Only money reminders with an amount can be paid by a bank SMS.
bool canBePaidBySms(Reminder reminder) =>
    (ReminderKind.fromKey(reminder.kind)?.isMoney ?? false) && reminder.amountMinor != null && reminder.dueAt != null;

/// [ReminderPaymentPort] over the reminders table. Paying goes through
/// [ReminderScheduler] so the paid reminder's alerts are cancelled and the
/// next occurrence's are posted.
class ReminderPaymentAdapter implements ReminderPaymentPort {
  ReminderPaymentAdapter({required this.reminders, required this.scheduler, required this.accounts});

  final RemindersRepository reminders;
  final ReminderScheduler scheduler;
  final AccountsRepository accounts;

  @override
  Future<List<ReminderMatchCandidate>> pendingCandidates() async {
    final pending = (await reminders.getUpcoming()).where(canBePaidBySms).toList();
    if (pending.isEmpty) return const [];
    final accountsById = {for (final account in await accounts.getAll()) account.id: account};
    return [for (final reminder in pending) reminderMatchCandidate(reminder, accountsById[reminder.accountId])];
  }

  @override
  Future<void> markPaidBySms({required String reminderId, required String entryId}) => scheduler.markDone(reminderId, entryId: entryId);

  /// A full reversal through [ReminderScheduler.undoDone]: the reminder is
  /// unpaid again, the occurrence it spawned is dropped and its alerts come
  /// back. Left alone when it was since reopened or paid by another entry.
  @override
  Future<void> reopenPaidBySms({required String reminderId, required String entryId}) async {
    if (isStillPaidBy(await reminders.getById(reminderId), entryId)) await scheduler.undoDone(reminderId);
  }
}

/// Whether [reminder] is still closed as paid by [entryId].
bool isStillPaidBy(Reminder? reminder, String entryId) =>
    reminder != null && reminder.status == ReminderStatus.done && reminder.entryId == entryId;

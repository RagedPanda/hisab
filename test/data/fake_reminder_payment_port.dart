import 'package:hisab/data/sms/sms_reminder_linker.dart';
import 'package:hisab/domain/reminders/sms_reminder_match.dart';

/// In-memory reminders for linker and ingest tests: paying one removes it
/// from the pending list and records the payment.
class FakeReminders implements ReminderPaymentPort {
  FakeReminders(this.pending);
  final List<ReminderMatchCandidate> pending;
  final List<({String reminderId, String entryId})> paid = [];

  @override
  Future<List<ReminderMatchCandidate>> pendingCandidates() async => pending;

  @override
  Future<void> markPaidBySms({required String reminderId, required String entryId}) async {
    paid.add((reminderId: reminderId, entryId: entryId));
    pending.removeWhere((candidate) => candidate.id == reminderId);
  }
}

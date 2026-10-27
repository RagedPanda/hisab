import 'package:hisab/data/sms/sms_reminder_linker.dart';
import 'package:hisab/domain/reminders/sms_reminder_match.dart';

/// In-memory reminders for linker and ingest tests: paying one removes it
/// from the pending list and records the payment; reopening puts it back.
class FakeReminders implements ReminderPaymentPort {
  FakeReminders(this.pending);
  final List<ReminderMatchCandidate> pending;
  final List<({String reminderId, String entryId})> paid = [];
  final List<({String reminderId, String entryId})> reopened = [];
  final Map<String, ReminderMatchCandidate> _paidCandidates = {};

  @override
  Future<List<ReminderMatchCandidate>> pendingCandidates() async => pending;

  @override
  Future<void> markPaidBySms({required String reminderId, required String entryId}) async {
    paid.add((reminderId: reminderId, entryId: entryId));
    for (final candidate in pending.where((candidate) => candidate.id == reminderId)) {
      _paidCandidates[reminderId] = candidate;
    }
    pending.removeWhere((candidate) => candidate.id == reminderId);
  }

  /// Puts the reminder back in [pending], as reopening a real one would.
  @override
  Future<void> reopenPaidBySms({required String reminderId, required String entryId}) async {
    reopened.add((reminderId: reminderId, entryId: entryId));
    final candidate = _paidCandidates.remove(reminderId);
    if (candidate != null) pending.add(candidate);
  }
}

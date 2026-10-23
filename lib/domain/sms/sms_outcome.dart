import 'sms_parser.dart';

/// What happened to one processed SMS, as shown in the SMS history.
enum SmsOutcome { added, duplicate, ignored, unparsed, pending, undone }

/// Status strings stored in `sms_log.status`.
abstract final class SmsLogStatus {
  static const pending = 'pending';
  static const added = 'added';

  /// The user dismissed a pending message.
  static const ignored = 'ignored';

  /// From a bank sender (or forced) but the parser found no transaction.
  static const skipped = 'skipped';

  /// Not a bank message.
  static const notBank = 'not_bank';

  /// A re-delivery of a message that was already processed.
  static const duplicate = 'duplicate';

  /// An auto-added entry the user undid.
  static const undone = 'undone';
}

/// Whether the log may keep [body] for a message with [status]. Only text
/// that may be a real transaction is kept: never a not-bank message, and
/// never an OTP or a promotion, even from a sender that looks like a bank.
bool keepsSmsText(String status, String body) => status != SmsLogStatus.notBank && !isOtpOrPromotionSms(body);

/// The text the log stores for a message with [status]: [body], or nothing
/// when [keepsSmsText] says no. Only sender, time and outcome remain then.
String storedSmsBody(String status, String body) => keepsSmsText(status, body) ? body : '';

/// A re-delivery is logged only when its text could be kept, so an OTP or
/// promotion never gains a duplicate row.
bool logsDuplicateOf(String originalStatus, String incomingBody) => keepsSmsText(originalStatus, incomingBody);

/// Maps a stored status to the outcome the history screen shows.
SmsOutcome smsOutcomeFor(String status) => switch (status) {
      SmsLogStatus.added => SmsOutcome.added,
      SmsLogStatus.duplicate => SmsOutcome.duplicate,
      SmsLogStatus.skipped => SmsOutcome.unparsed,
      SmsLogStatus.pending => SmsOutcome.pending,
      SmsLogStatus.undone => SmsOutcome.undone,
      _ => SmsOutcome.ignored,
    };

/// Only messages that produced nothing can be run through ingest again.
bool canReprocessSms(SmsOutcome outcome) => outcome == SmsOutcome.ignored || outcome == SmsOutcome.unparsed;

/// Whether [incoming] is the same delivery as the logged message rather than
/// a bank re-delivery. Live SMS carry the network timestamp while the inbox
/// stores the device receive time, so one delivery read both ways can differ
/// by a few seconds; anything under [tolerance] apart is the same delivery.
bool isSameDelivery(DateTime logged, DateTime incoming, {Duration tolerance = const Duration(minutes: 1)}) =>
    logged.difference(incoming).abs() < tolerance;

/// Phone-number senders are people, not businesses; their messages are never
/// kept in the history.
bool isPersonalSender(String sender) => RegExp(r'^\+?[0-9 ]{6,}$').hasMatch(sender.trim());

/// One-line preview of a message body.
String smsBodyPreview(String body, {int maxChars = 90}) {
  final singleLine = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  return singleLine.length <= maxChars ? singleLine : '${singleLine.substring(0, maxChars).trimRight()}…';
}

/// How many rows have each outcome; every outcome is present, zero when absent.
Map<SmsOutcome, int> countSmsOutcomes(Iterable<SmsOutcome> outcomes) {
  final counts = {for (final outcome in SmsOutcome.values) outcome: 0};
  for (final outcome in outcomes) {
    counts[outcome] = counts[outcome]! + 1;
  }
  return counts;
}

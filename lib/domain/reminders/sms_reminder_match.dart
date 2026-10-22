/// Decides whether a parsed bank SMS pays one of the user's pending
/// reminders (R2 "auto-done on an SMS match"). Pure: the caller loads the
/// pending reminders and applies the result.
library;

import '../sms/parsed_transaction.dart';
import '../sms/payee_normaliser.dart';

/// How far the paid amount may differ from the reminder amount.
enum AmountTolerance { exact, percentage }

/// A pending reminder as the matcher sees it, independent of the table row.
class ReminderMatchCandidate {
  const ReminderMatchCandidate({
    required this.id,
    required this.kind,
    required this.title,
    required this.dueAt,
    required this.amountMinor,
    this.toleranceMinor = 0,
    this.matchKeywords = const [],
    this.bankName,
    this.accountLast4,
  });

  final String id;

  /// bill | emi | card | subscription | insurance | document | custom
  final String kind;
  final String title;
  final DateTime dueAt;

  /// Reminders without an amount (documents, renewals) never auto-match.
  final int? amountMinor;

  /// Difference the user allows, in minor units; 0 uses the kind's default.
  final int toleranceMinor;

  /// Names the payee goes by in bank SMS ("tata power", "tpddl"); the title
  /// is used when there are none.
  final List<String> matchKeywords;

  /// Bank of the account the reminder is paid from, e.g. "HDFC Bank".
  final String? bankName;
  final String? accountLast4;
}

/// Tunables for one match run.
class SmsMatchPolicy {
  const SmsMatchPolicy({
    this.earlyDays = 10,
    this.lateDays = 7,
    this.billTolerancePercent = 10,
  });

  /// Days before the due date a payment still counts for this occurrence.
  final int earlyDays;

  /// Days after the due date a late payment still counts.
  final int lateDays;

  /// Allowed difference for bills whose amount varies (electricity, card).
  final int billTolerancePercent;
}

/// The reminder an SMS pays, with how far it was from the expected values.
class ReminderMatch {
  const ReminderMatch({required this.reminderId, required this.dayOffset, required this.amountDifferenceMinor});

  final String reminderId;

  /// Calendar days from the due date to the payment; negative means early.
  final int dayOffset;
  final int amountDifferenceMinor;

  @override
  bool operator ==(Object other) =>
      other is ReminderMatch &&
      other.reminderId == reminderId &&
      other.dayOffset == dayOffset &&
      other.amountDifferenceMinor == amountDifferenceMinor;

  @override
  int get hashCode => Object.hash(reminderId, dayOffset, amountDifferenceMinor);

  @override
  String toString() => 'ReminderMatch($reminderId, day $dayOffset, diff $amountDifferenceMinor)';
}

const Set<String> _exactAmountKinds = {'emi', 'subscription', 'insurance'};

/// EMIs, subscriptions and premiums are fixed; bills vary month to month.
AmountTolerance toleranceForKind(String kind) =>
    _exactAmountKinds.contains(kind) ? AmountTolerance.exact : AmountTolerance.percentage;

/// Largest difference from [expectedMinor] that still counts as paying it.
/// A tolerance the user set wins over the kind's default.
int allowedDifferenceMinor({
  required int expectedMinor,
  required String kind,
  required int userToleranceMinor,
  required int tolerancePercent,
}) {
  if (userToleranceMinor > 0) return userToleranceMinor;
  if (toleranceForKind(kind) == AmountTolerance.exact) return 0;
  return expectedMinor * tolerancePercent ~/ 100;
}

/// Whole calendar days from [dueAt] to [paidAt], ignoring the time of day.
int calendarDayOffset({required DateTime dueAt, required DateTime paidAt}) {
  final dueDay = DateTime.utc(dueAt.year, dueAt.month, dueAt.day);
  final paidDay = DateTime.utc(paidAt.year, paidAt.month, paidAt.day);
  return paidDay.difference(dueDay).inDays;
}

bool withinDueWindow(int dayOffset, SmsMatchPolicy policy) => dayOffset >= -policy.earlyDays && dayOffset <= policy.lateDays;

const List<String> _refundWords = ['refund', 'reversal', 'reversed', 'cashback', 'chargeback'];

/// Money coming back is never a bill payment, even when the parser read it
/// as a debit-shaped message.
bool isRefundLike(ParsedTransaction parsed) {
  if (!parsed.isDebit) return true;
  final lower = parsed.raw.toLowerCase();
  return _refundWords.any(lower.contains);
}

const Set<String> _genericWords = {
  'bill', 'bills', 'emi', 'payment', 'pay', 'paid', 'loan', 'the', 'and', 'ltd', 'limited', 'pvt', 'private',
  'bank', 'card', 'credit', 'monthly', 'due', 'premium', 'recharge', 'india', 'services', 'company',
};

Set<String> _significantWords(String text) => text
    .toLowerCase()
    .split(RegExp(r'[^a-z0-9ऀ-ॿ]+'))
    .where((word) => word.length >= 3 && !_genericWords.contains(word))
    .toSet();

String _compact(String text) => text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9ऀ-ॿ]+'), '');

/// Splits the stored "tata power|tpddl" keyword column into keywords.
List<String> parseMatchKeywords(String stored) =>
    stored.split('|').map((keyword) => keyword.trim().toLowerCase()).where((keyword) => keyword.isNotEmpty).toList();

/// True when the SMS counterparty names the payee. A keyword the user typed
/// matches anywhere in the counterparty ("tata power" in "TATAPOWER DDL");
/// without keywords, a distinctive word of the title must appear.
bool payeeMatches({required String? counterparty, required List<String> keywords, required String reminderTitle}) {
  if (counterparty == null || counterparty.trim().isEmpty) return false;
  final compactCounterparty = _compact(counterparty);
  final counterpartyWords = {..._significantWords(counterparty), ..._significantWords(normalisePayee(counterparty))};
  if (keywords.isNotEmpty) {
    return keywords.any((keyword) {
      final compactKeyword = _compact(keyword);
      if (compactKeyword.length < 4) return counterpartyWords.contains(compactKeyword);
      return compactCounterparty.contains(compactKeyword);
    });
  }
  final titleWords = _significantWords(reminderTitle);
  if (titleWords.any(counterpartyWords.contains)) return true;
  return titleWords.any((word) => word.length >= 4 && compactCounterparty.contains(word));
}

String _bankKey(String bank) => _compact(bank.toLowerCase().replaceAll(RegExp(r'\bbank\b'), ''));

/// True when the SMS comes from the bank the reminder is paid from. When both
/// sides know the last digits of the account they must agree too.
bool bankMatches({required String? smsBank, required String? smsLast4, required String? reminderBank, required String? reminderLast4}) {
  if (smsBank == null || reminderBank == null) return false;
  final smsKey = _bankKey(smsBank);
  if (smsKey.isEmpty || smsKey != _bankKey(reminderBank)) return false;
  if (smsLast4 != null && reminderLast4 != null) return smsLast4 == reminderLast4;
  return true;
}

/// Evaluates one candidate; null when any rule fails.
ReminderMatch? evaluateCandidate(ParsedTransaction parsed, ReminderMatchCandidate candidate, SmsMatchPolicy policy) {
  final expected = candidate.amountMinor;
  if (expected == null || expected <= 0) return null;
  final allowed = allowedDifferenceMinor(
    expectedMinor: expected,
    kind: candidate.kind,
    userToleranceMinor: candidate.toleranceMinor,
    tolerancePercent: policy.billTolerancePercent,
  );
  if ((parsed.amountMinor - expected).abs() > allowed) return null;
  final dayOffset = calendarDayOffset(dueAt: candidate.dueAt, paidAt: parsed.occurredAt);
  if (!withinDueWindow(dayOffset, policy)) return null;
  final partyOk = payeeMatches(counterparty: parsed.counterparty, keywords: candidate.matchKeywords, reminderTitle: candidate.title) ||
      bankMatches(smsBank: parsed.bank, smsLast4: parsed.accountLast4, reminderBank: candidate.bankName, reminderLast4: candidate.accountLast4);
  if (!partyOk) return null;
  return ReminderMatch(reminderId: candidate.id, dayOffset: dayOffset, amountDifferenceMinor: (parsed.amountMinor - expected).abs());
}

/// Closest due date wins; then the closer amount; then a payment on or after
/// the due date over an early one; then the id, so the result is stable.
int _compareMatches(ReminderMatch first, ReminderMatch second) {
  final byDistance = first.dayOffset.abs().compareTo(second.dayOffset.abs());
  if (byDistance != 0) return byDistance;
  final byAmount = first.amountDifferenceMinor.compareTo(second.amountDifferenceMinor);
  if (byAmount != 0) return byAmount;
  final byDirection = second.dayOffset.compareTo(first.dayOffset);
  if (byDirection != 0) return byDirection;
  return first.reminderId.compareTo(second.reminderId);
}

/// Picks the reminder [parsed] pays, if any. [alreadyMatchedReminderIds]
/// holds reminders another SMS has already paid, so none is matched twice.
ReminderMatch? matchSmsToReminder(
  ParsedTransaction parsed,
  Iterable<ReminderMatchCandidate> candidates, {
  Set<String> alreadyMatchedReminderIds = const {},
  SmsMatchPolicy policy = const SmsMatchPolicy(),
}) {
  if (isRefundLike(parsed)) return null;
  final matches = candidates
      .where((candidate) => !alreadyMatchedReminderIds.contains(candidate.id))
      .map((candidate) => evaluateCandidate(parsed, candidate, policy))
      .whereType<ReminderMatch>()
      .toList()
    ..sort(_compareMatches);
  return matches.isEmpty ? null : matches.first;
}

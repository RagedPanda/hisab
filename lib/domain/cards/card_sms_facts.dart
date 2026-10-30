/// How card facts read from SMS (statement, minimum due, due date, available
/// limit) land on a card's account fields. Pure: callers pass the stored
/// fields in and write back what comes out.
library;

import '../../core/dates.dart';
import '../../data/db/database.dart';
import '../sms/card_sms.dart';
import 'card_cycle.dart';

/// The statement columns of a card account after a statement SMS.
class CardStatementFields {
  const CardStatementFields({
    required this.lastStatementMinor,
    required this.lastStatementAt,
    required this.minimumDueMinor,
    required this.statementFromSmsAt,
    required this.dueDay,
    required this.statementDay,
  });

  final int lastStatementMinor;
  final DateTime lastStatementAt;
  final int? minimumDueMinor;

  /// When the SMS arrived; the card screen shows it as "From SMS" and the date.
  final DateTime statementFromSmsAt;
  final int dueDay;
  final int? statementDay;
}

/// The statement date to record for [statement]: the date it states;
/// otherwise the stored statement date when that bill falls due on the same
/// day (a reminder repeating the same bill); otherwise the card's most recent
/// statement day; otherwise the day the SMS arrived. Always before the due
/// date, so the bill it starts is the one the SMS names.
DateTime statementDateForSms(CardStatementSms statement, {int? statementDay, int? dueDay, DateTime? lastStatementAt}) {
  final due = startOfDay(statement.dueDate);
  final latest = DateTime(due.year, due.month, due.day - 1);
  DateTime beforeDue(DateTime date) => date.isBefore(due) ? startOfDay(date) : latest;
  final stated = statement.statementDate;
  if (stated != null) return beforeDue(stated);
  if (lastStatementAt != null && dueDay != null && isSameDay(dueDateForStatement(lastStatementAt, dueDay), due)) {
    return startOfDay(lastStatementAt);
  }
  final received = startOfDay(statement.receivedAt);
  if (statementDay != null) {
    final previous = previousStatementDate(received, statementDay);
    if (previous.isBefore(due) && calendarDaysBetween(previous, due) <= 31) return previous;
  }
  return beforeDue(received);
}

/// The card's statement columns once [statement] is applied, or null when
/// the stored statement is newer (an old message read late changes nothing).
/// The due day follows the SMS due date; a missing statement day is taken
/// from a statement date the SMS states.
CardStatementFields? cardStatementFromSms(
  CardStatementSms statement, {
  int? statementDay,
  int? dueDay,
  DateTime? lastStatementAt,
}) {
  final statementAt = statementDateForSms(statement, statementDay: statementDay, dueDay: dueDay, lastStatementAt: lastStatementAt);
  if (lastStatementAt != null && statementAt.isBefore(startOfDay(lastStatementAt))) return null;
  return CardStatementFields(
    lastStatementMinor: statement.totalDueMinor,
    lastStatementAt: statementAt,
    minimumDueMinor: statement.minimumDueMinor,
    statementFromSmsAt: statement.receivedAt,
    dueDay: statement.dueDate.day,
    statementDay: statementDay ?? statement.statementDate?.day,
  );
}

/// Whether an available limit reported at [reportedAt] replaces the one
/// stored at [storedAt]: only a newer report does.
bool takesReportedLimit({required DateTime reportedAt, DateTime? storedAt}) => storedAt == null || !reportedAt.isBefore(storedAt);

/// Whether the statement read from SMS still stands after the account
/// editor saved [newMinor] on [newAt]: only while the user left the amount
/// and its date as they were. Otherwise the minimum due and the "from SMS"
/// note no longer describe the statement and are cleared.
bool keepsSmsStatement({int? previousMinor, DateTime? previousAt, int? newMinor, DateTime? newAt}) =>
    newMinor != null && newMinor == previousMinor && newAt != null && previousAt != null && isSameDay(newAt, previousAt);

/// The card a card SMS for [bank] and [last4] belongs to among [cards]
/// (live card accounts) when no account carries its SMS key: the one card
/// with those last digits, or, when the SMS names no digits, the one card of
/// that bank. Null when none or several fit.
String? matchingCardId(List<Account> cards, {required String? bank, required String? last4}) {
  final fits = [
    for (final card in cards)
      if (card.type == 'card' && (last4 != null ? card.last4 == last4 : bank != null && card.bankName == bank)) card,
  ];
  return fits.length == 1 ? fits.single.id : null;
}

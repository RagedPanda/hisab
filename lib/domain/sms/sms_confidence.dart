/// Rules that decide what happens to a bank SMS once it has been parsed:
/// add it straight away, hold it for review, or skip it. Pure, no I/O.
library;

import 'parsed_transaction.dart';

/// Where an incoming bank SMS ends up.
enum SmsRoute {
  /// Becomes an entry immediately, marked as added from SMS.
  autoAdd,

  /// Waits in the review queue for the user to add, edit or ignore.
  review,

  /// Logged only; nothing for the user to look at (OTPs, offers, notices).
  skip,
}

/// A parse is confident when the amount, the direction and the account or
/// bank it belongs to were all read from the message. The parser only
/// returns a [ParsedTransaction] once it found a direction, so that part is
/// carried by the type. Foreign-currency amounts are never confident: the
/// user has to enter the rupee value.
bool isConfidentParse(ParsedTransaction parsed) => parsed.amountMinor > 0 && (parsed.bank != null || parsed.accountLast4 != null) && parsed.currency == 'INR';

/// Picks the [SmsRoute] for one message.
///
/// [parsed] is the parser result (null when it could not read a
/// transaction), [autoAddEnabled] the user's setting and
/// [possibleTransaction] whether an unparsed message still looks like money
/// moved, so it is worth a human look.
SmsRoute routeForSms({required ParsedTransaction? parsed, required bool autoAddEnabled, required bool possibleTransaction}) {
  if (parsed == null) return possibleTransaction ? SmsRoute.review : SmsRoute.skip;
  return autoAddEnabled && isConfidentParse(parsed) ? SmsRoute.autoAdd : SmsRoute.review;
}

/// Whether auto-add is on. Users who never touched the toggle get the
/// default (on); an explicit choice is always kept.
bool resolveSmsAutoAdd({required bool? storedValue, required bool userChose}) => userChose ? (storedValue ?? true) : true;

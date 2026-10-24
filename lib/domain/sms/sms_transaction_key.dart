import 'dart:convert';

import 'package:crypto/crypto.dart' show sha1;

import 'parsed_transaction.dart';

/// Identifies the bank transaction an SMS reports, independent of who sent
/// the text and when it reached Hisab. The same transaction pasted from the
/// clipboard, opened from a deep link or read from the inbox maps to one key,
/// so it is added (and pays a reminder) only once.
///
/// A bank reference (UPI ref, RRN) names the transaction, together with its
/// direction and amount: a refund that quotes the original reference is a
/// different transaction. Without a reference the normalised text and the
/// transaction's calendar day stand in, so the same wording on another day
/// is still a new transaction.
String smsTransactionKey({
  required String body,
  required String direction,
  required int amountMinor,
  required DateTime occurredAt,
  String? reference,
}) {
  final trimmedReference = reference?.trim().toLowerCase() ?? '';
  final source = trimmedReference.isNotEmpty
      ? 'ref|$direction|$amountMinor|$trimmedReference'
      : 'text|${normaliseSmsBody(body)}|${occurredAt.year}-${occurredAt.month}-${occurredAt.day}';
  return sha1.convert(utf8.encode(source)).toString();
}

/// The key for a freshly parsed SMS.
String smsTransactionKeyForParsed(String body, ParsedTransaction parsed) => smsTransactionKey(
      body: body,
      direction: parsed.direction.name,
      amountMinor: parsed.amountMinor,
      occurredAt: parsed.occurredAt,
      reference: parsed.reference,
    );

/// The key for a logged SMS from its stored parse ([ParsedTransaction.toJson]),
/// or null when the row was never parsed, or when its text was wiped (history
/// cleared or not kept) and no bank reference is left to name it.
String? smsTransactionKeyForStored(String body, Map<String, dynamic>? parsed) {
  final direction = parsed?['direction'];
  final amountMinor = parsed?['amountMinor'];
  final occurredAt = DateTime.tryParse('${parsed?['occurredAt']}');
  final reference = parsed?['reference'] as String?;
  if (direction is! String || amountMinor is! int || occurredAt == null) return null;
  if (body.trim().isEmpty && (reference?.trim() ?? '').isEmpty) return null;
  return smsTransactionKey(
    body: body,
    direction: direction,
    amountMinor: amountMinor,
    occurredAt: occurredAt,
    reference: reference,
  );
}

/// Case, line breaks and repeated spaces differ between a pasted copy and
/// the inbox original; they never change the transaction.
String normaliseSmsBody(String body) => body.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Keys and lookups for the category the user chose for an SMS payee, so a
/// corrected payee is categorised right on every later message. Pure: the
/// table rows are passed in as a key -> category id map.
library;

import 'parsed_transaction.dart';
import 'payee_normaliser.dart';

/// Entry kinds a remembered category applies to; a payee can be both paid
/// and paid by, and each side keeps its own category.
const String kPayeeExpense = 'expense';
const String kPayeeIncome = 'income';

const String _vpaPrefix = 'vpa:';
const String _namePrefix = 'name:';

/// Generic categories the keyword rules fall back to when nothing matched.
const Set<String> kFallbackCategoryKeys = {'other_expense', 'other_income'};

/// Words that mark a UPI handle or name as a business, not a person.
final _merchantWords = RegExp(
  r'(?:^|[^a-z])(?:paytmqr|bharatpe|upiqr|gpay-|merchant|store|stores|shop|mart|enterprises?|traders?|services|pvt|ltd|llp|solutions|retail|foods?|restaurant|hotel|medical|pharma|agency|agencies|industries|company|co)(?:[^a-z]|$)',
  caseSensitive: false,
);

/// Merchant QR handles ("q123456789@ybl", "paytmqr...@paytm") are shops.
final _merchantQr = RegExp(r'^(?:q\d|paytmqr|bharatpe|upiqr|gpay-)', caseSensitive: false);

/// The entry kind ("expense" / "income") of an SMS in [direction].
String payeeKindFor(TxnDirection direction) => direction == TxnDirection.debit ? kPayeeExpense : kPayeeIncome;

/// Key for the UPI ID itself ("vpa:rahul.sharma@okaxis"), or null when [raw]
/// is not a VPA.
String? payeeVpaKey(String? raw) {
  final trimmed = raw?.trim() ?? '';
  return trimmed.isNotEmpty && isVpa(trimmed) ? '$_vpaPrefix${trimmed.toLowerCase()}' : null;
}

/// Key for the readable payee name ("name:myntra designs"): the normalised
/// name, lower-cased, punctuation folded to single spaces. Null when there is
/// no readable name (empty, or an opaque VPA kept as is).
String? payeeNameKey(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty || isOpaqueVpa(trimmed)) return null;
  final folded = normalisePayee(trimmed).toLowerCase().replaceAll(RegExp(r'[^a-z0-9ऀ-ॿ]+'), ' ').trim();
  return folded.isEmpty ? null : '$_namePrefix$folded';
}

/// Keys to look [raw] up by, most specific first: the VPA when present,
/// then the normalised name (so a card SMS for "Swiggy" and a UPI one for
/// swiggy@icici share a correction made on either).
List<String> payeeMemoryKeys(String? raw) => [?payeeVpaKey(raw), ?payeeNameKey(raw)].toSet().toList();

/// The key a correction for [raw] is stored under: the VPA when present,
/// otherwise the normalised name. Null when the SMS named no payee.
String? payeeMemoryKey(String? raw) => payeeMemoryKeys(raw).firstOrNull;

/// Row id for [payeeKey] on the [kind] side ("expense|vpa:x@ybl").
String payeeMemoryRowId(String kind, String payeeKey) => '$kind|$payeeKey';

/// The payee key part of a [payeeMemoryRowId].
String payeeKeyOfRowId(String rowId) => rowId.substring(rowId.indexOf('|') + 1);

/// Row ids to look an SMS payee up by, most specific first.
List<String> payeeMemoryRowIds(String kind, String? raw) => [for (final key in payeeMemoryKeys(raw)) payeeMemoryRowId(kind, key)];

/// The category remembered for [raw] on the [kind] side, given the stored
/// rows as row id -> category id. The VPA wins over the name.
String? rememberedCategoryId(Map<String, String> memory, {required String kind, required String? raw}) {
  for (final rowId in payeeMemoryRowIds(kind, raw)) {
    final categoryId = memory[rowId];
    if (categoryId != null) return categoryId;
  }
  return null;
}

/// Whether an SMS paid (or was paid by) a person over UPI rather than a
/// shop: a UPI transfer whose payee is not a known merchant, does not read
/// like a business and matched no keyword rule. Such payees have no useful
/// default, so the app asks the user for a category once.
bool isPersonToPersonPayee({required String? counterparty, required Instrument instrument, required String suggestedCategoryKey}) {
  final raw = counterparty?.trim() ?? '';
  if (raw.isEmpty || instrument != Instrument.upi) return false;
  if (!kFallbackCategoryKeys.contains(suggestedCategoryKey)) return false;
  if (isKnownMerchantPayee(raw)) return false;
  final local = isVpa(raw) ? raw.substring(0, raw.indexOf('@')) : raw;
  return !_merchantQr.hasMatch(local) && !_merchantWords.hasMatch(local);
}

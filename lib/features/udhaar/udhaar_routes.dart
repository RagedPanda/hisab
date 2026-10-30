import '../../data/db/database.dart';
import '../../domain/udhaar/udhaar.dart';

/// People with udhaar, reachable from Settings and the Home card.
const String kUdhaarLocation = '/udhaar';

/// One person's udhaar page.
String udhaarPersonLocation(String personId) => '$kUdhaarLocation/person/$personId';

/// The udhaar form: entry [id] to edit, or a new entry for [personId] of
/// [kind], prefilled with [amountMinor] and [accountId] when given.
String udhaarEntryLocation({String? id, String? personId, UdhaarKind? kind, int? amountMinor, String? accountId}) {
  final query = {
    'id': ?id,
    'person': ?personId,
    'kind': ?kind?.storageKey,
    'amount': ?amountMinor?.toString(),
    'account': ?accountId,
  };
  return Uri(path: '$kUdhaarLocation/entry', queryParameters: query.isEmpty ? null : query).toString();
}

/// Where the general entry editor sends an udhaar [entry] of [kind]: the
/// udhaar form editing it, or a new one prefilled from it [asCopy].
String udhaarEditorLocation(Entry entry, UdhaarKind kind, {required bool asCopy}) => asCopy
    ? udhaarEntryLocation(
        personId: entry.personId,
        kind: kind,
        amountMinor: entry.amountMinor,
        accountId: udhaarAccountOf(from: entry.accountId, to: entry.toAccountId),
      )
    : udhaarEntryLocation(id: entry.id);

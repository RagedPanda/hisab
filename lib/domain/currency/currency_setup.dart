import 'currency_lookup.dart';

/// What startup should do about the currency setting.
///
/// Returns the code to store for an install that has no stored code yet but
/// is an upgrade: it already had the old symbol setting or has its own data.
/// Returns null when nothing should be written: a code is already stored, or
/// this is a fresh install that must pick one on the first-launch screen.
String? currencyCodeToMigrate({required String? storedCode, required String? legacySymbol, required bool hasUserData}) {
  if (storedCode != null && storedCode.isNotEmpty) return null;
  if (legacySymbol == null && !hasUserData) return null;
  return currencyCodeForLegacySymbol(legacySymbol);
}

import '../currency/currency_lookup.dart';

/// Key of the settings section in a backup payload.
const String kBackupSettingsKey = 'settings';

/// Settings a backup carries so a restore brings them back.
Map<String, dynamic> backupSettingsSection({required String currencyCode}) => {'currencyCode': currencyCode};

/// The currency stored in a backup, or null for an older backup without one
/// (or an unknown code), in which case the current currency is kept.
String? backupCurrencyCode(Map<String, dynamic> payload) {
  final section = payload[kBackupSettingsKey];
  if (section is! Map) return null;
  final code = section['currencyCode'];
  if (code is! String) return null;
  return currencyByCode(code)?.code;
}

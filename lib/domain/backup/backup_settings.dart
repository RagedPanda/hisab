import '../currency/currency_lookup.dart';
import '../money/money_format.dart';

/// Key of the settings section in a backup payload.
const String kBackupSettingsKey = 'settings';

/// Settings a backup carries so a restore brings them back.
Map<String, dynamic> backupSettingsSection({required String currencyCode, NumberFormatChoice? numberFormat}) => {
      'currencyCode': currencyCode,
      if (numberFormat != null) 'numberFormat': numberFormat.storageKey,
    };

/// The currency stored in a backup, or null for an older backup without one
/// (or an unknown code), in which case the current currency is kept.
String? backupCurrencyCode(Map<String, dynamic> payload) {
  final section = payload[kBackupSettingsKey];
  if (section is! Map) return null;
  final code = section['currencyCode'];
  if (code is! String) return null;
  return currencyByCode(code)?.code;
}

/// The number format choice stored in a backup, or null for an older backup
/// without one (or an unknown value), in which case the current one is kept.
NumberFormatChoice? backupNumberFormat(Map<String, dynamic> payload) {
  final section = payload[kBackupSettingsKey];
  if (section is! Map) return null;
  final key = section['numberFormat'];
  if (key is! String) return null;
  return NumberFormatChoice.tryFromStorageKey(key);
}

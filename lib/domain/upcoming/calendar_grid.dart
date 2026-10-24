/// Pure month-grid layout for the due calendar.
library;

/// The cells of a month view in rows of seven: leading nulls pad the first
/// week so day 1 lands under its weekday, trailing nulls fill the last row.
/// [firstWeekday] is the ISO weekday the rows start on (1 = Monday).
List<DateTime?> calendarMonthCells(DateTime month, {int firstWeekday = DateTime.monday}) {
  final first = DateTime(month.year, month.month);
  final length = DateTime(month.year, month.month + 1, 0).day;
  final leading = (first.weekday - firstWeekday) % 7;
  final cells = <DateTime?>[for (var pad = 0; pad < leading; pad++) null, for (var day = 1; day <= length; day++) DateTime(month.year, month.month, day)];
  final trailing = (7 - cells.length % 7) % 7;
  return [...cells, for (var pad = 0; pad < trailing; pad++) null];
}

/// The seven weekdays (ISO numbers) in display order.
List<int> calendarWeekdays({int firstWeekday = DateTime.monday}) => [for (var offset = 0; offset < 7; offset++) (firstWeekday - 1 + offset) % 7 + 1];

/// Regions whose week does not start on Monday (CLDR supplemental weekData,
/// `firstDay`); every other region starts on Monday.
final Map<String, int> _regionFirstWeekday = {
  for (final region in [
    'AG',
    'AS',
    'BD',
    'BR',
    'BS',
    'BT',
    'BW',
    'BZ',
    'CA',
    'CN',
    'CO',
    'DM',
    'DO',
    'ET',
    'GT',
    'GU',
    'HK',
    'HN',
    'ID',
    'IL',
    'IN',
    'JM',
    'JP',
    'KE',
    'KH',
    'KR',
    'LA',
    'MH',
    'MM',
    'MO',
    'MT',
    'MX',
    'MZ',
    'NI',
    'NP',
    'PA',
    'PE',
    'PH',
    'PK',
    'PR',
    'PT',
    'PY',
    'SA',
    'SG',
    'SV',
    'TH',
    'TT',
    'TW',
    'UM',
    'US',
    'VE',
    'VI',
    'WS',
    'YE',
    'ZA',
    'ZW',
  ])
    region: DateTime.sunday,
  for (final region in ['AE', 'AF', 'BH', 'DJ', 'DZ', 'EG', 'IQ', 'IR', 'JO', 'KW', 'LY', 'OM', 'QA', 'SD', 'SY']) region: DateTime.saturday,
  'MV': DateTime.friday,
};

/// The region assumed when a locale names only a language: the app's own
/// languages default to where their untagged locale data comes from.
const Map<String, String> _languageDefaultRegion = {'en': 'US', 'hi': 'IN'};

/// ISO weekday the week starts on in [region] (an ISO 3166 country code).
int firstWeekdayOfRegion(String region) => _regionFirstWeekday[region.toUpperCase()] ?? DateTime.monday;

/// ISO weekday the due calendar starts its rows on.
///
/// The app ships only language translations (`en`, `hi`), so the region must
/// come from the device: the first device locale speaking [appLanguage]
/// decides (`en-GB` starts on Monday, `en-US` on Sunday). Without one, the
/// language's default region decides. Tags may use `-` or `_`.
int calendarFirstWeekday({required String appLanguage, required List<String> deviceLocaleTags}) {
  for (final tag in deviceLocaleTags) {
    final parts = tag.split(RegExp('[-_]'));
    if (parts.first.toLowerCase() != appLanguage.toLowerCase()) continue;
    final region = parts.skip(1).where((part) => part.length == 2 || (part.length == 3 && int.tryParse(part) != null)).firstOrNull;
    if (region != null) return firstWeekdayOfRegion(region);
  }
  final fallback = _languageDefaultRegion[appLanguage.toLowerCase()];
  return fallback == null ? DateTime.monday : firstWeekdayOfRegion(fallback);
}

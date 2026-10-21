# Localisation

Hisab ships in English, but every piece of text a user sees comes from a dictionary, so
adding Hindi, Spanish or any other language is a matter of adding files, not touching screens.

## What is already in place
| Layer | Where | Mechanism |
|---|---|---|
| UI strings (buttons, titles, hints, errors, plurals) | `lib/l10n/app_en.arb` | Flutter `gen-l10n`; screens call `context.l10n.key` |
| Built-in category names | `lib/l10n/category_names.dart` | map `language code -> seed key -> name`; user renames always win |
| Dates, month names, number grouping | `intl` via `Localizations.localeOf(context)` | automatic once a locale is supported |
| Language setting | Settings -> Appearance -> Language | "Device language" or any supported locale, persisted in `AppSettings.localeCode` |
| Bank SMS parsing | `lib/domain/sms/sms_parser.dart`, `bank_senders.dart` | keyword and regex dictionaries; Indian bank SMS are English regardless of UI language |
| SMS -> category rules | `lib/domain/sms/sms_categorizer.dart` | keyword lists per category seed key; add local merchant names per market |

Domain code (`lib/domain`) contains no user-facing text; labels for enums such as
`SplitMethod` are mapped to dictionary keys in the widget layer.

## Adding a language (example: Hindi)
1. Copy `lib/l10n/app_en.arb` to `lib/l10n/app_hi.arb`, set `"@@locale": "hi"`, translate
   the values. Keep placeholders such as `{amount}` unchanged. Any key you omit falls back
   to English.
2. Add a `'hi': {...}` map to `localizedCategoryNames` in `lib/l10n/category_names.dart`
   keyed by the seed keys in `lib/domain/categories/category_catalog.dart`.
3. Add the display name to `localeDisplayName` in `lib/l10n/l10n.dart`.
4. Run `flutter gen-l10n`. The locale appears in Settings automatically because the
   picker reads `AppLocalizations.supportedLocales`.

Optional per market: extend the merchant keyword lists in `sms_categorizer.dart` and the
sender prefixes in `bank_senders.dart`.

## Rules for new code
- Never put English literals in widgets; add a key to `app_en.arb` and use `context.l10n`.
- Counts use ICU plurals (`{count, plural, =1{...} other{...}}`), never string concatenation.
- Stored values (`'expense'`, `'pending'`, seed keys, units) are identifiers, not text; they
  stay in English in the database and are translated only at display time.

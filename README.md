<p align="center"><img src="assets/logo/hisab_wordmark.png" alt="Hisab" width="480"></p>

# Hisab

Free, open-source personal expense tracker for Android and iOS. No ads, no trial, no account.

## Features
- Daily entries that can hold multiple items with quantity, unit and price (e.g. buffalo milk 1 L, cow milk 0.5 L). Hisab remembers items per category and suggests them next time.
- 18 expense groups with 100+ subcategories, plus income and transfer categories. All editable.
- Bank SMS reading on Android (opt-in, on-device): auto-detects transactions and balances, with a review inbox. iPhone users can forward alerts with a Shortcut or paste them.
- Groups with Splitwise-style splitting: equal, exact, percentage, shares, adjustments, by item. Simplified settle-up suggestions.
- Budgets with pace indicator, salary-month cycle, light and dark theme.
- Encrypted backup (AES-256-GCM) and a plan for encrypted cloud sync.

## Build
```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter run
```

## Docs
- [docs/PLAN.md](docs/PLAN.md): architecture, feature matrix, sync design.
- [docs/PERMISSIONS.md](docs/PERMISSIONS.md): every permission per platform, store declaration text, reference apps.
- [docs/LOCALIZATION.md](docs/LOCALIZATION.md): English and Hindi today; a new language is one ARB file plus a category-name map.
- [docs/REFERENCE_APPS.md](docs/REFERENCE_APPS.md): what FinArt, Splitwise, Money Manager, Monefy, Cashew and PennyWise taught us.

## Contributing
Issues and pull requests are welcome. Run `flutter test` before opening a PR, and add new user-facing strings to the ARB files rather than hardcoding them (see [docs/LOCALIZATION.md](docs/LOCALIZATION.md)).

## License
[MIT](LICENSE)

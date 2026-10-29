# Hisab — project notes

## README screenshots
- Any change that alters what a screen looks like (theme, layout, a redesigned card or form) must also refresh the affected images in `docs/screenshots/` that `README.md` shows, in the same PR.
- Keep the existing set and names (`01-dashboard.png` … `08-hindi-budgets.png`): Android emulator, made-up demo data (`--dart-define=HISAB_SEED_ENTRIES=120` on a debug build), resized to 360×800 PNG.
- The seed writes the rows each shot needs (`lib/data/debug/demo_story.dart`: Gwala Ji items, Goa trip, SMS to review, subscriptions); add to it rather than entering data by hand. Install fresh so the seed runs, and put System UI in demo mode with the clock at 10:00 before capturing.
- When the test count or coverage changes noticeably, update the README badges and the "measured on" date too (`flutter test --coverage`, generated `*.g.dart` and `lib/l10n/generated` excluded).

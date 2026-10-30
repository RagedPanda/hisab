# Hisab — project notes

## README screenshots
- Any change that alters what a screen looks like (theme, layout, a redesigned card or form) must also refresh the affected images in `docs/screenshots/` (Android) and `docs/screenshots/ios/` (iOS) in the same PR. `README.md` shows four of them; `docs/SCREENSHOTS.md` is the full Android | iOS gallery with Previous/Next links.
- Keep the existing set and names (`01-dashboard.png` … `13-spending-calendar-dark.png`). A new screen gets the next number, a shot in `integration_test/readme_gallery_test.dart` and a section in `docs/SCREENSHOTS.md`.
- Capture with `tool/readme_screenshots.sh android <serial>` and `tool/readme_screenshots.sh ios <simulator-udid>`: it sets the status bar to 10:00, runs the gallery flow over the demo seed (120 entries, `lib/data/debug/demo_story.dart`) and writes 360-wide PNGs, then `tool/frame_screenshots.py` draws a Pixel or iPhone 17 body around each into `docs/screenshots/framed/<platform>/`, which the README and gallery show (needs Pillow). Add to the seed rather than entering data by hand.
- When the test count or coverage changes noticeably, update the README badges and the "measured on" date too (`flutter test --coverage`, generated `*.g.dart` and `lib/l10n/generated` excluded).

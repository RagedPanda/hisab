/// The README screenshot gallery, shot on a real device or simulator over
/// the demo story (Gwala Ji items, Goa trip, SMS to review, subscriptions).
/// Each shot is named after its file in docs/screenshots. Run it through
/// `tool/readme_screenshots.sh`, which starts the device-shot watcher so
/// every image is a full-screen capture with the status bar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/debug/demo_seed.dart';
import 'package:hisab/features/quick_entries/quick_entries_screen.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:hisab/features/spending_calendar/spending_calendar_screen.dart';
import 'package:hisab/features/upcoming/upcoming_routes.dart';
import 'package:integration_test/integration_test.dart';

import 'harness.dart';

/// Demo entries the gallery is shot over, as with `HISAB_SEED_ENTRIES=120`.
const int kGalleryEntryCount = 120;

Future<void> _open(WidgetTester tester, String location) async {
  appRouter.push(location);
  await settle(tester);
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('README gallery', (tester) async {
    final app = await createApp();
    await seedDemoData(app.db, entryCount: kGalleryEntryCount);
    await pumpApp(tester, app);
    await shoot(tester, '01-dashboard');

    await goTab(tester, 'Entries');
    await shoot(tester, '02-entries');
    await tapText(tester, 'Gwala Ji');
    await scrollTo(tester, find.text('Paneer'));
    await shoot(tester, '03-multi-item-entry');
    await goBack(tester);

    await tapFinder(tester, find.byKey(const ValueKey('entries.calendar')));
    await shoot(tester, '09-spending-calendar');
    await goBack(tester);

    await goTab(tester, 'Groups');
    await tapText(tester, 'Goa trip');
    await shoot(tester, '04-group-expenses');
    await tapText(tester, 'Balances');
    await shoot(tester, '05-group-settle-up');
    await goBack(tester);

    await goTab(tester, 'Home');
    await _open(tester, '/sms/review');
    await shoot(tester, '06-sms-review');
    await goBack(tester);

    await _open(tester, kUpcomingCalendarRoute);
    await tapFinder(tester, find.byTooltip('Next month'));
    await tapFinder(tester, find.byKey(const ValueKey('upcoming.calendar.day.3')));
    await shoot(tester, '10-due-calendar');
    await goBack(tester);

    await _open(tester, '/entry?quick=seed.quick.milk');
    await tester.enterText(find.byType(EditableText).first, '60');
    await settle(tester);
    await shoot(tester, '11-new-entry');
    await discardEntry(tester);

    await _open(tester, kQuickEntriesLocation);
    await shoot(tester, '12-quick-entries');
    await goBack(tester);

    await app.read(settingsProvider.notifier).update((settings) => settings.copyWith(themeMode: ThemeMode.dark));
    await _open(tester, '/subscriptions');
    await shoot(tester, '07-subscriptions-dark');
    await goBack(tester);
    await _open(tester, kSpendingCalendarRoute);
    await shoot(tester, '13-spending-calendar-dark');
    await goBack(tester);
    await app.read(settingsProvider.notifier).update((settings) => settings.copyWith(themeMode: ThemeMode.light));

    await app.read(settingsProvider.notifier).update((settings) => settings.copyWith(localeCode: 'hi'));
    await settle(tester);
    await scrollTo(tester, find.text('बजट'));
    // scrollTo leaves the heading at the top edge; show the spend split above it too.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 300));
    await settle(tester);
    await shoot(tester, '08-hindi-budgets');
  });
}

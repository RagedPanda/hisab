import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:hisab/features/shell/widgets/common.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the real app on an in-memory database through the main journeys,
/// with [overrides] on top of the test database and preferences. [seed] runs
/// against the database before the first frame, while no query is in flight.
/// [preferences] are stored before the app starts, as from an earlier run.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
  Future<void> Function(ProviderContainer container)? seed,
  Map<String, Object> preferences = const {},
}) async {
  SharedPreferences.setMockInitialValues({'onboarded': true, 'currencyCode': 'INR', ...preferences});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    databaseProvider.overrideWithValue(db),
    ...overrides,
  ]);
  addTearDown(container.dispose);
  if (seed != null) await tester.runAsync(() => seed(container));
  await tester.binding.setSurfaceSize(const Size(430, 932));
  appRouter.go('/home');
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
  await settle(tester);
  return container;
}

/// Text fields keep the cursor blinking, so pumpAndSettle never settles on
/// screens with an autofocused field. Pump a fixed number of frames instead.
Future<void> settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> enter(WidgetTester tester, Finder field, String text) async {
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

/// An app container on a fresh in-memory database, disposed after the test.
Future<ProviderContainer> createContainer({Map<String, Object> preferences = const {}, List<Override> overrides = const []}) async {
  SharedPreferences.setMockInitialValues({'onboarded': true, 'currencyCode': 'INR', ...preferences});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    databaseProvider.overrideWithValue(db),
    ...overrides,
  ]);
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  return container;
}

/// Lets drift queries and streams complete (they need real async) between
/// frames.
Future<void> pumpWithDatabase(WidgetTester tester, [int frames = 6]) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Text of the placeholder page shown for any location [pumpScreen] has no
/// route for, so a test can assert where a tap navigated.
String openedLocation(String location) => 'opened $location';

/// Shows [screen] pushed over a plain Home page in a localized app on
/// [container], so popping it lands back on Home. Any other location opens a
/// page reading [openedLocation].
Future<GoRouter> pumpScreen(WidgetTester tester, ProviderContainer container, Widget screen, {Locale locale = const Locale('en'), Size size = const Size(360, 780)}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: kHomeLocation,
    routes: [
      GoRoute(path: kHomeLocation, builder: (_, _) => const Scaffold(body: Text('home'))),
      GoRoute(path: '/screen', builder: (_, _) => screen),
    ],
    errorBuilder: (_, state) => Scaffold(body: Text(openedLocation(state.uri.toString()))),
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  ));
  router.push('/screen');
  await pumpWithDatabase(tester);
  return router;
}

/// Scrolls the first horizontal [ChipRow] on screen from its start until
/// [chip] is built and in view; chips past the edge are not built yet.
Future<void> revealInChipRow(WidgetTester tester, Finder chip) async {
  final row = find.descendant(of: find.byType(ChipRow), matching: find.byType(Scrollable)).first;
  tester.state<ScrollableState>(row).position.jumpTo(0);
  await tester.pump();
  await tester.scrollUntilVisible(chip, 80, scrollable: row);
  await tester.pump();
}

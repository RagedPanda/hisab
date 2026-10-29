import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:hisab/features/shell/widgets/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the real app on an in-memory database through the main journeys,
/// with [overrides] on top of the test database and preferences. [seed] runs
/// against the database before the first frame, while no query is in flight.
Future<ProviderContainer> pumpApp(WidgetTester tester, {List<Override> overrides = const [], Future<void> Function(ProviderContainer container)? seed}) async {
  SharedPreferences.setMockInitialValues({'onboarded': true, 'currencyCode': 'INR'});
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

/// Scrolls the first horizontal [ChipRow] on screen from its start until
/// [chip] is built and in view; chips past the edge are not built yet.
Future<void> revealInChipRow(WidgetTester tester, Finder chip) async {
  final row = find.descendant(of: find.byType(ChipRow), matching: find.byType(Scrollable)).first;
  tester.state<ScrollableState>(row).position.jumpTo(0);
  await tester.pump();
  await tester.scrollUntilVisible(chip, 80, scrollable: row);
  await tester.pump();
}

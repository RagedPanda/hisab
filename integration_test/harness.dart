/// Shared helpers for the on-device integration suite. Boots the real app on
/// an in-memory database with mocked preferences, so the installed app's own
/// data is never touched, and provides screenshot + interaction utilities.
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final IntegrationTestWidgetsFlutterBinding binding;

/// The app state (database + preferences) that a flow runs against.
class AppHandle {
  AppHandle(this.container, this.db);
  final ProviderContainer container;
  final AppDatabase db;

  T read<T>(ProviderListenable<T> provider) => container.read(provider);
}

/// Creates a fresh in-memory database and preference store.
Future<AppHandle> createApp({bool onboarded = true}) async {
  SharedPreferences.setMockInitialValues({'onboarded': onboarded});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    databaseProvider.overrideWithValue(db),
  ]);
  return AppHandle(container, db);
}

/// Mounts [HisabApp] for [app] and lands on the Home tab.
Future<void> pumpApp(WidgetTester tester, AppHandle app) async {
  appRouter.go('/home');
  await tester.pumpWidget(UncontrolledProviderScope(container: app.container, child: const HisabApp()));
  await settle(tester);
}

/// Pumps a fixed number of real frames. `pumpAndSettle` never returns on
/// screens with a blinking cursor, so every wait in the suite goes through here.
Future<void> settle(WidgetTester tester, [int frames = 8]) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapText(WidgetTester tester, String text, {bool last = false, int frames = 8}) async {
  final finder = last ? find.text(text).last : find.text(text).first;
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester, frames);
}

Future<void> tapFinder(WidgetTester tester, Finder finder, {int frames = 8}) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester, frames);
}

Future<void> enterText(WidgetTester tester, Finder field, String text) async {
  await tester.ensureVisible(field);
  await tester.pump();
  await tester.tap(field);
  await tester.pump();
  await tester.enterText(field, text);
  await settle(tester, 3);
}

/// Switches bottom tabs by label.
Future<void> goTab(WidgetTester tester, String label) async {
  await tapFinder(tester, find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
}

/// Pops the current route via the AppBar back button. `pageBack` looks the
/// button up by its English tooltip, which breaks once the app is in Hindi.
Future<void> goBack(WidgetTester tester) async {
  final backButton = find.byType(BackButton);
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton.first);
  } else {
    await tester.pageBack();
  }
  await settle(tester);
}

/// Scrolls the first [Scrollable] under [within] until [target] is visible
/// (downwards by default, upwards with [up]), then nudges the list so the
/// target is clear of floating action buttons. Lists build lazily, so a
/// target that is off screen cannot even be found until this has run.
Future<void> scrollTo(WidgetTester tester, Finder target, {Finder? within, bool up = false}) async {
  final scrollables = within == null ? find.byType(Scrollable) : find.descendant(of: within, matching: find.byType(Scrollable));
  await waitFor(tester, scrollables);
  final position = tester.state<ScrollableState>(scrollables.first).position;
  for (var step = 0; step < kScrollSteps && target.evaluate().isEmpty; step++) {
    final next = (position.pixels + (up ? -kScrollStep : kScrollStep)).clamp(position.minScrollExtent, position.maxScrollExtent);
    if (next == position.pixels) break;
    position.jumpTo(next);
    await tester.pump();
  }
  if (target.evaluate().isEmpty) {
    final onstage = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().toList();
    final widget = scrollables.first.evaluate().first.widget as Scrollable;
    debugPrint('SCROLL-DIAG axis=${widget.axisDirection} pixels=${position.pixels} min=${position.minScrollExtent} max=${position.maxScrollExtent} count=${scrollables.evaluate().length} texts=$onstage');
  }
  expect(target, findsWidgets, reason: 'scrollTo could not bring the target on screen');
  await tester.ensureVisible(target.first);
  await tester.pump();
  if (!up) await _nudgeClearOfFab(tester, position, target);
  await settle(tester, 2);
}

/// Moves the list on by [kFabClearance] so the target is not under a floating
/// action button, unless that would push the target off screen again (small
/// viewports with the keyboard open).
Future<void> _nudgeClearOfFab(WidgetTester tester, ScrollPosition position, Finder target) async {
  final before = position.pixels;
  position.jumpTo((before + kFabClearance).clamp(position.minScrollExtent, position.maxScrollExtent));
  await tester.pump();
  if (target.evaluate().isEmpty) {
    position.jumpTo(before);
    await tester.pump();
  }
}

/// Scrolling is driven through the [ScrollPosition] rather than drag gestures:
/// with the keyboard open a drag that starts over a text field is claimed by
/// the field's selection recogniser and the list never moves.
const double kScrollStep = 200;
const int kScrollSteps = 50;
const double kFabClearance = 140;

/// Pumps until [finder] matches something, giving lazily loaded screens a
/// bounded moment to build. Fails the test if nothing appears in time.
Future<void> waitFor(WidgetTester tester, Finder finder, {int frames = 20}) async {
  for (var frame = 0; frame < frames && finder.evaluate().isEmpty; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

/// Whether the dialog/sheet currently on screen contains [text].
bool hasText(String text) => find.text(text).evaluate().isNotEmpty;

var _shotIndex = 0;

/// Takes an in-app screenshot (delivered to the driver as `<nn>_<name>.png`)
/// and, when `device_shots_watcher.sh` is running on the host, a full-device
/// `simctl` screenshot as `<nn>_<name>_device.png`.
Future<void> shoot(WidgetTester tester, String name) async {
  await settle(tester, 3);
  final numbered = '${(_shotIndex++).toString().padLeft(2, '0')}_$name';
  await _requestDeviceShot(numbered);
  await binding.takeScreenshot(numbered);
}

bool? _watcherAlive;

Future<void> _requestDeviceShot(String name) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/device_shots');
  await dir.create(recursive: true);
  _watcherAlive ??= File('${dir.path}/watcher_alive').existsSync();
  if (!_watcherAlive!) return;
  final request = File('${dir.path}/req_$name');
  await request.writeAsString(name, flush: true);
  final deadline = DateTime.now().add(const Duration(seconds: 8));
  while (request.existsSync() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

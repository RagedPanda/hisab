/// Shared helpers for the on-device integration suite. Boots the real app on
/// an in-memory database with mocked preferences, so the installed app's own
/// data is never touched, and provides screenshot + interaction utilities.
library;

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/core/settings.dart';
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

/// Creates a fresh in-memory database and preference store. A home currency is
/// saved by default so flows start on Home rather than the first-launch
/// currency picker; pass `currencyCode: null` to land on the picker.
Future<AppHandle> createApp({bool onboarded = true, String? currencyCode = 'INR', List<Override> overrides = const []}) async {
  SharedPreferences.setMockInitialValues({'onboarded': onboarded, kCurrencyCodeKey: ?currencyCode});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), databaseProvider.overrideWithValue(db), ...overrides]);
  return AppHandle(container, db);
}

/// Mounts [HisabApp] for [app] and lands on the Home tab.
Future<void> pumpApp(WidgetTester tester, AppHandle app) async {
  appRouter.go('/home');
  await tester.pumpWidget(_SurfaceMediaQuery(child: UncontrolledProviderScope(container: app.container, child: const HisabApp())));
  await settle(tester);
}

/// The logical size set by [useLogicalWidth], or null for the device's own.
final _logicalSurface = ValueNotifier<Size?>(null);

/// Lays the app out [width] logical pixels wide (a 360dp phone) until the
/// test ends.
///
/// Never set `tester.view.physicalSize` on a device for this. The engine
/// only rasterizes frames whose size matches the real window
/// (`Shell::ShouldDiscardLayerTree`), so every frame drawn at an overridden
/// physical size is dropped: the next Android capture returns the last frame
/// drawn before the resize and the one after that waits forever (#99).
/// `setSurfaceSize` instead lays out at [width] and paints into the real
/// window, centred, so frames keep reaching the screen. MediaQuery still
/// reports the window, so [_SurfaceMediaQuery] narrows it to match.
Future<void> useLogicalWidth(WidgetTester tester, double width) async {
  final size = Size(width, tester.view.physicalSize.height / tester.view.devicePixelRatio);
  addTearDown(() async {
    _logicalSurface.value = null;
    await binding.setSurfaceSize(null);
  });
  await binding.setSurfaceSize(size);
  _logicalSurface.value = size;
  await settle(tester, 4);
}

/// Reports the [useLogicalWidth] size through MediaQuery, so widgets that
/// read `MediaQuery.sizeOf` see the same width as their constraints.
class _SurfaceMediaQuery extends StatelessWidget {
  const _SurfaceMediaQuery({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Size?>(
        valueListenable: _logicalSurface,
        child: child,
        builder: (context, size, child) => size == null ? child! : MediaQuery(data: MediaQuery.of(context).copyWith(size: size), child: child!),
      );
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

/// The entry editor tucks its advanced fields (date, note, payee, project,
/// repeat, items) behind a "More details" tile that starts collapsed on a
/// fresh entry. Opens it so those fields can be reached; a no-op when [reveals]
/// (a field that appears once expanded) is already in the tree, e.g. when
/// editing auto-expanded the section.
Future<void> openMoreDetails(WidgetTester tester, {required Finder reveals}) async {
  if (reveals.evaluate().isNotEmpty) return;
  final tile = find.byKey(const ValueKey('editor.moreDetails'));
  if (tile.evaluate().isEmpty) await scrollTo(tester, tile);
  if (reveals.evaluate().isEmpty) await tapFinder(tester, tile);
}

/// Picks the account named [name] in the entry editor: opens the account row
/// ([pickerKey] is `from-account` or `to-account`), then taps it in the sheet.
Future<void> pickEditorAccount(WidgetTester tester, String name, {String pickerKey = 'from-account'}) async {
  await tapFinder(tester, find.byKey(ValueKey(pickerKey)));
  await tapFinder(tester, find.descendant(of: find.byType(BottomSheet), matching: find.widgetWithText(ListTile, name)));
}

/// Leaves the entry editor with unsaved input: Back raises the "Discard this
/// entry?" prompt, which is confirmed.
Future<void> discardEntry(WidgetTester tester) async {
  await goBack(tester);
  await tapFinder(tester, find.byKey(const Key('discard-entry')));
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
    final widget = scrollables.first.evaluate().first.widget as Scrollable;
    debugPrint(
      'SCROLL-DIAG axis=${widget.axisDirection} pixels=${position.pixels} min=${position.minScrollExtent} max=${position.maxScrollExtent} count=${scrollables.evaluate().length} texts=${onstageTexts()}',
    );
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
  if (finder.evaluate().isEmpty) debugPrint('WAIT-DIAG texts=${onstageTexts()}');
  expect(finder, findsWidgets);
}

/// Pumps until [finder] matches nothing, e.g. a sheet that is closing.
Future<void> waitForGone(WidgetTester tester, Finder finder, {int frames = 20}) async {
  for (var frame = 0; frame < frames && finder.evaluate().isNotEmpty; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (finder.evaluate().isNotEmpty) debugPrint('GONE-DIAG texts=${onstageTexts()}');
  expect(finder, findsNothing);
}

/// Every [Text] currently on stage, for failure diagnostics.
List<String> onstageTexts() => find.byType(Text).evaluate().map((element) => (element.widget as Text).data).whereType<String>().toList();

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
  // On Android a real device capture (adb screencap through the watcher) is
  // the screenshot, so the in-process capture below is skipped.
  if (Platform.isAndroid && _watcherAlive == true) return;
  if (Platform.isAndroid) _expectRealPhysicalSize(tester, numbered);
  if (Platform.isAndroid && !_surfaceConverted) {
    // Android renders to a SurfaceView that cannot be read back until it is
    // swapped for an image-backed surface; the binding reverts it after
    // every test, so convert once per test.
    await _whilePumping(tester, binding.convertFlutterSurfaceToImage(), 'converting the surface for $numbered');
    _surfaceConverted = true;
    addTearDown(() => _surfaceConverted = false);
    await tester.pump();
  }
  await _whilePumping(tester, binding.takeScreenshot(numbered), 'capturing $numbered');
}

/// Fails [shot] at once when the test view's physical size differs from the
/// real window: the engine drops such frames, so the capture would return a
/// stale frame and then hang (#99). Use [useLogicalWidth] instead.
void _expectRealPhysicalSize(WidgetTester tester, String shot) {
  final window = ui.PlatformDispatcher.instance.implicitView?.physicalSize;
  if (window == null || tester.view.physicalSize == window) return;
  fail('Cannot capture $shot: tester.view.physicalSize ${tester.view.physicalSize} differs from the window $window, '
      'so the engine discards every frame. Use useLogicalWidth() to test a narrow phone.');
}

/// How long one in-app capture may take before the flow fails.
const kShotTimeout = Duration(seconds: 30);

/// Awaits [work] while pumping frames, and fails with [what] after
/// [kShotTimeout] instead of stalling the run.
///
/// Android's capture (FlutterDeviceScreenshot.takeScreenshot) retries until
/// the Flutter view hands it a frame it has not read yet. It asks for one
/// with `scheduleFrame`, but the test binding only draws frames it pumps
/// itself, so on a screen with nothing animating no new frame ever comes
/// and the capture waits forever with the isolate idle (#99, Hindi dark
/// card screen). Pumping until the capture returns always gives it one.
Future<T> _whilePumping<T>(WidgetTester tester, Future<T> work, String what) async {
  var finished = false;
  unawaited(work.then<void>((_) => finished = true, onError: (Object _) => finished = true));
  final deadline = DateTime.now().add(kShotTimeout);
  while (!finished) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out after ${kShotTimeout.inSeconds} s $what (texts on screen: ${onstageTexts().take(12).toList()})');
    await tester.pump(const Duration(milliseconds: 100));
  }
  return work;
}

bool _surfaceConverted = false;

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

/// Hides the soft keyboard, so it covers neither a shot nor the buttons at
/// the foot of a sheet.
Future<void> dropKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await settle(tester, 6);
}

/// Pops the top bottom sheet without relying on where its scrim is: a tall
/// sheet (Hindi, large text, a 360dp phone) leaves no scrim to tap.
Future<void> popSheet(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(BottomSheet).last)).pop();
  await settle(tester, 10);
}

/// Answers "Not now" to the notification and "Alarms & reminders" sheets
/// that saving a reminder can bring up, depending on what the device has
/// already granted.
Future<void> declineReminderPermissionSheets(WidgetTester tester) async {
  for (final title in ["Get reminded before it's due", 'Get reminders on time']) {
    if (hasText(title)) await tapText(tester, 'Not now', frames: 12);
  }
}

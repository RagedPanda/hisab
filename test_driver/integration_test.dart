import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Android package the flows run in.
const String kHisabPackage = 'com.sarv.hisab';

/// `adb` arguments that grant the notification permission before the flows
/// run, so no system prompt covers a dialog mid-flow (flow 29, #86). The
/// device is the one in `ANDROID_SERIAL` when set (adb reads it itself).
List<String> grantNotificationsArgs({String package = kHisabPackage}) =>
    ['shell', 'pm', 'grant', package, 'android.permission.POST_NOTIFICATIONS'];

/// Grants POST_NOTIFICATIONS through adb. Best effort: on iOS, on Android
/// below 13 (not a runtime permission there) or without adb it just logs.
Future<void> grantNotificationPermission() async {
  try {
    final result = await Process.run('adb', grantNotificationsArgs());
    if (result.exitCode != 0) stdout.writeln('WARN: notification permission not granted by adb: ${result.stderr}'.trim());
  } on ProcessException catch (error) {
    stdout.writeln('WARN: adb not available, notification permission not granted: ${error.message}');
  }
}

/// Host-side driver for `flutter drive --driver=test_driver/integration_test.dart`.
///
/// Before the flows reach a notification prompt it grants the Android
/// notification permission ([grantNotificationPermission]); with more than
/// one device attached, set `ANDROID_SERIAL` to the `-d` device.
///
/// Every `binding.takeScreenshot(name)` call made by the in-app suite is
/// delivered here once the run finishes and written as `<name>.png` to
/// `$HISAB_SHOTS_DIR` (default `build/integration_shots`).
Future<void> main() async {
  await grantNotificationPermission();
  final outputDir = Directory(Platform.environment['HISAB_SHOTS_DIR'] ?? 'build/integration_shots');
  await outputDir.create(recursive: true);
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      await File('${outputDir.path}/$name.png').writeAsBytes(bytes, flush: true);
      return true;
    },
  );
}

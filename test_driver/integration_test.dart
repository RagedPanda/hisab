import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Host-side driver for `flutter drive --driver=test_driver/integration_test.dart`.
///
/// Every `binding.takeScreenshot(name)` call made by the in-app suite is
/// delivered here once the run finishes and written as `<name>.png` to
/// `$HISAB_SHOTS_DIR` (default `build/integration_shots`).
Future<void> main() async {
  final outputDir = Directory(Platform.environment['HISAB_SHOTS_DIR'] ?? 'build/integration_shots');
  await outputDir.create(recursive: true);
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      await File('${outputDir.path}/$name.png').writeAsBytes(bytes, flush: true);
      return true;
    },
  );
}

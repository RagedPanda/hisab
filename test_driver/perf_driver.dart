import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

/// Host-side driver for the scroll-performance probe: turns the traced
/// timeline into `build/<reportKey>.timeline_summary.json`.
Future<void> main() => integrationDriver(
      responseDataCallback: (data) async {
        if (data == null) return;
        for (final entry in data.entries) {
          final summary = driver.TimelineSummary.summarize(driver.Timeline.fromJson(entry.value as Map<String, dynamic>));
          await summary.writeTimelineToFile(entry.key, pretty: true, includeSummary: true);
        }
      },
    );

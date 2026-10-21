/// Scroll-performance probe for the Home tab with a seeded database of 300+
/// entries. Run in profile mode so the numbers mean something:
///
/// flutter drive --profile --no-dds --driver=test_driver/perf_driver.dart \
///   --target=integration_test/dashboard_perf_test.dart -d DEVICE
///
/// The driver writes `build/dashboard_scroll.timeline_summary.json` with
/// average / worst frame build and raster times and missed-budget counts.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/debug/demo_seed.dart';
import 'package:integration_test/integration_test.dart';

import 'harness.dart';

const int kPerfEntryCount = 320;
const int kPerfScrollPasses = 6;
const Duration kFlingSettleTime = Duration(milliseconds: 1200);

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Let the engine drive frames at vsync so the fling is rendered as the user would see it.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;

  testWidgets('home scrolls smoothly with $kPerfEntryCount+ entries', (tester) async {
    final app = await createApp();
    addTearDown(app.container.dispose);
    await seedDemoData(app.db, entryCount: kPerfEntryCount);
    await pumpApp(tester, app);
    await settle(tester, 15);

    final scrollable = find.byType(Scrollable).first;
    await binding.traceAction(() async {
      for (var pass = 0; pass < kPerfScrollPasses; pass++) {
        await tester.fling(scrollable, const Offset(0, -900), 2500);
        await Future<void>.delayed(kFlingSettleTime);
        await tester.fling(scrollable, const Offset(0, 900), 2500);
        await Future<void>.delayed(kFlingSettleTime);
      }
    }, reportKey: 'dashboard_scroll');
  });
}

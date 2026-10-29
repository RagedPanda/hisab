import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/features/shell/router.dart';

import 'app_harness.dart' show settle;

/// Opens the real app at [location] on a [size] phone over [container], and
/// sends the shared router home again once the test ends.
Future<void> pumpAt(WidgetTester tester, ProviderContainer container, String location, {Size size = const Size(430, 932)}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(() => appRouter.go('/home'));
  appRouter.go(location);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
  await settle(tester);
}

/// Taps [finder] (scrolling it into view first) and lets the app settle.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester);
}

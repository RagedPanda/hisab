import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/features/expense_editor/expense_editor_screen.dart';
import 'package:hisab/features/shell/router.dart';

import '../core/fake_notification_gateway.dart';
import 'app_harness.dart';

/// Finders and steps shared by the entry editor's widget tests.

final editorScreen = find.byType(ExpenseEditorScreen);
final editorAmountField = find.descendant(of: editorScreen, matching: find.byType(TextField)).first;
final editorSaveButton = find.byKey(const ValueKey('editor.save'));
final _editorScrollable = find.descendant(of: editorScreen, matching: find.byType(Scrollable)).first;

/// Opens the editor at [location] (pushed over home, so saving pops back);
/// [location] is read after [seed], so it can name what the seed created.
Future<ProviderContainer> openEditor(WidgetTester tester, {String Function()? location, Future<void> Function(ProviderContainer container)? seed}) async {
  final container = await pumpApp(tester, seed: seed, overrides: [notificationGatewayProvider.overrideWithValue(FakeNotificationGateway())]);
  appRouter.push(location == null ? '/entry' : location());
  await settle(tester);
  return container;
}

/// The editor body is a lazy list, so [target] is only built once scrolled to.
Future<void> revealInEditor(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 200, scrollable: _editorScrollable);
  await tester.pump();
}

Future<void> tapInEditor(WidgetTester tester, Finder target) async {
  await revealInEditor(tester, target);
  await tester.tap(target);
  await settle(tester);
}

/// The amount sits at the top of the lazy list, so it is only built while scrolled into view.
Future<String> editorAmountText(WidgetTester tester) async {
  tester.state<ScrollableState>(_editorScrollable).position.jumpTo(0);
  await tester.pump();
  return tester.widget<TextField>(editorAmountField).controller!.text;
}

Future<void> enterEditorAmount(WidgetTester tester, String amount) async {
  tester.state<ScrollableState>(_editorScrollable).position.jumpTo(0);
  await tester.pump();
  await enter(tester, editorAmountField, amount);
}

Future<void> saveEditor(WidgetTester tester) async {
  await tester.tap(editorSaveButton);
  await settle(tester);
}

/// Runs a real database [query] outside the fake-async test zone.
Future<T> readDb<T>(WidgetTester tester, Future<T> Function() query) async => (await tester.runAsync(query)) as T;

/// Opens the editor's ⋮ menu and picks the item keyed [itemKey].
Future<void> tapEditorMenu(WidgetTester tester, String itemKey) async {
  await tester.tap(find.byKey(const Key('editor.more')));
  await settle(tester);
  await tester.tap(find.byKey(Key(itemKey)));
  await settle(tester);
}

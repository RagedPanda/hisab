import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/features/expense_editor/expense_editor_screen.dart';
import 'package:hisab/features/shell/router.dart';

import '../support/app_harness.dart';

/// The shell's add-entry button; Groups shows its own New group button.
final _addEntryButton = find.widgetWithIcon(FloatingActionButton, Icons.add);

String _location() => appRouter.routerDelegate.currentConfiguration.uri.toString();

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await settle(tester);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('the tabs switch branches and the add button shows only on Home and Entries', (tester) async {
    await pumpApp(tester);
    expect(_addEntryButton, findsOneWidget);

    await _tapTab(tester, 'Entries');
    expect(_location(), '/transactions');
    expect(_addEntryButton, findsOneWidget);

    await _tapTab(tester, 'Groups');
    expect(_location(), '/groups');
    expect(_addEntryButton, findsNothing);

    await _tapTab(tester, 'Settings');
    expect(_location(), '/settings');
    expect(_addEntryButton, findsNothing);
    await _tapTab(tester, 'Settings');
    expect(_location(), '/settings', reason: 'tapping the open tab again keeps it, back at its first page');

    await _tapTab(tester, 'Home');
    expect(_location(), '/home');
  });

  testWidgets('Back on another tab returns to Home instead of leaving the app', (tester) async {
    await pumpApp(tester);
    await _tapTab(tester, 'Groups');
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(_location(), '/home');
  });

  testWidgets('the add button opens the entry editor', (tester) async {
    await pumpApp(tester);
    await tester.tap(_addEntryButton);
    await settle(tester);
    expect(find.byType(ExpenseEditorScreen), findsOneWidget);
    appRouter.go('/home');
    await settle(tester);
  });
}

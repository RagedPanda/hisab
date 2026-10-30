import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/features/shell/router.dart';

import '../support/app_harness.dart';

/// The editor opened on its own by hisab://entry?kind=expense (Quick
/// Settings tile, Add expense launcher shortcut, notification).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final editorTitle = find.text('New entry');

  Future<void> openFromOutside(WidgetTester tester) async {
    appRouter.go('/entry?kind=expense');
    await settle(tester);
    expect(editorTitle, findsOneWidget);
  }

  testWidgets('shows a back arrow that goes Home', (tester) async {
    await pumpApp(tester);
    await openFromOutside(tester);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(editorTitle, findsNothing);
    expect(appRouter.routerDelegate.currentConfiguration.uri.path, '/home');
  });

  testWidgets('the back arrow asks before dropping a typed amount', (tester) async {
    await pumpApp(tester);
    await openFromOutside(tester);
    await enter(tester, find.byType(TextField).first, '250');
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.text('Discard this entry?'), findsOneWidget);
  });

  testWidgets('asks for the keypad again once the window gets focus', (tester) async {
    await pumpApp(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await openFromOutside(tester);
    tester.testTextInput.log.clear();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.testTextInput.log.map((call) => call.method), contains('TextInput.show'));

    tester.testTextInput.log.clear();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.testTextInput.log.map((call) => call.method), isNot(contains('TextInput.show')), reason: 'only once, on open');
  });

  testWidgets('opened from inside the app it keeps the usual back arrow', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(editorTitle, findsNothing);
  });
}

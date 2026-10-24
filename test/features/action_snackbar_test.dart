import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/features/shell/widgets/common.dart';

void main() {
  Future<ScaffoldMessengerState> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox.expand())));
    return tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger));
  }

  testWidgets('#72: the SMS permission snackbar with a Settings action times out on its own', (tester) async {
    final messenger = await pumpHost(tester);
    var opened = 0;
    showActionSnackBar(messenger, message: 'SMS permission denied', actionLabel: 'Settings', onAction: () => opened++);
    await tester.pumpAndSettle();
    expect(find.text('SMS permission denied'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    expect(opened, 1);

    showActionSnackBar(messenger, message: 'SMS permission denied', actionLabel: 'Settings', onAction: () => opened++);
    await tester.pumpAndSettle();
    // The display timer starts once the entrance animation has finished.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text('SMS permission denied'), findsNothing, reason: 'it no longer stays up until dismissed');
  });

  test('every snackbar with an action in lib/ goes through showActionSnackBar', () {
    const helperFile = 'lib/features/shell/widgets/common.dart';
    final offenders = [
      for (final file in Directory('lib').listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.dart') && !file.path.endsWith(helperFile) && file.readAsStringSync().contains('SnackBarAction(')) file.path,
    ];
    expect(offenders, isEmpty, reason: 'a SnackBarAction outside the helper stays up forever since Flutter 3.29');
  });
}

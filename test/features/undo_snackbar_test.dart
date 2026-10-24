import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/features/shell/widgets/common.dart';

void main() {
  Future<ScaffoldMessengerState> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox.expand())));
    return tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger));
  }

  testWidgets('an Undo snackbar times out on its own', (tester) async {
    final messenger = await pumpHost(tester);
    showUndoSnackBar(messenger, message: 'Payment removed', undoLabel: 'Undo', onUndo: () {});
    await tester.pumpAndSettle();
    expect(find.text('Payment removed'), findsOneWidget);
    // The display timer starts once the entrance animation has finished.
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text('Payment removed'), findsNothing);
  });

  testWidgets('a new Undo snackbar replaces the previous one instead of queueing', (tester) async {
    final messenger = await pumpHost(tester);
    var undone = '';
    showUndoSnackBar(messenger, message: 'Recorded payment', undoLabel: 'Undo', onUndo: () => undone = 'recorded');
    await tester.pump();
    showUndoSnackBar(messenger, message: 'Payment removed', undoLabel: 'Undo', onUndo: () => undone = 'removed');
    await tester.pumpAndSettle();
    expect(find.text('Recorded payment'), findsNothing);
    expect(find.text('Payment removed'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    expect(undone, 'removed');
  });
}

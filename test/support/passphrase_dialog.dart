import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fills the open backup passphrase dialog and presses its main button. A
/// new-passphrase dialog also gets [confirmation] (the same by default).
/// Pumps once; callers settle as their screen needs.
Future<void> answerPassphraseDialog(WidgetTester tester, String passphrase, {String? confirmation}) async {
  final fields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
  await tester.enterText(fields.first, passphrase);
  if (fields.evaluate().length > 1) await tester.enterText(fields.at(1), confirmation ?? passphrase);
  await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
  await tester.pump();
}

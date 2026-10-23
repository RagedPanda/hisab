import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/features/expense_editor/expense_editor_screen.dart';

import '../app_flow_test.dart' show pumpApp;

bool typingFocused() => FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null;

/// Regression test for #56: the amount field autofocused again whenever the
/// lazy ListView rebuilt it, so closing the Repeat sheet reopened the keyboard
/// and scrolled the editor up, away from the Repeat tile.

/// Pumps frames while a fake keyboard follows text focus, as on a device:
/// focusing a text field raises it (300 logical px) and unfocusing drops it.
Future<void> pumpWithKeyboard(WidgetTester tester, [int frames = 12]) async {
  for (var frame = 0; frame < frames; frame++) {
    final typing = typingFocused();
    tester.view.viewInsets = FakeViewPadding(bottom: typing ? 300 * tester.view.devicePixelRatio : 0);
    await tester.pump(const Duration(milliseconds: 100));
  }
}

ScrollPosition editorScroll(WidgetTester tester) => tester.state<ScrollableState>(find.descendant(of: find.byType(ExpenseEditorScreen), matching: find.byType(Scrollable)).first).position;

bool onstage(Finder finder) => finder.hitTestable().evaluate().isNotEmpty;

void main() {
  testWidgets('the Repeat tile stays on screen after the Repeat sheet closes', (tester) async {
    addTearDown(tester.view.resetViewInsets);
    await pumpApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await pumpWithKeyboard(tester);
    expect(typingFocused(), isTrue, reason: 'a new entry opens with the amount field focused');
    final amountField = find.descendant(of: find.byType(ExpenseEditorScreen), matching: find.byType(TextField)).first;
    await tester.enterText(amountField, '15000');
    await pumpWithKeyboard(tester);
    await tester.tap(find.text('Choose category'));
    await pumpWithKeyboard(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Search categories'), 'rent');
    await pumpWithKeyboard(tester);
    await tester.tap(find.text('Rent'));
    await pumpWithKeyboard(tester);

    final repeatTile = find.byKey(const ValueKey('editor.repeat'));
    // Scroll the way the integration harness does: jumps, not a drag, so the
    // keyboard stays up (a drag would dismiss it).
    final position = editorScroll(tester);
    while (repeatTile.evaluate().isEmpty && position.pixels < position.maxScrollExtent) {
      position.jumpTo((position.pixels + 200).clamp(0, position.maxScrollExtent));
      await tester.pump();
    }
    await tester.ensureVisible(repeatTile);
    await pumpWithKeyboard(tester);
    expect(onstage(repeatTile), isTrue);
    await tester.tap(repeatTile);
    await pumpWithKeyboard(tester);
    await tester.tap(find.byKey(const ValueKey('repeat.done')));
    await pumpWithKeyboard(tester, 20);

    expect(find.byKey(const ValueKey('repeat.done')), findsNothing);
    expect(onstage(repeatTile), isTrue, reason: 'closing the sheet must not scroll the editor away from the tile');
    expect(typingFocused(), isFalse, reason: 'closing the sheet must not reopen the keyboard');
  });
}

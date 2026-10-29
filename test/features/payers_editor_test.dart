import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/money.dart';
import 'package:hisab/features/split/payers_editor.dart';

import '../support/split_harness.dart';

void main() {
  final members = [testMember('me', 'You', isMe: true), testMember('priya', 'Priya')];

  /// A payers editor for a ₹100 bill that keeps its own amounts and reports each change.
  Widget payers({required Map<String, int> initial, required ValueChanged<Map<String, int>> onChanged}) {
    var amounts = initial;
    return StatefulBuilder(
      builder: (context, setState) => PayersEditor(
        totalMinor: 10000,
        members: members,
        amounts: amounts,
        moneyFormat: MoneyFormat.inr,
        onChanged: (changed) {
          onChanged(changed);
          setState(() => amounts = changed);
        },
      ),
    );
  }

  Color? assignedColor(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('payers-assigned'))).style?.color;

  String fieldText(WidgetTester tester, String memberId) =>
      tester.widget<EditableText>(find.descendant(of: find.byKey(Key('payer-amount-$memberId')), matching: find.byType(EditableText))).controller.text;

  testWidgets('the assigned line stays red until the amounts add up to the bill', (tester) async {
    var latest = const <String, int>{};
    await pumpLocalized(tester, payers(initial: const {'me': 6000}, onChanged: (amounts) => latest = amounts));
    final errorColor = Theme.of(tester.element(find.byType(PayersEditor))).colorScheme.error;

    expect(find.text('Enter how much each person paid.'), findsOneWidget);
    expect((fieldText(tester, 'me'), fieldText(tester, 'priya')), ('60', ''));
    expect(find.text('₹60 of ₹100 assigned'), findsOneWidget);
    expect(assignedColor(tester), errorColor);

    await tester.enterText(find.byKey(const Key('payer-amount-priya')), '40');
    await tester.pumpAndSettle();
    expect(latest, {'me': 6000, 'priya': 4000});
    expect(find.text('₹100 of ₹100 assigned'), findsOneWidget);
    expect(assignedColor(tester), isNot(errorColor));

    await tester.enterText(find.byKey(const Key('payer-amount-priya')), '');
    await tester.pumpAndSettle();
    expect(latest['priya'], 0, reason: 'a cleared field counts as nothing paid');
  });
}

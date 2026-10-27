import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/domain/split/split_calculator.dart';
import 'package:hisab/features/split/split_editor.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';
import 'package:hisab/core/money.dart';

void main() {
  Member member(String id, String name, {bool isMe = false}) =>
      Member(updatedAt: DateTime(2026, 10, 1), id: id, groupId: 'g1', name: name, isMe: isMe, weight: 1);

  testWidgets('#58: a by-item split opens with every method chip built and By item selected, at 360dp', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final members = [member('me', 'You', isMe: true), member('rahul', 'Rahul')];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SplitEditor(
            totalMinor: 45000,
            members: members,
            method: SplitMethod.byItem,
            inputs: const [],
            moneyFormat: MoneyFormat.inr,
            items: const [
              ItemSplitInput(amountMinor: 30000, memberIds: ['me', 'rahul'], label: 'Pizza'),
              ItemSplitInput(amountMinor: 15000, memberIds: ['rahul'], label: 'Coke'),
            ],
            onMethodChanged: (_) {},
            onInputsChanged: (_) {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    for (final method in SplitMethod.values) {
      final chip = find.byKey(Key('split-method-${method.name}'));
      expect(chip, findsOneWidget, reason: '${method.name} chip is built');
      final rect = tester.getRect(chip);
      expect(rect.right <= 360 && rect.left >= 0, isTrue, reason: '${method.name} chip is on screen');
    }
    expect(tester.widget<ChoiceChip>(find.byKey(const Key('split-method-byItem'))).selected, isTrue);
    final chipKeys = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).map((chip) => chip.key).toList();
    expect(chipKeys.first, const Key('split-method-byItem'), reason: 'By item is the first option when there are items');
    expect(tester.takeException(), isNull, reason: 'no overflow at 360dp');
  });

  test('By item comes first when the expense has items, and is hidden otherwise', () {
    expect(splitMethodOptions(hasItems: true), [
      SplitMethod.byItem,
      SplitMethod.equal,
      SplitMethod.exact,
      SplitMethod.percent,
      SplitMethod.shares,
      SplitMethod.adjustment,
    ]);
    expect(splitMethodOptions(hasItems: false), [
      SplitMethod.equal,
      SplitMethod.exact,
      SplitMethod.percent,
      SplitMethod.shares,
      SplitMethod.adjustment,
    ]);
  });
}

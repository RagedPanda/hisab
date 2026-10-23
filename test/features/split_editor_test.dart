import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/domain/split/split_calculator.dart';
import 'package:hisab/features/split/split_editor.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';

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
            symbol: '₹',
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
    expect(tester.takeException(), isNull, reason: 'no overflow at 360dp');
  });
}

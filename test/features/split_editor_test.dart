import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/domain/split/split_calculator.dart';
import 'package:hisab/features/split/split_editor.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';
import 'package:hisab/core/money.dart';
import 'package:hisab/domain/money/money_format_resolver.dart';

import '../support/split_harness.dart';

/// A split editor that keeps its own method and inputs, like the expense
/// editor does, and reports every change through [onInputs].
Widget editableSplit({required List<Member> members, required SplitMethod initialMethod, List<SplitInput> initialInputs = const [], int totalMinor = 10000, ValueChanged<List<SplitInput>>? onInputs, ValueChanged<SplitMethod>? onMethod}) {
  var method = initialMethod;
  var inputs = initialInputs;
  return StatefulBuilder(
    builder: (context, setState) => SplitEditor(
      totalMinor: totalMinor,
      members: members,
      method: method,
      inputs: inputs,
      moneyFormat: MoneyFormat.inr,
      onMethodChanged: (picked) {
        onMethod?.call(picked);
        setState(() {
          method = picked;
          inputs = defaultSplitInputs(members, picked);
        });
      },
      onInputsChanged: (changed) {
        onInputs?.call(changed);
        setState(() => inputs = changed);
      },
    ),
  );
}

Future<void> pickMethod(WidgetTester tester, SplitMethod method) async {
  await tester.tap(find.byKey(const Key('split-method-picker')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('split-method-${method.name}')));
  await tester.pumpAndSettle();
}

void main() {
  Member member(String id, String name, {bool isMe = false}) =>
      Member(updatedAt: DateTime(2026, 10, 1), id: id, groupId: 'g1', name: name, isMe: isMe, weight: 1);

  testWidgets('#58: a by-item split shows By item and offers every method, at 360dp', (tester) async {
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
    expect(find.byKey(const Key('split-method-picker')), findsOneWidget);
    expect(find.text('By item'), findsOneWidget, reason: 'the row shows the chosen method');
    await tester.tap(find.byKey(const Key('split-method-picker')));
    await tester.pumpAndSettle();
    for (final method in SplitMethod.values) {
      expect(find.byKey(Key('split-method-${method.name}')), findsOneWidget, reason: '${method.name} is offered in the sheet');
    }
    final optionKeys = tester.widgetList<ListTile>(find.descendant(of: find.byType(BottomSheet), matching: find.byType(ListTile))).map((tile) => tile.key).toList();
    expect(optionKeys.first, const Key('split-method-byItem'), reason: 'By item is the first option when there are items');
    expect(tester.widget<ListTile>(find.byKey(const Key('split-method-byItem'))).selected, isTrue);
    expect(tester.takeException(), isNull, reason: 'no overflow at 360dp');
  });

  testWidgets('#90: an exact yen split shows and takes whole yen only', (tester) async {
    final members = [member('me', 'You', isMe: true), member('rahul', 'Rahul')];
    var latest = const <SplitInput>[];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SplitEditor(
            totalMinor: 300000,
            members: members,
            method: SplitMethod.exact,
            inputs: const [SplitInput(memberId: 'me', amountMinor: 100050), SplitInput(memberId: 'rahul', amountMinor: 199950)],
            moneyFormat: resolveMoneyFormat(currencyCode: 'JPY'),
            onMethodChanged: (_) {},
            onInputsChanged: (inputs) => latest = inputs,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final fieldTexts = tester.widgetList<TextField>(find.byType(TextField)).map((field) => field.controller?.text).toList();
    expect(fieldTexts, ['1001', '2000'], reason: 'seeded with rounded whole yen, not "1000.50"');
    await tester.enterText(find.byType(TextField).first, '1.5');
    expect(latest.firstWhere((input) => input.memberId == 'me').amountMinor, 1500, reason: 'the decimal point is filtered out');
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

  group('editing each method', () {
    final members = [testMember('me', 'You', isMe: true), testMember('rahul', 'Rahul')];

    testWidgets('equal: unticking a member leaves them out of the split', (tester) async {
      var latest = const <SplitInput>[];
      await pumpLocalized(tester, editableSplit(members: members, initialMethod: SplitMethod.equal, initialInputs: defaultSplitInputs(members, SplitMethod.equal), onInputs: (inputs) => latest = inputs));
      expect(find.text('Splits ₹100 across 2 people'), findsOneWidget);

      await tester.tap(find.byType(Checkbox).last);
      await tester.pumpAndSettle();
      expect(latest.firstWhere((input) => input.memberId == 'rahul').included, isFalse);
      expect(find.text('Splits ₹100 across 1 people'), findsOneWidget);
    });

    testWidgets('a change to a member with no input yet adds one', (tester) async {
      var latest = const <SplitInput>[];
      await pumpLocalized(tester, editableSplit(members: members, initialMethod: SplitMethod.equal, onInputs: (inputs) => latest = inputs));

      await tester.tap(find.byType(Checkbox).last);
      await tester.pumpAndSettle();
      expect(latest.single.memberId, 'rahul');
      expect(latest.single.included, isFalse);
      expect(find.text('Select at least one person'), findsOneWidget);
    });

    testWidgets('percent: fields start at an even share and an uneven total says what is left', (tester) async {
      var latest = const <SplitInput>[];
      await pumpLocalized(tester, editableSplit(members: members, initialMethod: SplitMethod.equal, onInputs: (inputs) => latest = inputs));
      await pickMethod(tester, SplitMethod.percent);
      expect(find.text('Percentages'), findsOneWidget);
      expect(tester.widgetList<TextField>(find.byType(TextField)).map((field) => field.controller!.text), ['50', '50']);

      await tester.enterText(find.byType(TextField).first, '40');
      await tester.pumpAndSettle();
      expect(latest.firstWhere((input) => input.memberId == 'me').weight, 40);
      expect(find.text('10% left to assign'), findsOneWidget);
    });

    testWidgets('shares: fractional weights show as typed and change the split', (tester) async {
      var latest = const <SplitInput>[];
      await pumpLocalized(tester, editableSplit(
        members: members,
        initialMethod: SplitMethod.shares,
        initialInputs: const [SplitInput(memberId: 'me', weight: 1.5), SplitInput(memberId: 'rahul', weight: 0)],
        onInputs: (inputs) => latest = inputs,
      ));
      expect(tester.widgetList<TextField>(find.byType(TextField)).map((field) => field.controller!.text), ['1.5', '']);

      await tester.enterText(find.byType(TextField).last, '2.5');
      await tester.pumpAndSettle();
      expect(latest.firstWhere((input) => input.memberId == 'rahul').weight, 2.5);
      expect(find.text('Splits ₹100 across 2 people'), findsOneWidget);
    });

    testWidgets('adjustment: an extra amount and an untick are both kept', (tester) async {
      var latest = const <SplitInput>[];
      await pumpLocalized(tester, editableSplit(members: members, initialMethod: SplitMethod.adjustment, initialInputs: defaultSplitInputs(members, SplitMethod.adjustment), onInputs: (inputs) => latest = inputs));

      await tester.enterText(find.byType(TextField).first, '20');
      await tester.pumpAndSettle();
      expect(latest.firstWhere((input) => input.memberId == 'me').amountMinor, 2000);
      await tester.tap(find.byType(Checkbox).last);
      await tester.pumpAndSettle();
      expect(latest.firstWhere((input) => input.memberId == 'rahul').included, isFalse);
    });

    testWidgets('exact: amounts that fall short are reported in money', (tester) async {
      var latest = const <SplitInput>[];
      await pumpLocalized(tester, editableSplit(members: members, initialMethod: SplitMethod.equal, onInputs: (inputs) => latest = inputs));
      await pickMethod(tester, SplitMethod.exact);

      await tester.enterText(find.byType(TextField).first, '30');
      await tester.pumpAndSettle();
      expect(latest.firstWhere((input) => input.memberId == 'me').amountMinor, 3000);
      expect(find.text('₹70 left to assign'), findsOneWidget);
    });

    testWidgets('picking the current method again, or dismissing the sheet, changes nothing', (tester) async {
      final picked = <SplitMethod>[];
      await pumpLocalized(tester, editableSplit(members: members, initialMethod: SplitMethod.equal, onMethod: picked.add));

      await pickMethod(tester, SplitMethod.equal);
      await tester.tap(find.byKey(const Key('split-method-picker')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(picked, isEmpty);
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  test('every split error reads as a sentence with its amount, percent or item', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final messages = {
      for (final code in SplitErrorCode.values) code: splitErrorMessage(SplitError(code, amountMinor: 2500, percent: 12.5, label: 'Coke'), l10n, MoneyFormat.inr),
    };
    expect(messages.values.toSet(), hasLength(SplitErrorCode.values.length), reason: 'each code has its own message');
    expect(messages[SplitErrorCode.amountOver], contains('₹25'));
    expect(messages[SplitErrorCode.itemsExceed], contains('₹25'));
    expect(messages[SplitErrorCode.adjustmentsExceed], contains('₹25'));
    expect(messages[SplitErrorCode.percentOver], contains('12.50'));
    expect(messages[SplitErrorCode.itemUnassigned], 'Assign "Coke" to someone');
    expect(splitErrorMessage(const SplitError(SplitErrorCode.itemUnassigned), l10n, MoneyFormat.inr), 'Assign "item" to someone', reason: 'an unnamed item is called "item"');
    expect(splitErrorMessage(const SplitError(SplitErrorCode.percentLeft, percent: 10), l10n, MoneyFormat.inr), '10% left to assign', reason: 'whole percentages drop the .00');
  });

  test('default inputs start percentages even and shares from member weights', () {
    final members = [testMember('me', 'You', isMe: true, weight: 2), testMember('rahul', 'Rahul', weight: 0)];
    expect([for (final input in defaultSplitInputs(members, SplitMethod.percent)) input.weight], [50, 50]);
    expect([for (final input in defaultSplitInputs(members, SplitMethod.shares)) input.weight], [2, 1], reason: 'a zero weight counts as one share');
    expect([for (final input in defaultSplitInputs(members, SplitMethod.exact)) input.weight], [0, 0]);
  });
}

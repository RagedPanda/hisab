import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/money/money_format.dart';
import 'package:hisab/features/expense_editor/calculator_sheet.dart';
import 'package:hisab/l10n/l10n.dart';

/// The amount field's calculator keypad: what it shows while an expression is
/// typed, when "Use" is allowed and what it hands back.
void main() {
  /// Opens the sheet from a button and records what it returned in [results].
  Future<void> openCalculator(WidgetTester tester, {String initialAmountText = '', required List<int?> results}) async {
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(await showCalculatorSheet(context, initialAmountText: initialAmountText, moneyFormat: MoneyFormat.inr)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, List<String> keyIds) async {
    for (final keyId in keyIds) {
      await tester.tap(find.byKey(ValueKey('calc.key.$keyId')));
      await tester.pump();
    }
  }

  String display(WidgetTester tester) => tester.widget<Text>(find.byKey(const ValueKey('calc.display'))).data!;
  String result(WidgetTester tester) => tester.widget<Text>(find.byKey(const ValueKey('calc.result'))).data!;
  FilledButton useButton(WidgetTester tester) => tester.widget<FilledButton>(find.byKey(const ValueKey('calc.use')));
  TextButton clearButton(WidgetTester tester) => tester.widget<TextButton>(find.byKey(const ValueKey('calc.clear')));

  testWidgets('an empty keypad shows 0 and cannot be used or cleared', (tester) async {
    await openCalculator(tester, results: []);

    expect(display(tester), '0');
    expect(result(tester), ' ');
    expect(useButton(tester).onPressed, isNull);
    expect(clearButton(tester).onPressed, isNull);
    expect(find.text('Use ₹0'), findsOneWidget);
  });

  testWidgets('typing a sum previews the total and Use hands it back in minor units', (tester) async {
    final results = <int?>[];
    await openCalculator(tester, results: results);

    await press(tester, ['1', '2', 'plus', '3', 'dot', '5']);
    expect(display(tester), '12+3.5');
    expect(result(tester), '= ₹15.50');

    await tester.tap(find.byKey(const ValueKey('calc.use')));
    await tester.pumpAndSettle();
    expect(results, [1550]);
    expect(find.byKey(const ValueKey('calc.display')), findsNothing, reason: 'the sheet closes');
  });

  testWidgets('every key reaches the expression', (tester) async {
    await openCalculator(tester, results: []);

    await press(tester, ['7', '8', '9', 'divide', '4', '5', '6', 'times', '0', 'minus', '1']);
    expect(display(tester), allOf(contains('789'), contains('456'), contains('0'), endsWith('1')));
    await press(tester, ['back']);
    expect(display(tester), isNot(endsWith('1')), reason: 'backspace drops the last character');
  });

  testWidgets('the field amount seeds the keypad', (tester) async {
    await openCalculator(tester, initialAmountText: '250', results: []);
    expect(display(tester), '250');
    expect(result(tester), '= ₹250');
  });

  testWidgets('dividing by zero, a result below zero and a huge result say why Use is off', (tester) async {
    await openCalculator(tester, results: []);

    await press(tester, ['8', 'divide', '0']);
    expect(result(tester), "Can't divide by zero");
    expect(useButton(tester).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('calc.clear')));
    await tester.pump();
    expect(display(tester), '0');

    await press(tester, ['2', 'minus', '5']);
    expect(result(tester), 'The result is below zero');

    await tester.longPress(find.byKey(const ValueKey('calc.key.back')));
    await tester.pump();
    expect(display(tester), '0', reason: 'a long press on backspace clears everything');

    await press(tester, ['9', '9', '9', '9', '9', '9', '9', '9', '9', 'times', '9', '9', '9', '9', '9', '9']);
    expect(result(tester), 'The result is too large');
    expect(useButton(tester).onPressed, isNull);
  });

  testWidgets('dismissing the sheet returns nothing', (tester) async {
    final results = <int?>[];
    await openCalculator(tester, results: results);
    await press(tester, ['5']);

    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();
    expect(results, [null]);
  });
}

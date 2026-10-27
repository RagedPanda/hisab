import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/money/money_format.dart';
import 'package:hisab/domain/money/money_format_resolver.dart';
import 'package:hisab/features/expense_editor/item_row.dart';
import 'package:hisab/l10n/l10n.dart';

Future<void> pumpRow(
  WidgetTester tester, {
  required bool showNameError,
  String name = '',
  int unitPriceMinor = 7500,
  MoneyFormat moneyFormat = MoneyFormat.inr,
  ValueChanged<ItemDraft>? onChanged,
}) async {
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
        body: ItemRow(
          draft: ItemDraft(name: name, quantity: 0.5, unitPriceMinor: unitPriceMinor),
          units: const [],
          moneyFormat: moneyFormat,
          showNameError: showNameError,
          onChanged: onChanged ?? (_) {},
          onRemove: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('name field is a labelled, discoverable input', (tester) async {
    await pumpRow(tester, showNameError: false);
    // The "Item name" label advertises the field as an input, not static text.
    expect(find.widgetWithText(TextField, 'Item name'), findsOneWidget);
    expect(find.text('Required'), findsNothing);
  });

  testWidgets('a blocked save flags the empty name field in red', (tester) async {
    await pumpRow(tester, showNameError: true);
    expect(find.text('Required'), findsOneWidget, reason: 'the offending field is highlighted, not just a snackbar');
  });

  testWidgets('a named row shows no error even when errors are flagged', (tester) async {
    await pumpRow(tester, showNameError: false, name: 'Milk');
    expect(find.text('Required'), findsNothing);
  });

  testWidgets('#90: a yen price shows and takes whole yen only', (tester) async {
    final changes = <ItemDraft>[];
    await pumpRow(tester, showNameError: false, unitPriceMinor: 7550, moneyFormat: resolveMoneyFormat(currencyCode: 'JPY'), onChanged: changes.add);
    final price = find.byWidgetPredicate((widget) => widget is TextField && widget.controller?.text == '76');
    expect(price, findsOneWidget, reason: 'seeded with the rounded whole yen it displays, not "75.50"');
    expect(tester.widget<TextField>(price).keyboardType, const TextInputType.numberWithOptions(), reason: 'no decimal key for yen');
    await tester.enterText(price, '1.5');
    expect(changes.last.unitPriceMinor, 1500, reason: 'the decimal point is filtered out, so the field holds whole yen');
  });

  testWidgets('a rupee price keeps its paise', (tester) async {
    await pumpRow(tester, showNameError: false, unitPriceMinor: 7550);
    final price = find.byWidgetPredicate((widget) => widget is TextField && widget.controller?.text == '75.50');
    expect(price, findsOneWidget);
    expect(tester.widget<TextField>(price).keyboardType, const TextInputType.numberWithOptions(decimal: true));
  });
}

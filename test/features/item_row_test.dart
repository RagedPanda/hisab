import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/money/money_format.dart';
import 'package:hisab/features/expense_editor/item_row.dart';
import 'package:hisab/l10n/l10n.dart';

Future<void> pumpRow(WidgetTester tester, {required bool showNameError, String name = ''}) async {
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
          draft: ItemDraft(name: name, quantity: 0.5, unitPriceMinor: 7500),
          units: const [],
          moneyFormat: MoneyFormat.inr,
          showNameError: showNameError,
          onChanged: (_) {},
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
}

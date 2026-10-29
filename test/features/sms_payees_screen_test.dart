import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/domain/sms/payee_category_memory.dart';
import 'package:hisab/features/sms/sms_payees_screen.dart';

import '../support/app_harness.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('with nothing remembered the screen explains how payees are learnt', (tester) async {
    final container = await createContainer();
    await pumpScreen(tester, container, const SmsPayeesScreen());
    expect(find.text('No payees remembered yet'), findsOneWidget);
  });

  testWidgets('lists each remembered payee with its category, and Forget removes one', (tester) async {
    final container = await createContainer();
    await tester.runAsync(() async {
      final groceries = (await container.read(categoriesRepositoryProvider).findBySeedKey('groceries'))!;
      final payees = container.read(payeeCategoryRepositoryProvider);
      await payees.remember(kind: kPayeeExpense, raw: 'ramesh@okaxis', categoryId: groceries.id);
      await payees.remember(kind: kPayeeExpense, raw: 'suresh@ybl', categoryId: 'a-deleted-category');
    });
    await pumpScreen(tester, container, const SmsPayeesScreen());

    expect(find.text('Categories you chose for a payee, used for their next SMS'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget, reason: 'a payee whose category is gone shows a plain label');
    expect(find.byIcon(Icons.label_off_outlined), findsOneWidget);

    final firstPayee = (tester.widget(find.byType(ListTile).first) as ListTile).title! as Text;
    final name = firstPayee.data!;
    await tester.tap(find.byTooltip('Forget $name'));
    await pumpWithDatabase(tester);
    expect(find.text('$name forgotten'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
  });
}

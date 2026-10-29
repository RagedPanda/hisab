import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/features/spending_calendar/spending_calendar_screen.dart';

import '../support/app_harness.dart' show createContainer;
import '../support/screen_harness.dart';
import '../support/seed.dart';

BoxDecoration _cellDecoration(WidgetTester tester, int day) => tester
    .widget<Container>(find.descendant(of: find.byKey(ValueKey('spending.calendar.day.$day')), matching: find.byType(Container)).first)
    .decoration! as BoxDecoration;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('Entries opens a month shaded by spend, and a day lists its entries', (tester) async {
    final container = await createContainer();
    final now = DateTime.now();
    await tester.runAsync(() async {
      await seedEntry(container, id: 'milk', payee: 'Gwala Ji', amountMinor: 6000, occurredAt: DateTime(now.year, now.month, 1, 9));
      await seedEntry(container, id: 'rent', payee: 'Landlord', amountMinor: 2000000, occurredAt: DateTime(now.year, now.month, 2, 11));
      await seedEntry(container, id: 'salary', payee: 'Employer', amountMinor: 9000000, kind: 'income', occurredAt: DateTime(now.year, now.month, 3, 10));
    });
    await pumpAt(tester, container, '/transactions');

    await tapAndSettle(tester, find.byKey(const ValueKey('entries.calendar')));
    expect(find.byType(SpendingCalendarScreen), findsOneWidget);
    expect(find.text('₹20,060 spent'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('spending.calendar.day.1')), matching: find.text('60')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('spending.calendar.day.2')), matching: find.text('20K')), findsOneWidget);
    expect(_cellDecoration(tester, 2).color!.a, greaterThan(_cellDecoration(tester, 1).color!.a));
    expect(_cellDecoration(tester, 3).color, isNull, reason: 'income is not spend');

    await tapAndSettle(tester, find.byKey(const ValueKey('spending.calendar.day.2')));
    expect(find.text('Landlord'), findsOneWidget);
    expect(find.text('Gwala Ji'), findsNothing);
    expect(tester.widget<Text>(find.byKey(const ValueKey('spending.calendar.dayTotal'))).data, '₹20,000');
  });

  testWidgets('a day with nothing spent says so, and the month can be stepped', (tester) async {
    final container = await createContainer();
    await pumpAt(tester, container, kSpendingCalendarRoute);
    expect(find.byKey(const ValueKey('spending.calendar.dayEmpty')), findsOneWidget);
    expect(find.text('₹0 spent'), findsOneWidget);

    final shown = tester.widget<Text>(find.byKey(const ValueKey('spending.calendar.month'))).data;
    await tapAndSettle(tester, find.byTooltip('Previous month'));
    expect(tester.widget<Text>(find.byKey(const ValueKey('spending.calendar.month'))).data, isNot(shown));
  });
}

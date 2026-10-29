import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/domain/stats/month_summary.dart';
import 'package:hisab/features/dashboard/dashboard_keys.dart';
import 'package:hisab/features/dashboard/dashboard_providers.dart';
import 'package:hisab/features/dashboard/widgets/hero_card.dart';

import '../support/app_harness.dart';

/// October 2026 against September, with [expense] spent now and
/// [previousExpense] last month.
HeroData _hero({required int expense, int income = 0, required int previousExpense}) => HeroData(
      summary: MonthSummary(expense: expense, income: income, previousExpense: previousExpense, daysElapsed: 24, daysInMonth: 31, elapsedFraction: 0.77),
      range: DateRange(DateTime(2026, 10, 1), DateTime(2026, 11, 1)),
      previousRange: DateRange(DateTime(2026, 9, 1), DateTime(2026, 10, 1)),
    );

Future<void> _pumpHero(WidgetTester tester, HeroData hero) async {
  final container = await createContainer(overrides: [heroDataProvider.overrideWithValue(AsyncData(hero))]);
  await pumpScreen(tester, container, const Scaffold(body: Padding(padding: EdgeInsets.all(16), child: HeroCard())), size: const Size(430, 932));
  await tester.pumpAndSettle();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('less than last month reads as down, and a tap opens Entries', (tester) async {
    await _pumpHero(tester, _hero(expense: 500000, previousExpense: 1000000));
    expect(find.text('▼ 50% vs Sep'), findsOneWidget);

    await tester.tap(find.byKey(kHeroCardKey));
    await tester.pumpAndSettle();
    expect(find.text(openedLocation('/transactions')), findsOneWidget);
  });

  testWidgets('the same as last month says so', (tester) async {
    await _pumpHero(tester, _hero(expense: 500000, previousExpense: 500000));
    expect(find.text('Same as Sep'), findsOneWidget);
  });

  testWidgets('a long press copies the month total', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await _pumpHero(tester, _hero(expense: 123450, previousExpense: 0));

    await tester.longPress(find.byKey(kHeroCardKey));
    await tester.pump();
    expect(copied, ['1234.50']);
    expect(find.text('Copied'), findsOneWidget);
  });

  testWidgets('an empty month offers to add the first entry', (tester) async {
    await _pumpHero(tester, _hero(expense: 0, previousExpense: 0));
    expect(find.text('Nothing spent yet this month'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Add your first entry'));
    await tester.pumpAndSettle();
    expect(find.text(openedLocation('/entry')), findsOneWidget);
  });
}

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/domain/stats/spend_series.dart';
import 'package:hisab/domain/stats/trend.dart';
import 'package:hisab/features/dashboard/dashboard_keys.dart';
import 'package:hisab/features/dashboard/dashboard_providers.dart';
import 'package:hisab/features/dashboard/widgets/trend_card.dart';

import '../support/app_harness.dart';
import '../support/one_line_text.dart';

/// Six months from August 2026 to January 2027, so the labels span a year.
List<PeriodTotal> _sixMonths({int expense = 1200000}) => [
      for (var offset = 0; offset < 6; offset++)
        PeriodTotal(range: DateRange(DateTime(2026, 8 + offset, 1), DateTime(2026, 9 + offset, 1)), expense: expense, income: 0),
    ];

/// January 2027, ten days in, ₹1,000 a day against ₹800 a day in December.
TrendData _trend({int expenseCount = 5, bool spent = true, bool previous = true}) => TrendData(
      current: [for (var day = 1; day <= 10; day++) spent ? day * 100000 : 0],
      previous: [for (var day = 1; day <= 31; day++) previous ? day * 80000 : 0],
      daysInMonth: 31,
      daysElapsed: 10,
      months: _sixMonths(),
      expenseCount: expenseCount,
    );

Future<ProviderContainer> _pumpTrend(WidgetTester tester, TrendData trend) async {
  final container = await createContainer(overrides: [trendDataProvider.overrideWithValue(AsyncData(trend))]);
  await pumpScreen(tester, container, const Scaffold(body: SingleChildScrollView(padding: EdgeInsets.all(16), child: TrendCard())));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('stays hidden until the window holds a few expenses', (tester) async {
    await _pumpTrend(tester, _trend(expenseCount: 2));
    expect(find.byKey(kTrendCardKey), findsNothing);
    expect(find.text('Spending trend'), findsNothing);
  });

  testWidgets('the daily chart shows this month against last, with a tooltip for both lines', (tester) async {
    await _pumpTrend(tester, _trend());
    expect(find.byKey(kTrendCardKey), findsOneWidget);
    expect(find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.label == 'Spending trend: ₹10,000 spent so far this month'), findsOneWidget);
    expect(find.text('1'), findsWidgets, reason: 'the first day is labelled on the axis');

    final chart = tester.getRect(find.byType(LineChart));
    // Day 5 sits a quarter of the way along the 31 days, past the 40dp axis.
    final dayFive = Offset(chart.left + 40 + (chart.width - 40) * 4 / 30, chart.center.dy);
    final gesture = await tester.startGesture(dayFive);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull, reason: 'the tooltip for both lines paints');
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a month with nothing spent yet shows a flat empty state', (tester) async {
    await _pumpTrend(tester, _trend(spent: false, previous: false));
    expect(find.text('Add a few entries to see your trend'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('monthly bars label months across the year and a tap selects that month', (tester) async {
    final container = await _pumpTrend(tester, _trend());
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('Aug 26'), findsOneWidget, reason: 'six months over two years carry the year');
    expect(find.text('Jan 27'), findsOneWidget);

    final chart = tester.getRect(find.byType(BarChart));
    final plotWidth = chart.width - 40;
    // The second bar (September), just above the axis line.
    final september = Offset(chart.left + 40 + plotWidth * 1.5 / 6, chart.bottom - 22 - 6);
    final gesture = await tester.startGesture(september);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(container.read(selectedMonthProvider), DateTime(2026, 9, 1));

    await tester.tap(find.text('Daily'));
    await tester.pumpAndSettle();
    expect(find.byType(LineChart), findsOneWidget);
  });

  for (final (locale, title) in const [(Locale('en'), 'Spending trend'), (Locale('hi'), 'खर्च का रुझान')]) {
    testWidgets('the title keeps its room and the switch moves under it at text x2 (${locale.languageCode})', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final container = await createContainer(overrides: [trendDataProvider.overrideWithValue(AsyncData(_trend()))]);
      await pumpScreen(tester, container, const Scaffold(body: SingleChildScrollView(padding: EdgeInsets.all(16), child: TrendCard())), locale: locale);
      await tester.pumpAndSettle();

      final titleRect = tester.getRect(find.text(title));
      expect(titleRect.width, greaterThan(200), reason: 'before, the switch squeezed the title to nothing');
      expect(tester.getRect(find.byType(SegmentedButton<TrendMode>)).top, greaterThanOrEqualTo(titleRect.bottom));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('with room to spare the switch sits beside the title', (tester) async {
    // The test font is far wider than the real one, so give it a wide screen.
    final container = await createContainer(overrides: [trendDataProvider.overrideWithValue(AsyncData(_trend()))]);
    await pumpScreen(tester, container, const Scaffold(body: SingleChildScrollView(padding: EdgeInsets.all(16), child: TrendCard())), size: const Size(600, 780));
    await tester.pumpAndSettle();
    final titleRect = tester.getRect(find.text('Spending trend'));
    final switchRect = tester.getRect(find.byType(SegmentedButton<TrendMode>));
    expect(switchRect.left, greaterThan(titleRect.right));
    expect(switchRect.top, lessThan(titleRect.bottom));
  });

  testWidgets('axis labels stay on one line inside their reserved room at text x2', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpTrend(tester, _trend());

    void expectAxisLabels(Finder chart, List<String> amounts, List<String> bottom) {
      final chartRect = tester.getRect(chart);
      for (final label in amounts) {
        expectOneLine(tester, chart, label);
        final rect = tester.getRect(find.descendant(of: chart, matching: find.text(label)));
        expect(rect.left, greaterThanOrEqualTo(chartRect.left - 0.01), reason: '"$label" starts inside the chart');
        expect(rect.right, lessThanOrEqualTo(chartRect.left + 40.01), reason: '"$label" fits the 40dp amount axis');
      }
      for (final label in bottom) {
        expectOneLine(tester, chart, label);
        final rect = tester.getRect(find.descendant(of: chart, matching: find.text(label)));
        expect(rect.bottom, lessThanOrEqualTo(chartRect.bottom + 0.01), reason: '"$label" is not cut off below the chart');
      }
    }

    // ₹10,000 so far against ₹24,800 last month: the axis tops out at ₹25K.
    expectAxisLabels(find.byType(LineChart), ['₹25K'], ['1']);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    expectAxisLabels(find.byType(BarChart), [], ['Aug 26', 'Jan 27']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the labels on one axis share one size at text x2', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpTrend(tester, _trend());

    void expectOneScale(Finder chart) {
      final heights = leftAxisLabelHeights(tester, chart);
      expect(heights.length, greaterThan(1));
      for (final height in heights) {
        expect(height, moreOrLessEquals(heights.first), reason: 'before, "₹0" was drawn bigger than "₹25K"');
      }
    }

    expectOneScale(find.byType(LineChart));
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    expectOneScale(find.byType(BarChart));
    expect(tester.takeException(), isNull);
  });
}

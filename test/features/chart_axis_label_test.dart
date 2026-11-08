import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/features/dashboard/widgets/dashboard_card.dart';

import '../support/one_line_text.dart';

/// A bar chart whose bottom axis shows [labels] in fixed [width] slots. The
/// first label is drawn in a taller font, standing in for a script such as
/// Devanagari whose lines are taller than Latin ones.
Widget _chart(List<String> labels, {required double width}) => MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 200,
            child: BarChart(
              duration: Duration.zero,
              BarChartData(
                maxY: 10,
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) => ChartAxisLabel(
                        labels[value.round()],
                        axis: meta.axisSide,
                        width: width,
                        style: TextStyle(fontSize: value == 0 ? 16 : 11),
                      ),
                    ),
                  ),
                ),
                barGroups: [
                  for (var index = 0; index < labels.length; index++) BarChartGroupData(x: index, barRods: [BarChartRodData(toY: 5)]),
                ],
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('labels in fixed-width slots share the scale of the tallest one', (tester) async {
    await tester.pumpWidget(_chart(['Me', 'Priya', 'Rahul'], width: 56));
    await tester.pumpAndSettle();

    final scales = [for (final label in ['Me', 'Priya', 'Rahul']) drawnScale(tester, find.text(label))];
    expect(scales.first, lessThan(1), reason: 'the tall label shrinks to fit the axis');
    for (final scale in scales) {
      expect(scale, moreOrLessEquals(scales.first), reason: 'every label on the axis is drawn at one scale');
    }
    expect(tester.getRect(find.text('Me')).height, lessThanOrEqualTo(22.01), reason: 'the tallest label fits the axis');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a label longer than its slot ends in an ellipsis inside the slot', (tester) async {
    await tester.pumpWidget(_chart(['Me', 'Bartholomew'], width: 56));
    await tester.pumpAndSettle();

    final long = find.text('Bartholomew');
    expect(tester.renderObject<RenderParagraph>(long).didExceedMaxLines, isTrue, reason: 'the long name is ellipsized');
    expect(tester.renderObject<RenderParagraph>(long).size.width, 56, reason: 'the name keeps its slot width');
  });
}

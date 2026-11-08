import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Expects [label] inside [scope] to be laid out on a single line: no taller
/// than the same text unwrapped, and not cut short by a line limit.
void expectOneLine(WidgetTester tester, Finder scope, String label) {
  final paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: scope, matching: find.text(label)));
  final oneLineHeight = paragraph.getMaxIntrinsicHeight(double.infinity);
  expect(paragraph.size.height, moreOrLessEquals(oneLineHeight), reason: '"$label" wraps onto more than one line');
  expect(paragraph.didExceedMaxLines, isFalse, reason: '"$label" is cut short');
}

/// Painted heights of the labels in [chart]'s left amount axis, [axisWidth]
/// wide: all equal when the axis draws its labels at one scale.
List<double> leftAxisLabelHeights(WidgetTester tester, Finder chart, {double axisWidth = 40}) {
  final chartLeft = tester.getRect(chart).left;
  final labels = find.descendant(of: chart, matching: find.byType(RichText));
  return [
    for (var index = 0; index < labels.evaluate().length; index++)
      if (tester.getRect(labels.at(index)).right <= chartLeft + axisWidth + 0.01) tester.getRect(labels.at(index)).height,
  ];
}

/// The scale [text] is drawn at: its painted height over its laid-out height.
double drawnScale(WidgetTester tester, Finder text) => tester.getRect(text).height / tester.renderObject<RenderParagraph>(text).size.height;

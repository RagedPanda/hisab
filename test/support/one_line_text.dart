import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Expects [label] inside [scope] to be laid out on a single line: no taller
/// than the same text unwrapped, and not cut short by a line limit.
void expectOneLine(WidgetTester tester, Finder scope, String label) {
  final paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: scope, matching: find.text(label)));
  final oneLineHeight = paragraph.getMaxIntrinsicHeight(double.infinity);
  expect(paragraph.size.height, moreOrLessEquals(oneLineHeight), reason: '"$label" wraps onto more than one line');
  expect(paragraph.didExceedMaxLines, isFalse, reason: '"$label" is cut short');
}

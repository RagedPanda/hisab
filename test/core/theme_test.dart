import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/theme.dart';

/// WCAG contrast ratio between two colours (1 = identical, 21 = black on white).
double _contrast(Color first, Color second) {
  final (lighter, darker) = first.computeLuminance() > second.computeLuminance()
      ? (first.computeLuminance(), second.computeLuminance())
      : (second.computeLuminance(), first.computeLuminance());
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    group('$brightness', () {
      final theme = buildTheme(brightness);
      final card = theme.cardTheme.color!;

      test('cards stand clearly off the page so grouped rows read as one block', () {
        // Before: 1.01 in light (surfaceContainerLow on the grey-teal page) and 1.14 in dark.
        expect(_contrast(card, theme.scaffoldBackgroundColor), greaterThan(brightness == Brightness.light ? 1.1 : 1.25));
      });

      test('the card is the theme helper colour', () => expect(card, cardColor(theme.colorScheme)));

      test('a text field inside a card keeps its own fill', () {
        expect(theme.inputDecorationTheme.fillColor, isNot(card));
      });

      test('a filled field stands off the dialog behind it', () {
        final dialog = theme.dialogTheme.backgroundColor!;
        expect(_contrast(theme.inputDecorationTheme.fillColor!, dialog), greaterThan(1.1));
      });

      test('row dividers are visible on the card', () {
        expect(_contrast(theme.colorScheme.outlineVariant, card), greaterThan(1.3));
      });
    });
  }

  test('light cards are white and dark cards two tonal steps up', () {
    expect(buildTheme(Brightness.light).cardTheme.color, Colors.white);
    final dark = buildTheme(Brightness.dark);
    expect(dark.cardTheme.color, dark.colorScheme.surfaceContainerHigh);
  });
}

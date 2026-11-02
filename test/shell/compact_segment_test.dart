import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/features/shell/widgets/common.dart';
import 'package:hisab/features/shell/widgets/segment_label.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';

import '../support/one_line_text.dart';

/// The labels the app shows with [compactSegment]: the entry kind tabs (entry
/// editor and recurring rule form) and the theme picker in Settings.
List<(String, IconData)> kindSegments(AppLocalizations l10n) =>
    [(l10n.kindExpense, Icons.arrow_upward), (l10n.kindIncome, Icons.arrow_downward), (l10n.kindTransfer, Icons.swap_horiz)];

List<(String, IconData)> themeSegments(AppLocalizations l10n) =>
    [(l10n.themeSystem, Icons.brightness_auto), (l10n.themeLight, Icons.light_mode_outlined), (l10n.themeDark, Icons.dark_mode_outlined)];

/// Mirrors the entry editor and recurring form: default style, 16dp page padding.
Widget kindPicker(BuildContext context, List<(String, IconData)> segments) => ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        SegmentedButton<int>(
          segments: [for (final (index, (label, icon)) in segments.indexed) compactSegment(context, value: index, label: label, icon: icon)],
          selected: const {2},
          onSelectionChanged: (_) {},
        ),
      ],
    );

/// Mirrors the Settings theme picker: expanded inside a padded card.
Widget themePicker(BuildContext context, List<(String, IconData)> segments) => ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              style: const ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)), visualDensity: VisualDensity.standard),
              segments: [for (final (index, (label, icon)) in segments.indexed) compactSegment(context, value: index, label: label, icon: icon)],
              selected: const {0},
              onSelectionChanged: (_) {},
            ),
          ),
        ),
      ],
    );

Future<AppLocalizations> pumpPicker(
  WidgetTester tester, {
  required double width,
  required Locale locale,
  required Widget Function(BuildContext, List<(String, IconData)>) picker,
  required List<(String, IconData)> Function(AppLocalizations) segmentsOf,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late AppLocalizations l10n;
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)), child: child!),
    home: Scaffold(
      body: Builder(builder: (context) {
        l10n = AppLocalizations.of(context);
        return picker(context, segmentsOf(l10n));
      }),
    ),
  ));
  await tester.pumpAndSettle();
  return l10n;
}

void expectLabelsVisible(WidgetTester tester, List<(String, IconData)> segments) {
  expect(tester.takeException(), isNull, reason: 'no overflow');
  final screen = Offset.zero & tester.view.physicalSize;
  for (final (label, _) in segments) {
    final labelFinder = find.text(label);
    expect(labelFinder, findsOneWidget, reason: '"$label" is shown as text, not only as an icon');
    final labelRect = tester.getRect(labelFinder);
    final segmentRect = tester.getRect(find.ancestor(of: labelFinder, matching: find.byType(TextButton)));
    expect(labelRect.width, greaterThan(0));
    expect(segmentRect.intersect(labelRect).size, labelRect.size, reason: '"$label" is not clipped by its segment');
    expect(screen.intersect(labelRect).size, labelRect.size, reason: '"$label" is on screen');
  }
}

void main() {
  final pickers = {'entry kind': (kindPicker, kindSegments), 'theme': (themePicker, themeSegments)};
  for (final locale in const [Locale('en'), Locale('hi')]) {
    for (final MapEntry(key: name, value: (picker, segmentsOf)) in pickers.entries) {
      testWidgets('$name labels stay visible at 360dp, without icons (${locale.languageCode})', (tester) async {
        final l10n = await pumpPicker(tester, width: 360, locale: locale, picker: picker, segmentsOf: segmentsOf);
        final segments = segmentsOf(l10n);
        expectLabelsVisible(tester, segments);
        for (final (_, icon) in segments) {
          expect(find.byIcon(icon), findsNothing, reason: 'the icon gives way to the label on narrow screens');
        }
      });

      testWidgets('$name shows icon and label on wider screens (${locale.languageCode})', (tester) async {
        final l10n = await pumpPicker(tester, width: 412, locale: locale, picker: picker, segmentsOf: segmentsOf);
        final segments = segmentsOf(l10n);
        expectLabelsVisible(tester, segments);
        // The entry kind picker shows a check in place of the selected segment's icon.
        final unselected = name == 'entry kind' ? segments.take(2) : segments;
        for (final (_, icon) in unselected) {
          expect(find.byIcon(icon), findsOneWidget);
        }
      });
    }
  }

  testWidgets('segmentLabel keeps a long label on one line inside a narrow segment, and keys the Text', (tester) async {
    const label = 'A rather long segment label';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 120,
            child: SegmentedButton<int>(
              key: const Key('narrow'),
              segments: [ButtonSegment(value: 0, label: segmentLabel(label, key: const Key('label'))), const ButtonSegment(value: 1, label: Text('B'))],
              selected: const {0},
              onSelectionChanged: (_) {},
            ),
          ),
        ),
      ),
    ));
    expectOneLine(tester, find.byKey(const Key('narrow')), label);
    expect(tester.widget<Text>(find.byKey(const Key('label'))).data, label);
    final segment = tester.getRect(find.ancestor(of: find.text(label), matching: find.byType(TextButton)));
    final shown = tester.getRect(find.text(label));
    expect(segment.intersect(shown).size, shown.size, reason: 'the label scales down to fit its segment');
    expect(tester.takeException(), isNull);
  });

  for (final locale in const [Locale('en'), Locale('hi')]) {
    for (final textScale in const [1.0, 1.3, 2.0]) {
      for (final MapEntry(key: name, value: (picker, segmentsOf)) in pickers.entries) {
        testWidgets('$name labels share one size on one line at 360dp, text x$textScale (${locale.languageCode})', (tester) async {
          final l10n = await pumpPicker(tester, width: 360, locale: locale, picker: picker, segmentsOf: segmentsOf, textScale: textScale);
          final segments = segmentsOf(l10n);
          expectLabelsVisible(tester, segments);
          final heights = [for (final (label, _) in segments) tester.getRect(find.text(label)).height];
          for (final (index, (label, _)) in segments.indexed) {
            expectOneLine(tester, find.byType(SegmentedButton<int>), label);
            expect(heights[index], moreOrLessEquals(heights.first, epsilon: 0.01), reason: '"$label" is drawn at the same scale as its neighbours');
          }
        });
      }
    }
  }

  testWidgets('a label that fits is drawn smaller when a neighbour has to shrink', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              segments: [ButtonSegment(value: 0, label: segmentLabel('A much longer label')), ButtonSegment(value: 1, label: segmentLabel('B'))],
              selected: const {0},
              onSelectionChanged: (_) {},
            ),
          ),
        ),
      ),
    ));
    final long = tester.getRect(find.text('A much longer label'));
    final short = tester.getRect(find.text('B'));
    final natural = tester.renderObject<RenderBox>(find.text('B')).size;
    expect(long.height, lessThan(natural.height), reason: 'the long label shrinks');
    expect(short.height, moreOrLessEquals(long.height), reason: 'the short label follows it');
    expect(tester.takeException(), isNull);
  });

  group('labelFitScale', () {
    test('is 1 when the label fits', () {
      expect(labelFitScale(const Size(50, 20), const BoxConstraints(maxWidth: 100, maxHeight: 40)), 1);
    });
    test('shrinks a label that is too wide', () {
      expect(labelFitScale(const Size(200, 20), const BoxConstraints(maxWidth: 100, maxHeight: 40)), 0.5);
    });
    test('shrinks a label that is too tall', () {
      expect(labelFitScale(const Size(50, 40), const BoxConstraints(maxWidth: 100, maxHeight: 10)), 0.25);
    });
    test('takes the tighter of width and height', () {
      expect(labelFitScale(const Size(200, 40), const BoxConstraints(maxWidth: 100, maxHeight: 10)), 0.25);
    });
    test('ignores unbounded sides and empty labels', () {
      expect(labelFitScale(const Size(200, 40), const BoxConstraints()), 1);
      expect(labelFitScale(Size.zero, const BoxConstraints(maxWidth: 10, maxHeight: 10)), 1);
    });
  });

  group('sharedLabelScale', () {
    test('is the smallest need', () => expect(sharedLabelScale([1, 0.8, 0.6]), 0.6));
    test('never enlarges', () => expect(sharedLabelScale([]), 1));
  });
}

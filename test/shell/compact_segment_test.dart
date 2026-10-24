import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/features/shell/widgets/common.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';

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
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late AppLocalizations l10n;
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
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
}

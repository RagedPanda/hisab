import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/stats/category_shares.dart';
import 'package:hisab/features/dashboard/dashboard_providers.dart';
import 'package:hisab/features/dashboard/widgets/category_donut.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';

/// Global horizontal extent of the glyphs [finder]'s text actually paints,
/// not of its (possibly wider, end-aligned) box.
({double left, double right}) inkExtent(WidgetTester tester, Finder finder) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final boxes = paragraph.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: paragraph.text.toPlainText().length));
  final left = boxes.map((box) => box.left).reduce((a, b) => a < b ? a : b);
  final right = boxes.map((box) => box.right).reduce((a, b) => a > b ? a : b);
  return (left: paragraph.localToGlobal(Offset(left, 0)).dx, right: paragraph.localToGlobal(Offset(right, 0)).dx);
}

void main() {
  for (final locale in const [Locale('en'), Locale('hi')]) {
    testWidgets('legend percent and amount keep a gap at 360dp (${locale.languageCode})', (tester) async {
      tester.view.physicalSize = const Size(360, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: CategoryDonut(
              data: CategoryBreakdown(
                shares: [CategoryShare(categoryId: '', minor: 25400000, fraction: 1)],
                categoriesById: {},
                totalMinor: 25400000,
              ),
              selectedId: null,
              symbol: 'CHF',
              totalCaption: 'Spent',
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'no overflow');

      final percent = find.text('100%');
      final amount = find.textContaining('2,54,000').last;
      expect(percent, findsOneWidget);
      final percentInk = inkExtent(tester, percent);
      final amountInk = inkExtent(tester, amount);
      expect(amountInk.left - percentInk.right, greaterThanOrEqualTo(kLegendValueGap), reason: '"100%" and the amount must not touch');
      expect(tester.renderObject<RenderParagraph>(percent).didExceedMaxLines, isFalse, reason: 'the percent stays on one line');
    });
  }
}

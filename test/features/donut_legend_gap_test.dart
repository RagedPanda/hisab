import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/stats/category_shares.dart';
import 'package:hisab/features/dashboard/dashboard_providers.dart';
import 'package:hisab/features/dashboard/widgets/category_donut.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';
import 'package:hisab/core/money.dart';
import 'package:hisab/domain/money/money_format_resolver.dart';

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
              moneyFormat: MoneyFormat(grouping: DigitGrouping.indian, groupSeparator: ',', decimalSeparator: '.', fractionDigits: 2, symbol: 'CHF', symbolAfter: false),
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

  for (final locale in const [Locale('en'), Locale('hi')]) {
    testWidgets('legend amounts stay whole on their row at text x2 (${locale.languageCode})', (tester) async {
      // A 360dp card: wide enough for the legend to sit beside the donut.
      tester.view.physicalSize = const Size(424, 1600);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: CategoryDonut(
              data: const CategoryBreakdown(
                shares: [CategoryShare(categoryId: 'a', minor: 1800000, fraction: 0.6), CategoryShare(categoryId: 'b', minor: 1200000, fraction: 0.4)],
                categoriesById: {},
                totalMinor: 3000000,
              ),
              selectedId: null,
              moneyFormat: resolveMoneyFormat(currencyCode: 'INR'),
              totalCaption: 'Spent',
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'no overflow');

      for (final label in ['₹18,000', '₹12,000']) {
        final amount = find.text(label);
        expect(amount, findsOneWidget);
        final row = tester.getRect(find.ancestor(of: amount, matching: find.byType(InkWell)).first);
        final ink = inkExtent(tester, amount);
        final paragraph = tester.renderObject<RenderParagraph>(amount);
        expect(paragraph.size.height, moreOrLessEquals(paragraph.getMaxIntrinsicHeight(double.infinity)), reason: '"$label" is on one line');
        expect(tester.getRect(amount).bottom, lessThanOrEqualTo(row.bottom + 0.01), reason: '"$label" is not cut off below its row');
        expect(ink.right, lessThanOrEqualTo(row.right + 0.01), reason: '"$label" is not cut off at the side');
        expect(ink.right - ink.left, moreOrLessEquals(paragraph.getMaxIntrinsicWidth(double.infinity) * tester.getRect(amount).height / paragraph.size.height, epsilon: 0.5), reason: '"$label" is drawn whole');
      }
    });
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/money/money_format_resolver.dart';
import 'package:hisab/domain/stats/category_shares.dart';
import 'package:hisab/features/dashboard/dashboard_providers.dart';
import 'package:hisab/features/dashboard/widgets/category_donut.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';

import '../support/one_line_text.dart';

/// The spending donut on a 360dp card, captioned like the dashboard's.
Future<void> _pumpDonut(WidgetTester tester, Locale locale, double textScale) async {
  tester.view.physicalSize = const Size(424, 1600);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
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
          totalCaption: lookupAppLocalizations(locale).thisMonth,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in const [Locale('en'), Locale('hi')]) {
    testWidgets('at text x2 the centre caption is whole and stays in the hole with the amount (${locale.languageCode})', (tester) async {
      await _pumpDonut(tester, locale, 2);
      expect(tester.takeException(), isNull, reason: 'no overflow');

      final caption = find.text(lookupAppLocalizations(locale).thisMonth);
      final amount = find.text('₹30,000');
      expect(tester.renderObject<RenderParagraph>(caption).didExceedMaxLines, isFalse, reason: 'the caption is not cut short');
      expect(tester.renderObject<RenderParagraph>(amount).didExceedMaxLines, isFalse, reason: 'the amount is not cut short');

      final hole = Rect.fromCircle(center: tester.getCenter(find.byType(PieChart)), radius: 46);
      for (final text in [caption, amount]) {
        final rect = tester.getRect(text);
        expect(rect.left, greaterThanOrEqualTo(hole.left - 0.01));
        expect(rect.right, lessThanOrEqualTo(hole.right + 0.01));
        expect(rect.top, greaterThanOrEqualTo(hole.top - 0.01));
        expect(rect.bottom, lessThanOrEqualTo(hole.bottom + 0.01));
      }
      expect(drawnScale(tester, caption), greaterThanOrEqualTo(0.5), reason: 'the caption is no smaller than at the default size');
    });
  }

  testWidgets('at the default text size the centre caption keeps one line at full size', (tester) async {
    await _pumpDonut(tester, const Locale('en'), 1);

    final caption = find.text('this month');
    final paragraph = tester.renderObject<RenderParagraph>(caption);
    expect(paragraph.size.height, moreOrLessEquals(paragraph.getMaxIntrinsicHeight(double.infinity)), reason: 'one line');
    expect(drawnScale(tester, caption), 1, reason: 'not shrunk');
    expect(tester.getRect(caption).width, lessThanOrEqualTo(kDonutCentreWidth), reason: 'inside the centre');
  });
}

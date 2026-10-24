import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/domain/budget/safe_to_spend.dart';
import 'package:hisab/domain/stats/month_summary.dart';
import 'package:hisab/features/dashboard/dashboard_keys.dart';
import 'package:hisab/features/dashboard/dashboard_providers.dart';
import 'package:hisab/features/dashboard/widgets/hero_card.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _hero = HeroData(
  summary: const MonthSummary(expense: 123456700, income: 500000000, previousExpense: 100000000, daysElapsed: 24, daysInMonth: 31, elapsedFraction: 0.77),
  range: DateRange(DateTime(2026, 10, 1), DateTime(2026, 11, 1)),
  previousRange: DateRange(DateTime(2026, 9, 1), DateTime(2026, 10, 1)),
);

Future<void> _pumpHero(WidgetTester tester, {required SafeToSpend? safe, Locale locale = const Locale('en')}) async {
  SharedPreferences.setMockInitialValues({'onboarded': true, 'currencyCode': 'INR'});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      heroDataProvider.overrideWithValue(AsyncData(_hero)),
      safeToSpendProvider.overrideWithValue(AsyncData(safe)),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: Padding(padding: EdgeInsets.all(16), child: HeroCard())),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  for (final (locale, label, over) in const [(Locale('en'), 'Safe to spend', 'Over budget'), (Locale('hi'), 'सुरक्षित खर्च', 'बजट से ऊपर')]) {
    testWidgets('safe-to-spend line fits at 360dp (${locale.languageCode})', (tester) async {
      await _pumpHero(tester, safe: const SafeToSpend(perDayMinor: 12345600, overByMinor: 0, daysLeft: 8), locale: locale);
      expect(tester.takeException(), isNull, reason: 'no overflow');
      expect(find.textContaining(label), findsOneWidget);
      expect(find.textContaining('1,23,456'), findsOneWidget);
      expect(find.text(over), findsNothing);
    });

    testWidgets('overspent shows zero and the over-budget hint at 360dp (${locale.languageCode})', (tester) async {
      await _pumpHero(tester, safe: const SafeToSpend(perDayMinor: 0, overByMinor: 250000, daysLeft: 8), locale: locale);
      expect(tester.takeException(), isNull, reason: 'no overflow');
      expect(find.textContaining('₹0'), findsOneWidget);
      expect(find.text(over), findsOneWidget);
    });
  }

  testWidgets('no monthly budget: no safe-to-spend line', (tester) async {
    await _pumpHero(tester, safe: null);
    expect(find.byKey(kSafeToSpendKey), findsNothing);
  });
}

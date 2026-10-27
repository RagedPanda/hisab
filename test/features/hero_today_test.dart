import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hisab/core/dates.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/domain/stats/month_summary.dart';
import 'package:hisab/features/dashboard/dashboard_keys.dart';
import 'package:hisab/features/dashboard/dashboard_providers.dart';
import 'package:hisab/features/dashboard/widgets/hero_card.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _summary = MonthSummary(
  expense: 123456700,
  income: 500000000,
  previousExpense: 100000000,
  daysElapsed: 24,
  daysInMonth: 31,
  elapsedFraction: 0.77,
);

HeroData _hero({int? todayMinor}) => HeroData(
      summary: _summary,
      range: DateRange(DateTime(2026, 10, 1), DateTime(2026, 11, 1)),
      previousRange: DateRange(DateTime(2026, 9, 1), DateTime(2026, 10, 1)),
      todayMinor: todayMinor,
    );

Future<GoRouter> _pumpHero(WidgetTester tester, {required HeroData hero, Locale locale = const Locale('en')}) async {
  SharedPreferences.setMockInitialValues({'onboarded': true, 'currencyCode': 'INR'});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(initialLocation: '/home', routes: [
    GoRoute(path: '/home', builder: (_, _) => const Scaffold(body: Padding(padding: EdgeInsets.all(16), child: HeroCard()))),
    GoRoute(path: '/transactions', builder: (_, state) => Scaffold(body: Text('entries ${state.uri}'))),
  ]);
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      heroDataProvider.overrideWithValue(AsyncData(hero)),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  ));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  for (final (locale, label) in const [(Locale('en'), 'Today'), (Locale('hi'), 'आज')]) {
    testWidgets('Today figure fits the hero card at 360dp (${locale.languageCode})', (tester) async {
      await _pumpHero(tester, hero: _hero(todayMinor: 4567800), locale: locale);
      expect(tester.takeException(), isNull, reason: 'no overflow');
      expect(find.byKey(kHeroTodayKey), findsOneWidget);
      expect(find.textContaining(label), findsWidgets);
      expect(find.textContaining('45,678'), findsOneWidget);
    });
  }

  testWidgets('tapping Today opens Entries filtered to today', (tester) async {
    await _pumpHero(tester, hero: _hero(todayMinor: 0));
    await tester.tap(find.byKey(kHeroTodayKey));
    await tester.pumpAndSettle();
    expect(find.text('entries /transactions?day=${isoDay(DateTime.now())}'), findsOneWidget);
  });

  testWidgets('a month other than this one shows no Today figure', (tester) async {
    await _pumpHero(tester, hero: _hero());
    expect(find.byKey(kHeroTodayKey), findsNothing);
  });
}

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/home_currency.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/core/settings.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ProviderContainer, SharedPreferences)> pumpApp(WidgetTester tester, Map<String, Object> prefsValues, {Size size = const Size(430, 932)}) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    databaseProvider.overrideWithValue(db),
  ]);
  addTearDown(container.dispose);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  appRouter.go('/home');
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
  await settle(tester);
  return (container, prefs);
}

Future<void> settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('first launch', () {
    testWidgets('fresh install asks once with INR preselected, even with a UK locale', (tester) async {
      tester.platformDispatcher.localeTestValue = const Locale('en', 'GB');
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      final (container, prefs) = await pumpApp(tester, {});
      expect(find.text('Choose your currency'), findsOneWidget);
      expect(find.text('Continue with \u20b9 INR'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('currency-continue')));
      await settle(tester);
      expect(find.text('Choose your currency'), findsNothing);
      expect(find.text('Hisab'), findsOneWidget);
      expect(prefs.getString(kCurrencyCodeKey), 'INR');
      expect(container.read(homeCurrencyCodeProvider), 'INR');
      expect(container.read(settingsProvider).currencySymbol, '\u20b9');
    });

    testWidgets('search by country, tap to select, then confirm', (tester) async {
      final (container, _) = await pumpApp(tester, {});
      await tester.enterText(find.byKey(const ValueKey('currency-search')), 'switzerland');
      await tester.pump();
      expect(find.byKey(const ValueKey('currency-CHF')), findsOneWidget);
      expect(find.byKey(const ValueKey('currency-INR')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('currency-CHF')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('currency-continue')));
      await settle(tester);
      expect(container.read(settingsProvider).currencyCode, 'CHF');
      expect(container.read(settingsProvider).currencyConfirmed, isTrue);
    });

    testWidgets('no match shows a message', (tester) async {
      await pumpApp(tester, {});
      await tester.enterText(find.byKey(const ValueKey('currency-search')), 'zzqq');
      await tester.pump();
      expect(find.text('No currency matches "zzqq"'), findsOneWidget);
    });

    testWidgets('fits a 360dp screen', (tester) async {
      await pumpApp(tester, {}, size: const Size(360, 640));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('currency-continue')), findsOneWidget);
    });

    testWidgets('upgrade with a migrated currency is not asked', (tester) async {
      await pumpApp(tester, {'currencyCode': 'EUR', 'currencySymbol': '€'});
      expect(find.text('Choose your currency'), findsNothing);
      expect(find.text('Hisab'), findsOneWidget);
    });

    testWidgets('Hindi wording', (tester) async {
      await pumpApp(tester, {'localeCode': 'hi'});
      expect(find.text('अपनी मुद्रा चुनें'), findsOneWidget);
    });
  });

  testWidgets('Settings > Currency picker writes the setting', (tester) async {
    final (container, prefs) = await pumpApp(tester, {'currencyCode': 'INR'});
    appRouter.go('/settings');
    await settle(tester);
    expect(find.text('₹ INR'), findsOneWidget);
    await tester.tap(find.text('Currency'));
    await settle(tester);
    await tester.enterText(find.byKey(const ValueKey('currency-search')), 'yen');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('currency-JPY')));
    await settle(tester);
    expect(container.read(settingsProvider).currencyCode, 'JPY');
    expect(prefs.getString(kCurrencyCodeKey), 'JPY');
    expect(find.text('¥ JPY'), findsOneWidget);
  });
}

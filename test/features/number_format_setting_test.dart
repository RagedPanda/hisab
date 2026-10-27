import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/core/settings.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/domain/money/money_format.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('Number format row fits at 360dp in Hindi and the override applies', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true, 'currencyCode': 'EUR', 'localeCode': 'hi'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory())),
      deviceLocaleProvider.overrideWithValue(const Locale('de', 'DE')),
    ]);
    addTearDown(container.dispose);
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    appRouter.go('/home');
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
    await _settle(tester);
    // Home overflows at 360dp with the square test font (pre-existing, not
    // this screen); drop that so the checks below cover Settings only.
    tester.takeException();
    await tester.tap(find.text('सेटिंग्स'));
    await _settle(tester);

    final row = find.widgetWithText(ListTile, 'संख्या फ़ॉर्मैट');
    await tester.scrollUntilVisible(row, 200, scrollable: find.byType(Scrollable).first);
    await _settle(tester, 4);
    expect(find.descendant(of: row, matching: find.text('123.456,78')), findsOneWidget, reason: 'automatic follows EUR on a German device');
    expect(tester.takeException(), isNull, reason: 'no overflow on Settings at 360dp in Hindi');

    await tester.tap(row);
    await _settle(tester, 4);
    expect(find.text('अपने-आप'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'no overflow in the picker at 360dp in Hindi');
    await tester.tap(find.text('1,23,456.78'));
    await _settle(tester, 4);

    expect(container.read(settingsProvider).numberFormat, NumberFormatChoice.indian);
    expect(prefs.getString(kNumberFormatKey), 'indian');
    expect(find.descendant(of: row, matching: find.text('1,23,456.78')), findsOneWidget);
  });
}

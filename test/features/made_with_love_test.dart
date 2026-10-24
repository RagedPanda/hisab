import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/settings/made_with_love.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:hisab/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _phoneSize = Size(360, 760);

Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder get _redHeart => find.byWidgetPredicate((widget) => widget is Icon && widget.icon == Icons.favorite && widget.color == Colors.red);

void main() {
  testWidgets('Settings ends with "Made with" and a red heart at 360dp', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true, 'currencyCode': 'INR'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory())),
    ]);
    addTearDown(container.dispose);
    await tester.binding.setSurfaceSize(_phoneSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    appRouter.go('/home');
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
    await _settle(tester);
    // Home overflows at 360dp with the square test font (pre-existing, not
    // this screen); drop that so the check below covers Settings only.
    tester.takeException();
    await tester.tap(find.text('Settings'));
    await _settle(tester);

    final madeWithLove = find.byType(MadeWithLove);
    await tester.scrollUntilVisible(madeWithLove, 200, scrollable: find.byType(Scrollable).first);
    await _settle(tester, 4);

    expect(find.textContaining('Made with'), findsOneWidget);
    expect(find.descendant(of: madeWithLove, matching: _redHeart), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'no overflow on Settings at 360dp');

    final heartCentre = tester.getCenter(madeWithLove);
    expect(heartCentre.dx, closeTo(_phoneSize.width / 2, 1), reason: 'centred under the About card');
    final aboutCard = find.ancestor(of: find.text('Hisab').last, matching: find.byType(Card));
    expect(tester.getTopLeft(madeWithLove).dy, greaterThanOrEqualTo(tester.getBottomLeft(aboutCard).dy), reason: 'below the About card');

    final semantics = tester.ensureSemantics();
    expect(tester.getSemantics(find.byKey(const ValueKey('about-made-with-love'))).label, 'Made with love');
    semantics.dispose();
  });

  testWidgets('Hindi puts the heart first and reads naturally', (tester) async {
    await tester.binding.setSurfaceSize(_phoneSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('hi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: MadeWithLove())),
    ));
    await tester.pump();

    expect(find.textContaining('से बनाया गया'), findsOneWidget);
    expect(find.textContaining('Made with'), findsNothing);
    expect(_redHeart, findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(tester.getSemantics(find.byKey(const ValueKey('about-made-with-love'))).label, 'प्यार से बनाया गया');
    semantics.dispose();
  });
}

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/app.dart';
import 'package:hisab/core/providers.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/fake_notification_gateway.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  testWidgets('Settings keeps everyday rows under Money and planning rows under Advanced', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarded': true, 'currencyCode': 'INR'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(AppDatabase(NativeDatabase.memory())),
      notificationGatewayProvider.overrideWithValue(FakeNotificationGateway()),
    ]);
    addTearDown(container.dispose);
    await tester.binding.setSurfaceSize(const Size(360, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    appRouter.go('/settings');
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const HisabApp()));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final advanced = find.byKey(const Key('settingsAdvanced'));
    expect(find.text('Advanced'), findsOneWidget);
    for (final row in ['Budgets', 'Projects', 'Recurring', 'Subscriptions', 'Month starts on', 'Number format']) {
      expect(find.descendant(of: advanced, matching: find.text(row)), findsOneWidget, reason: row);
    }
    for (final row in ['Currency', 'Accounts', 'Default account', 'Categories']) {
      expect(find.descendant(of: advanced, matching: find.text(row)), findsNothing, reason: row);
      expect(find.text(row), findsWidgets, reason: row);
    }
    expect(tester.getTopLeft(find.text('Categories')).dy, lessThan(tester.getTopLeft(find.text('Advanced')).dy), reason: 'everyday rows come first');
  });
}

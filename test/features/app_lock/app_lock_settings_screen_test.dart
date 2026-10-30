import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/app_lock/device_authenticator.dart';
import 'package:hisab/domain/app_lock/app_lock_policy.dart';
import 'package:hisab/features/app_lock/app_lock_providers.dart';
import 'package:hisab/features/app_lock/app_lock_settings_screen.dart';
import 'package:hisab/features/shell/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/app_harness.dart';
import '../../support/fake_app_lock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final lockSwitch = find.byKey(const Key('appLockSwitch'));

  Future<void> openSettings(WidgetTester tester, FakeAuthenticator auth) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpApp(tester, overrides: [
      appAuthenticatorProvider.overrideWithValue(auth),
      secureWindowChannelProvider.overrideWithValue(FakeSecureWindow()),
    ]);
    appRouter.go('/settings');
    await settle(tester);
    appRouter.push(kAppLockLocation);
    await settle(tester);
  }

  bool switchOn(WidgetTester tester) => tester.widget<SwitchListTile>(lockSwitch).value;

  testWidgets('without a screen lock on the phone it explains and stays off', (tester) async {
    final auth = FakeAuthenticator(available: false);
    await openSettings(tester, auth);
    await tester.tap(lockSwitch);
    await settle(tester, 4);
    expect(switchOn(tester), isFalse);
    expect(auth.prompts, 0);
    expect(find.textContaining('no screen lock'), findsOneWidget);
  });

  testWidgets('turns on only after the user proves who they are', (tester) async {
    final auth = FakeAuthenticator(results: [AppAuthResult.notUnlocked, AppAuthResult.unlocked]);
    await openSettings(tester, auth);
    await tester.tap(lockSwitch);
    await settle(tester, 4);
    expect(switchOn(tester), isFalse, reason: 'the prompt was cancelled');

    await tester.tap(lockSwitch);
    await settle(tester, 4);
    expect(switchOn(tester), isTrue);
    expect(find.byKey(const Key('appLockScreen')), findsNothing, reason: 'turning it on does not lock the open app');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kAppLockEnabledKey), isTrue);

    await tester.tap(find.text('5 min'));
    await settle(tester, 4);
    expect(prefs.getString(kAppLockTimeoutKey), AppLockTimeout.fiveMinutes.name);
    expect(find.byKey(const Key('appLockHideInRecents')), findsOneWidget);

    await tester.tap(lockSwitch);
    await settle(tester, 4);
    expect(prefs.getBool(kAppLockEnabledKey), isFalse, reason: 'turning it off needs no prompt');
    expect(auth.prompts, 2);
  });

  testWidgets('the Settings row sums it up and opens the screen', (tester) async {
    final container = await createContainer(preferences: {kAppLockEnabledKey: true, kAppLockTimeoutKey: AppLockTimeout.fiveMinutes.name});
    await pumpScreen(tester, container, const Scaffold(body: AppLockSettingsTile()));
    expect(find.text('On, locks after 5 minutes'), findsOneWidget);
    await tester.tap(find.byKey(const Key('settingsAppLock')));
    await pumpWithDatabase(tester, 3);
    expect(find.text(openedLocation(kAppLockLocation)), findsOneWidget);
  });
}

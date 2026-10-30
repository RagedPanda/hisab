import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/app_lock/device_authenticator.dart';
import 'package:hisab/domain/app_lock/app_lock_policy.dart';
import 'package:hisab/features/app_lock/app_lock_providers.dart';
import 'package:hisab/features/dashboard/dashboard_screen.dart';
import 'package:hisab/features/shell/router.dart';

import '../../support/app_harness.dart';
import '../../support/fake_app_lock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final lockScreen = find.byKey(const Key('appLockScreen'));
  final unlockButton = find.byKey(const Key('appLockUnlock'));
  final home = find.byType(DashboardScreen);
  var now = DateTime(2026, 10, 30, 10);

  Map<String, Object> lockOn({AppLockTimeout timeout = AppLockTimeout.oneMinute, bool hideInRecents = false}) =>
      {kAppLockEnabledKey: true, kAppLockTimeoutKey: timeout.name, kAppLockHideInRecentsKey: hideInRecents};

  Future<ProviderContainer> start(WidgetTester tester, FakeAuthenticator auth, {Map<String, Object> preferences = const {}, FakeSecureWindow? secure}) {
    now = DateTime(2026, 10, 30, 10);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    return pumpApp(tester, preferences: preferences, overrides: [
      appAuthenticatorProvider.overrideWithValue(auth),
      appLockClockProvider.overrideWithValue(() => now),
      secureWindowChannelProvider.overrideWithValue(secure ?? FakeSecureWindow()),
    ]);
  }

  Future<void> leave(WidgetTester tester) async {
    for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
  }

  Future<void> comeBack(WidgetTester tester, Duration away) async {
    now = now.add(away);
    for (final state in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await settle(tester, 4);
  }

  testWidgets('with the lock off the app opens straight to Home', (tester) async {
    final auth = FakeAuthenticator();
    await start(tester, auth);
    expect(home, findsOneWidget);
    expect(lockScreen, findsNothing);
    expect(auth.prompts, 0);
  });

  testWidgets('a cold start asks at once, and stays locked until the user unlocks', (tester) async {
    final auth = FakeAuthenticator(results: [AppAuthResult.notUnlocked, AppAuthResult.unlocked]);
    await start(tester, auth, preferences: lockOn());
    expect(auth.prompts, 1);
    expect(lockScreen, findsOneWidget);
    expect(home, findsNothing, reason: 'nothing of the app shows behind the lock');

    await tester.tap(unlockButton);
    await settle(tester, 4);
    expect(lockScreen, findsNothing);
    expect(home, findsOneWidget);
  });

  testWidgets('locks again only after the chosen timeout in the background', (tester) async {
    final auth = FakeAuthenticator(results: [AppAuthResult.unlocked]);
    await start(tester, auth, preferences: lockOn());
    expect(home, findsOneWidget);

    await leave(tester);
    expect(lockScreen, findsOneWidget, reason: 'the recent-apps card shows the cover');
    expect(unlockButton, findsNothing);
    await comeBack(tester, const Duration(seconds: 40));
    expect(lockScreen, findsNothing);
    expect(home, findsOneWidget);
    expect(auth.prompts, 1);

    await leave(tester);
    await comeBack(tester, const Duration(minutes: 2));
    expect(auth.prompts, 2, reason: 'the prompt shows on return');
    expect(lockScreen, findsOneWidget);
    expect(unlockButton, findsOneWidget);
    expect(home, findsNothing);
  });

  testWidgets('"Immediately" locks on any trip away', (tester) async {
    final auth = FakeAuthenticator(results: [AppAuthResult.unlocked]);
    await start(tester, auth, preferences: lockOn(timeout: AppLockTimeout.immediately));
    await leave(tester);
    await comeBack(tester, const Duration(seconds: 1));
    expect(unlockButton, findsOneWidget);
  });

  testWidgets('the device PIN screen opened by the prompt does not lock again', (tester) async {
    final auth = FakeAuthenticator()..hold = true;
    await start(tester, auth, preferences: lockOn(timeout: AppLockTimeout.immediately));
    expect(auth.prompts, 1);
    await leave(tester);
    await comeBack(tester, const Duration(seconds: 20));
    expect(auth.prompts, 1, reason: 'no second prompt while the first is up');
    auth.pending!.complete(AppAuthResult.unlocked);
    await settle(tester, 4);
    expect(home, findsOneWidget);
  });

  testWidgets('a link opened while locked lands on its screen after unlocking', (tester) async {
    final auth = FakeAuthenticator(results: [AppAuthResult.notUnlocked, AppAuthResult.unlocked]);
    await start(tester, auth, preferences: lockOn());
    appRouter.go('/entry?kind=expense');
    await settle(tester);
    expect(find.text('New entry'), findsNothing);
    expect(lockScreen, findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse, reason: 'the amount must not raise the keypad over the lock');

    await tester.tap(unlockButton);
    await settle(tester, 4);
    expect(find.text('New entry'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue, reason: 'the amount takes focus once unlocked');
  });

  testWidgets('typed input survives a lock', (tester) async {
    final auth = FakeAuthenticator(results: [AppAuthResult.unlocked, AppAuthResult.unlocked]);
    await start(tester, auth, preferences: lockOn());
    appRouter.go('/entry?kind=expense');
    await settle(tester);
    await enter(tester, find.byType(TextField).first, '250');
    await leave(tester);
    await comeBack(tester, const Duration(minutes: 3));
    expect(lockScreen, findsNothing, reason: 'the fake unlocks at once');
    expect(find.text('250'), findsOneWidget);
  });

  testWidgets('a removed screen lock turns the app lock off instead of locking the user out', (tester) async {
    final auth = FakeAuthenticator(results: [AppAuthResult.noScreenLock]);
    final container = await start(tester, auth, preferences: lockOn());
    expect(home, findsOneWidget);
    expect(container.read(appLockSettingsProvider).enabled, isFalse);
  });

  testWidgets('"Hide in recent apps" secures the window only while the lock is on', (tester) async {
    final secure = FakeSecureWindow();
    final container = await start(tester, FakeAuthenticator(results: [AppAuthResult.unlocked]), preferences: lockOn(hideInRecents: true), secure: secure);
    expect(secure.calls, [true]);
    await container.read(appLockSettingsProvider.notifier).setEnabled(false);
    await tester.pump();
    expect(secure.calls, [true, false]);
  });
}

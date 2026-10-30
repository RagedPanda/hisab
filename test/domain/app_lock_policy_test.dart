import 'dart:ui' show AppLifecycleState;

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/app_lock/device_authenticator.dart';
import 'package:hisab/domain/app_lock/app_lock_policy.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  final leftAt = DateTime(2026, 10, 30, 10);

  group('isAwayTooLong', () {
    test('locks only once the timeout has passed', () {
      expect(isAwayTooLong(leftAt: leftAt, now: leftAt.add(const Duration(seconds: 59)), timeout: AppLockTimeout.oneMinute), isFalse);
      expect(isAwayTooLong(leftAt: leftAt, now: leftAt.add(const Duration(minutes: 1)), timeout: AppLockTimeout.oneMinute), isTrue);
      expect(isAwayTooLong(leftAt: leftAt, now: leftAt.add(const Duration(minutes: 4)), timeout: AppLockTimeout.fiveMinutes), isFalse);
      expect(isAwayTooLong(leftAt: leftAt, now: leftAt.add(const Duration(minutes: 5)), timeout: AppLockTimeout.fiveMinutes), isTrue);
    });

    test('immediately locks on any trip away', () {
      expect(isAwayTooLong(leftAt: leftAt, now: leftAt, timeout: AppLockTimeout.immediately), isTrue);
    });

    test('a clock that went backwards counts as too long', () {
      expect(isAwayTooLong(leftAt: leftAt, now: leftAt.subtract(const Duration(hours: 1)), timeout: AppLockTimeout.fiveMinutes), isTrue);
    });
  });

  test('timeouts round-trip by name and default to one minute', () {
    for (final timeout in AppLockTimeout.values) {
      expect(AppLockTimeout.fromName(timeout.name), timeout);
    }
    expect(AppLockTimeout.fromName(null), AppLockTimeout.oneMinute);
    expect(AppLockTimeout.fromName('tenMinutes'), AppLockTimeout.oneMinute);
  });

  test('the content is covered once the app is hidden, and on iOS already when inactive', () {
    for (final state in [AppLifecycleState.hidden, AppLifecycleState.paused]) {
      expect(coversContent(state, isIOS: false), isTrue);
      expect(coversContent(state, isIOS: true), isTrue);
    }
    expect(coversContent(AppLifecycleState.inactive, isIOS: false), isFalse, reason: 'a pulled-down notification shade');
    expect(coversContent(AppLifecycleState.inactive, isIOS: true), isTrue);
    expect(coversContent(AppLifecycleState.resumed, isIOS: true), isFalse);
  });

  group('AppLockSession', () {
    test('a cold start is locked only with the lock on', () {
      expect(AppLockSession.coldStart(enabled: true).locked, isTrue);
      expect(AppLockSession.coldStart(enabled: false).locked, isFalse);
    });

    test('coming back within the timeout stays unlocked', () {
      final session = const AppLockSession(locked: false).left(leftAt).returned(leftAt.add(const Duration(seconds: 30)), enabled: true, timeout: AppLockTimeout.oneMinute);
      expect(session.locked, isFalse);
      expect(session.leftAt, isNull);
    });

    test('coming back after the timeout locks', () {
      final session = const AppLockSession(locked: false).left(leftAt).returned(leftAt.add(const Duration(minutes: 2)), enabled: true, timeout: AppLockTimeout.oneMinute);
      expect(session.locked, isTrue);
    });

    test('with the lock off nothing locks', () {
      final session = const AppLockSession(locked: false).left(leftAt).returned(leftAt.add(const Duration(hours: 2)), enabled: false, timeout: AppLockTimeout.immediately);
      expect(session.locked, isFalse);
    });

    test('the first moment of leaving counts', () {
      final session = const AppLockSession(locked: false).left(leftAt).left(leftAt.add(const Duration(minutes: 3)));
      expect(session.leftAt, leftAt);
    });

    test('the device PIN screen opened by the prompt is not leaving', () {
      final session = const AppLockSession(locked: true).startAuthenticating().left(leftAt).returned(leftAt.add(const Duration(minutes: 10)), enabled: true, timeout: AppLockTimeout.immediately);
      expect(session.leftAt, isNull);
      expect(session.finishAuthenticating(unlocked: true).locked, isFalse);
    });

    test('a failed prompt keeps it locked; turning the lock off unlocks', () {
      final locked = const AppLockSession(locked: true).startAuthenticating().finishAuthenticating(unlocked: false);
      expect(locked.locked, isTrue);
      expect(locked.authenticating, isFalse);
      expect(locked.disabled().locked, isFalse);
    });
  });

  test('a device without a screen lock and a lockout read as such; anything else is a retry', () {
    expect(authResultForError(LocalAuthExceptionCode.noCredentialsSet), AppAuthResult.noScreenLock);
    expect(authResultForError(LocalAuthExceptionCode.temporaryLockout), AppAuthResult.lockedOut);
    expect(authResultForError(LocalAuthExceptionCode.biometricLockout), AppAuthResult.lockedOut);
    expect(authResultForError(LocalAuthExceptionCode.userCanceled), AppAuthResult.notUnlocked);
    expect(authResultForError(LocalAuthExceptionCode.systemCanceled), AppAuthResult.notUnlocked);
  });
}

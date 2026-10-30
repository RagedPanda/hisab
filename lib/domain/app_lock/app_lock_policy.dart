/// When the app lock asks for the fingerprint, face or device PIN again, and
/// when the app's content is hidden. Pure: no I/O, no clock; the caller
/// passes the time in.
library;

import 'dart:ui' show AppLifecycleState;

/// How long Hisab may stay in the background before it locks again.
enum AppLockTimeout {
  immediately(Duration.zero),
  oneMinute(Duration(minutes: 1)),
  fiveMinutes(Duration(minutes: 5));

  const AppLockTimeout(this.duration);

  final Duration duration;

  /// The timeout stored as [name], or the default for anything unknown.
  static AppLockTimeout fromName(String? name) =>
      AppLockTimeout.values.firstWhere((timeout) => timeout.name == name, orElse: () => kDefaultAppLockTimeout);
}

const AppLockTimeout kDefaultAppLockTimeout = AppLockTimeout.oneMinute;

/// Whether coming back at [now] after leaving at [leftAt] needs unlocking.
/// A clock that went backwards counts as too long away.
bool isAwayTooLong({required DateTime leftAt, required DateTime now, required AppLockTimeout timeout}) {
  final away = now.difference(leftAt);
  return away.isNegative || away >= timeout.duration;
}

/// Whether the app's content is hidden behind a cover in [state], so the
/// recent-apps switcher never shows it. iOS takes its switcher snapshot
/// once the app is inactive; Android reports inactive for every pulled-down
/// notification shade, so there the cover waits for the app to be hidden.
bool coversContent(AppLifecycleState state, {required bool isIOS}) => switch (state) {
      AppLifecycleState.resumed || AppLifecycleState.detached => false,
      AppLifecycleState.inactive => isIOS,
      AppLifecycleState.hidden || AppLifecycleState.paused => true,
    };

/// Whether moving from [previous] to [state] means the user left the app,
/// which starts the timeout. Coming back passes through hidden after
/// paused; that is the way in, not out.
bool isLeaving(AppLifecycleState state, {AppLifecycleState? previous}) =>
    (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) &&
    !(state == AppLifecycleState.hidden && previous == AppLifecycleState.paused);

/// The lock's state while the app runs. Each change returns a new session.
class AppLockSession {
  const AppLockSession({required this.locked, this.leftAt, this.authenticating = false, this.inSystemScreen = false});

  /// A cold start is locked whenever the lock is on.
  factory AppLockSession.coldStart({required bool enabled}) => AppLockSession(locked: enabled);

  /// True while the lock screen covers the app.
  final bool locked;

  /// When the user last left the app; null while it is in front.
  final DateTime? leftAt;

  /// True while the system's fingerprint, face or PIN prompt is up. That
  /// prompt (the device PIN one in particular) sends the app to the
  /// background, which must not count as leaving it.
  final bool authenticating;

  /// True while a system screen Hisab opened itself (a folder or file
  /// picker, the Google account chooser) is up. Like [authenticating], the
  /// trip there is not leaving the app, so the user is not locked out on
  /// the way back.
  final bool inSystemScreen;

  AppLockSession _copy({bool? locked, DateTime? leftAt, bool clearLeftAt = false, bool? authenticating, bool? inSystemScreen}) => AppLockSession(
        locked: locked ?? this.locked,
        leftAt: clearLeftAt ? null : leftAt ?? this.leftAt,
        authenticating: authenticating ?? this.authenticating,
        inSystemScreen: inSystemScreen ?? this.inSystemScreen,
      );

  /// The user left the app at [now]. The first moment counts: hidden and
  /// paused both arrive on the way out.
  AppLockSession left(DateTime now) => authenticating || inSystemScreen || leftAt != null ? this : _copy(leftAt: now);

  /// The user came back at [now]: locked when away for at least [timeout]
  /// with the lock on.
  AppLockSession returned(DateTime now, {required bool enabled, required AppLockTimeout timeout}) {
    final away = leftAt;
    final tooLong = enabled && away != null && isAwayTooLong(leftAt: away, now: now, timeout: timeout);
    return _copy(locked: locked || tooLong, clearLeftAt: true);
  }

  AppLockSession startAuthenticating() => _copy(authenticating: true);

  /// The prompt closed; [unlocked] when the user proved who they are.
  AppLockSession finishAuthenticating({required bool unlocked}) => _copy(locked: locked && !unlocked, authenticating: false);

  AppLockSession openedSystemScreen() => _copy(inSystemScreen: true);

  AppLockSession closedSystemScreen() => _copy(inSystemScreen: false);

  /// The lock was turned off: nothing stays locked.
  AppLockSession disabled() => _copy(locked: false);
}

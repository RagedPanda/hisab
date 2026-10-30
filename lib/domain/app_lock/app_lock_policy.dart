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

/// Whether [state] means the user left the app, which starts the timeout.
bool isLeaving(AppLifecycleState state) => state == AppLifecycleState.hidden || state == AppLifecycleState.paused;

/// The lock's state while the app runs. Each change returns a new session.
class AppLockSession {
  const AppLockSession({required this.locked, this.leftAt, this.authenticating = false});

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

  /// The user left the app at [now]. The first moment counts: hidden and
  /// paused both arrive on the way out.
  AppLockSession left(DateTime now) =>
      authenticating || leftAt != null ? this : AppLockSession(locked: locked, leftAt: now, authenticating: authenticating);

  /// The user came back at [now]: locked when away for at least [timeout]
  /// with the lock on.
  AppLockSession returned(DateTime now, {required bool enabled, required AppLockTimeout timeout}) {
    final away = leftAt;
    final tooLong = enabled && away != null && isAwayTooLong(leftAt: away, now: now, timeout: timeout);
    return AppLockSession(locked: locked || tooLong, authenticating: authenticating);
  }

  AppLockSession startAuthenticating() => AppLockSession(locked: locked, leftAt: leftAt, authenticating: true);

  /// The prompt closed; [unlocked] when the user proved who they are.
  AppLockSession finishAuthenticating({required bool unlocked}) => AppLockSession(locked: locked && !unlocked, leftAt: leftAt);

  /// The lock was turned off: nothing stays locked.
  AppLockSession disabled() => AppLockSession(locked: false, leftAt: leftAt, authenticating: authenticating);
}

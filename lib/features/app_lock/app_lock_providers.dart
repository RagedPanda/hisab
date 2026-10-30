import 'dart:ui' show AppLifecycleState;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/app_lock/device_authenticator.dart';
import '../../data/app_lock/secure_window_channel.dart';
import '../../domain/app_lock/app_lock_policy.dart';

const String kAppLockEnabledKey = 'appLock.enabled';
const String kAppLockTimeoutKey = 'appLock.timeout';
const String kAppLockHideInRecentsKey = 'appLock.hideInRecents';

/// Settings > App lock, kept on this device beside [AppSettings]. Not part
/// of backups: a restored phone asks to turn it on again.
class AppLockSettings {
  const AppLockSettings({this.enabled = false, this.timeout = kDefaultAppLockTimeout, this.hideInRecents = false});

  final bool enabled;
  final AppLockTimeout timeout;

  /// FLAG_SECURE on Android while the lock is on: a blank recent-apps card,
  /// and no screenshots.
  final bool hideInRecents;

  /// Whether Hisab's window should carry FLAG_SECURE.
  bool get secureWindow => enabled && hideInRecents;

  AppLockSettings copyWith({bool? enabled, AppLockTimeout? timeout, bool? hideInRecents}) => AppLockSettings(
        enabled: enabled ?? this.enabled,
        timeout: timeout ?? this.timeout,
        hideInRecents: hideInRecents ?? this.hideInRecents,
      );
}

class AppLockSettingsNotifier extends Notifier<AppLockSettings> {
  @override
  AppLockSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppLockSettings(
      enabled: prefs.getBool(kAppLockEnabledKey) ?? false,
      timeout: AppLockTimeout.fromName(prefs.getString(kAppLockTimeoutKey)),
      hideInRecents: prefs.getBool(kAppLockHideInRecentsKey) ?? false,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    await ref.read(sharedPreferencesProvider).setBool(kAppLockEnabledKey, enabled);
  }

  Future<void> setTimeout(AppLockTimeout timeout) async {
    state = state.copyWith(timeout: timeout);
    await ref.read(sharedPreferencesProvider).setString(kAppLockTimeoutKey, timeout.name);
  }

  Future<void> setHideInRecents(bool hide) async {
    state = state.copyWith(hideInRecents: hide);
    await ref.read(sharedPreferencesProvider).setBool(kAppLockHideInRecentsKey, hide);
  }
}

final appLockSettingsProvider = NotifierProvider<AppLockSettingsNotifier, AppLockSettings>(AppLockSettingsNotifier.new);

final appAuthenticatorProvider = Provider<AppAuthenticator>((ref) => DeviceAuthenticator());

final secureWindowChannelProvider = Provider<SecureWindowChannel>((ref) => const SecureWindowChannel());

/// The lock's clock; tests move it to cross the timeout.
final appLockClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Whether the lock screen is up, and when the user left the app.
class AppLockController extends Notifier<AppLockSession> {
  @override
  AppLockSession build() {
    // Turning the lock off unlocks; turning it on keeps the app open (the
    // user has just proved who they are).
    ref.listen(appLockSettingsProvider.select((settings) => settings.enabled), (_, enabled) {
      if (!enabled) state = state.disabled();
    });
    return AppLockSession.coldStart(enabled: ref.read(appLockSettingsProvider).enabled);
  }

  /// Follows the app in and out of the foreground. True when the user came
  /// back to a locked app, so the caller shows the prompt.
  bool onLifecycle(AppLifecycleState lifecycle) {
    final now = ref.read(appLockClockProvider)();
    if (isLeaving(lifecycle)) {
      state = state.left(now);
      return false;
    }
    if (lifecycle != AppLifecycleState.resumed) return false;
    final cameBack = state.leftAt != null;
    final settings = ref.read(appLockSettingsProvider);
    state = state.returned(now, enabled: settings.enabled, timeout: settings.timeout);
    return cameBack && state.locked;
  }

  /// Shows the system prompt; unlocks on success. A device whose screen
  /// lock was removed cannot unlock, so the app lock turns itself off.
  Future<AppAuthResult> unlock(String reason) async {
    final result = await authenticate(reason);
    if (result == AppAuthResult.noScreenLock) await ref.read(appLockSettingsProvider.notifier).setEnabled(false);
    return result;
  }

  /// Runs the system prompt without the trip to the device PIN screen
  /// counting as leaving the app. Unlocks on success.
  Future<AppAuthResult> authenticate(String reason) async {
    if (state.authenticating) return AppAuthResult.notUnlocked;
    state = state.startAuthenticating();
    var result = AppAuthResult.notUnlocked;
    try {
      result = await ref.read(appAuthenticatorProvider).authenticate(reason);
    } finally {
      state = state.finishAuthenticating(unlocked: result == AppAuthResult.unlocked);
    }
    return result;
  }
}

final appLockProvider = NotifierProvider<AppLockController, AppLockSession>(AppLockController.new);

/// Whether the lock screen is up.
final appLockedProvider = Provider<bool>((ref) => ref.watch(appLockProvider.select((session) => session.locked)));

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// How one attempt to unlock ended.
enum AppAuthResult {
  unlocked,

  /// Cancelled or not recognised; the lock screen offers to try again.
  notUnlocked,

  /// The device has no screen lock (PIN, pattern, password) to fall back on.
  noScreenLock,

  /// Too many failed attempts; the device asks the user to wait.
  lockedOut,
}

/// Proves the user is the device's owner. The app lock talks only to this,
/// so tests swap in a fake.
abstract interface class AppAuthenticator {
  /// Whether the device has a screen lock the user can unlock with.
  Future<bool> isAvailable();

  /// Shows the system prompt: fingerprint or face, with the device PIN,
  /// pattern or password as the fallback. [reason] is shown on the prompt.
  Future<AppAuthResult> authenticate(String reason);
}

/// [AppAuthenticator] backed by the platform's biometric prompt.
class DeviceAuthenticator implements AppAuthenticator {
  DeviceAuthenticator([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<AppAuthResult> authenticate(String reason) async {
    try {
      final unlocked = await _auth.authenticate(localizedReason: reason, sensitiveTransaction: false);
      return unlocked ? AppAuthResult.unlocked : AppAuthResult.notUnlocked;
    } on LocalAuthException catch (error) {
      return authResultForError(error.code);
    } on PlatformException {
      return AppAuthResult.notUnlocked;
    }
  }
}

/// What a failed prompt means for the lock screen.
AppAuthResult authResultForError(LocalAuthExceptionCode code) => switch (code) {
      LocalAuthExceptionCode.noCredentialsSet => AppAuthResult.noScreenLock,
      LocalAuthExceptionCode.temporaryLockout || LocalAuthExceptionCode.biometricLockout => AppAuthResult.lockedOut,
      _ => AppAuthResult.notUnlocked,
    };

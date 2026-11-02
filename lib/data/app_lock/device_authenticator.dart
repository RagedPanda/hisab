import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

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

/// Everything the system prompt shows, already in the app's language. The
/// platform's own defaults are English only, so each line is passed in.
class AuthPromptText {
  const AuthPromptText({required this.reason, required this.title, required this.hint, required this.cancel, required this.fallback});

  /// Why the prompt is up (Android description, iOS reason line).
  final String reason;

  /// Android prompt title.
  final String title;

  /// Android subtitle under the title.
  final String hint;

  /// Cancel button, where the platform shows one.
  final String cancel;

  /// iOS button to fall back to the device passcode.
  final String fallback;
}

/// The per-platform messages handed to `local_auth` for [text].
List<AuthMessages> authMessagesFor(AuthPromptText text) => [
      AndroidAuthMessages(signInTitle: text.title, signInHint: text.hint, cancelButton: text.cancel),
      IOSAuthMessages(cancelButton: text.cancel, localizedFallbackTitle: text.fallback),
    ];

/// Proves the user is the device's owner. The app lock talks only to this,
/// so tests swap in a fake.
abstract interface class AppAuthenticator {
  /// Whether the device has a screen lock the user can unlock with.
  Future<bool> isAvailable();

  /// Shows the system prompt: fingerprint or face, with the device PIN,
  /// pattern or password as the fallback, worded by [prompt].
  Future<AppAuthResult> authenticate(AuthPromptText prompt);
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
  Future<AppAuthResult> authenticate(AuthPromptText prompt) async {
    try {
      final unlocked = await _auth.authenticate(
        localizedReason: prompt.reason,
        authMessages: authMessagesFor(prompt),
        sensitiveTransaction: false,
      );
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

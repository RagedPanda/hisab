import 'dart:async';

import 'package:hisab/data/app_lock/device_authenticator.dart';
import 'package:hisab/data/app_lock/secure_window_channel.dart';

/// Answers prompts from [results] in order (then "not unlocked"); with
/// [hold] set, each prompt waits until the test completes [pending].
class FakeAuthenticator implements AppAuthenticator {
  FakeAuthenticator({this.available = true, List<AppAuthResult> results = const []}) : results = [...results];

  bool available;
  final List<AppAuthResult> results;
  bool hold = false;
  Completer<AppAuthResult>? pending;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<AppAuthResult> authenticate(String reason) {
    prompts++;
    if (hold) return (pending = Completer<AppAuthResult>()).future;
    return Future.value(results.isEmpty ? AppAuthResult.notUnlocked : results.removeAt(0));
  }
}

class FakeSecureWindow extends SecureWindowChannel {
  final calls = <bool>[];

  @override
  bool get isSupported => true;

  @override
  Future<void> setSecure(bool secure) async => calls.add(secure);

  final recentsCalls = <bool>[];

  @override
  Future<void> setRecentsHidden(bool hidden) async => recentsCalls.add(hidden);
}

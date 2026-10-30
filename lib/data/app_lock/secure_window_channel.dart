import 'dart:io';

import 'package:flutter/services.dart';

/// Android's FLAG_SECURE on Hisab's window: the recent-apps switcher shows
/// a blank card and screenshots are blocked. A no-op off Android.
class SecureWindowChannel {
  const SecureWindowChannel();

  static const _methods = MethodChannel('com.ragedpanda.hisab/app_lock');

  bool get isSupported => Platform.isAndroid;

  Future<void> setSecure(bool secure) async {
    if (!isSupported) return;
    await _methods.invokeMethod<void>('setSecure', secure);
  }
}

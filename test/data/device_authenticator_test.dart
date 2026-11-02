import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/app_lock/device_authenticator.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

void main() {
  const text = AuthPromptText(reason: 'Unlock', title: 'Lock', hint: 'Touch', cancel: 'Stop', fallback: 'PIN');

  test('every line of the Android prompt comes from the app, not the English defaults', () {
    final android = authMessagesFor(text).whereType<AndroidAuthMessages>().single;
    expect(android.args, {'biometricHint': 'Touch', 'cancelButton': 'Stop', 'signInTitle': 'Lock'});
  });

  test('the iOS prompt gets its cancel and passcode buttons', () {
    final ios = authMessagesFor(text).whereType<IOSAuthMessages>().single;
    expect(ios.cancelButton, 'Stop');
    expect(ios.localizedFallbackTitle, 'PIN');
  });
}

import 'package:shared_preferences/shared_preferences.dart';

/// Asks for the notification permission (Android 13+) that announces SMS
/// captured while the app is closed, and remembers that it asked, so users
/// who already had Bank SMS on before the feature existed are asked once.
class SmsNotificationPrompt {
  SmsNotificationPrompt(this.prefs, {required this.request});
  final SharedPreferences prefs;

  /// Shows the system prompt. Capture works whatever the answer.
  final Future<void> Function() request;

  static const key = 'smsNotificationAsked';

  bool get asked => prefs.getBool(key) ?? false;

  /// Asks now, e.g. when the user turns Bank SMS on.
  Future<void> ask() async {
    await prefs.setBool(key, true);
    await request();
  }

  /// Asks only if this install has never asked before.
  Future<void> askOnce() async {
    if (!asked) await ask();
  }
}

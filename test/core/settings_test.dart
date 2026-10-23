import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('SMS auto-add is on for a new install', () async {
    SharedPreferences.setMockInitialValues({});
    expect(AppSettings.fromPrefs(await SharedPreferences.getInstance()).smsAutoAdd, isTrue);
  });

  test('a false saved by an older build without the user choosing it becomes on', () async {
    SharedPreferences.setMockInitialValues({'smsAutoAdd': false});
    expect(AppSettings.fromPrefs(await SharedPreferences.getInstance()).smsAutoAdd, isTrue);
  });

  test('turning auto-add off survives a save and reload', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await const AppSettings().copyWith(smsAutoAdd: false, smsAutoAddChosen: true).writeTo(prefs);
    final reloaded = AppSettings.fromPrefs(prefs);
    expect(reloaded.smsAutoAdd, isFalse);
    expect(reloaded.smsAutoAddChosen, isTrue);
  });
}

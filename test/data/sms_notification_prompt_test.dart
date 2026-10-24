import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/sms/sms_notification_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late int requests;
  late SmsNotificationPrompt prompt;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    requests = 0;
    prompt = SmsNotificationPrompt(await SharedPreferences.getInstance(), request: () async => requests++);
  });

  test('#42: an install that never asked is asked once on start', () async {
    await prompt.askOnce();
    await prompt.askOnce();
    expect(requests, 1);
    expect(prompt.asked, isTrue);
  });

  test('turning Bank SMS on asks even after an earlier prompt', () async {
    await prompt.askOnce();
    await prompt.ask();
    expect(requests, 2);
  });

  test('a prompt shown from the toggle is not repeated on the next start', () async {
    await prompt.ask();
    await prompt.askOnce();
    expect(requests, 1);
  });
}

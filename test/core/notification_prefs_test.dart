import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/notification_prefs.dart';
import 'package:hisab/domain/notifications/evening_summary.dart';
import 'package:hisab/domain/notifications/notification_kinds.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('nothing stored reads as no choices and a 9 pm summary', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = NotificationPrefs.fromPrefs(await SharedPreferences.getInstance());
    expect(prefs.choices, isEmpty);
    expect(prefs.eveningSummaryMinute, kDefaultEveningSummaryMinute);
  });

  test('round-trips only the switches the user flipped', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SharedPreferences.getInstance();
    await const NotificationPrefs()
        .withChoice(NotificationKind.reminders, false)
        .withChoice(NotificationKind.eveningSummary, true)
        .withEveningSummaryMinute(20 * 60 + 30)
        .writeTo(store);

    final read = NotificationPrefs.fromPrefs(store);
    expect(read.choices, {NotificationKind.reminders: false, NotificationKind.eveningSummary: true});
    expect(read.eveningSummaryMinute, 20 * 60 + 30);
    expect(store.containsKey(notificationChoiceKey(NotificationKind.bankSms)), isFalse, reason: 'an untouched switch keeps following the setup');
  });

  test('a stored time out of range is clamped', () async {
    SharedPreferences.setMockInitialValues({kEveningSummaryMinuteKey: 5000});
    expect(NotificationPrefs.fromPrefs(await SharedPreferences.getInstance()).eveningSummaryMinute, 24 * 60 - 1);
  });
}

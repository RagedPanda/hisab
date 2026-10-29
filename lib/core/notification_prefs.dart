import 'package:shared_preferences/shared_preferences.dart';

import '../domain/notifications/evening_summary.dart';
import '../domain/notifications/notification_kinds.dart';

/// Preference key of the switch for [kind]; absent until the user flips it.
String notificationChoiceKey(NotificationKind kind) => 'notify.${kind.name}';

/// Preference key of the evening summary time, in minutes after midnight.
const String kEveningSummaryMinuteKey = 'notify.eveningSummaryMinute';

/// Settings > Notifications, kept on this device beside [AppSettings].
/// Holds only the switches the user flipped; see [notificationKindOn] for
/// how an untouched one reads. The salary alert's switch lives on the
/// salary setup and is not stored here.
class NotificationPrefs {
  const NotificationPrefs({this.choices = const {}, this.eveningSummaryMinute = kDefaultEveningSummaryMinute});

  final Map<NotificationKind, bool> choices;

  /// When the evening summary fires, in minutes after local midnight.
  final int eveningSummaryMinute;

  NotificationPrefs withChoice(NotificationKind kind, bool on) =>
      NotificationPrefs(choices: {...choices, kind: on}, eveningSummaryMinute: eveningSummaryMinute);

  NotificationPrefs withEveningSummaryMinute(int minute) => NotificationPrefs(choices: choices, eveningSummaryMinute: clampMinuteOfDay(minute));

  static NotificationPrefs fromPrefs(SharedPreferences prefs) => NotificationPrefs(
        choices: {
          for (final kind in NotificationKind.values)
            if (prefs.containsKey(notificationChoiceKey(kind))) kind: prefs.getBool(notificationChoiceKey(kind)) ?? false,
        },
        eveningSummaryMinute: clampMinuteOfDay(prefs.getInt(kEveningSummaryMinuteKey) ?? kDefaultEveningSummaryMinute),
      );

  Future<void> writeTo(SharedPreferences prefs) async {
    for (final MapEntry(key: kind, value: on) in choices.entries) {
      await prefs.setBool(notificationChoiceKey(kind), on);
    }
    await prefs.setInt(kEveningSummaryMinuteKey, eveningSummaryMinute);
  }
}

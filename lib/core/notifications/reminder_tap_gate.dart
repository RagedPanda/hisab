import 'notification_gateway.dart';

/// How long an identical notification tap counts as the same one.
const kDuplicateTapWindow = Duration(seconds: 10);

/// Identity of a tap: which notification and which button.
String tapKey(NotificationTap tap) => '${tap.payload ?? ''}|${tap.actionId ?? ''}';

/// Whether a tap with [key] at [now] repeats the [previousKey] tap seen at
/// [previousAt]. A cold start reports the launching tap twice (as the launch
/// details and through the response callback); handling both would open the
/// prefilled editor twice.
bool isDuplicateTap({
  required String? previousKey,
  required DateTime? previousAt,
  required String key,
  required DateTime now,
  Duration window = kDuplicateTapWindow,
}) =>
    previousKey == key && previousAt != null && now.difference(previousAt).abs() < window;

/// Lets each notification tap through once, dropping the duplicate delivery.
class ReminderTapGate {
  ReminderTapGate({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  String? _lastKey;
  DateTime? _lastAt;

  /// True when [tap] should be handled; false for a duplicate delivery.
  bool admit(NotificationTap tap) {
    final key = tapKey(tap);
    final now = _clock();
    if (isDuplicateTap(previousKey: _lastKey, previousAt: _lastAt, key: key, now: now)) return false;
    _lastKey = key;
    _lastAt = now;
    return true;
  }
}

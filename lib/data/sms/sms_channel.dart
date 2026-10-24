import 'dart:io';

import 'package:flutter/services.dart';

/// Raw SMS as delivered by the platform.
class RawSms {
  const RawSms({required this.sender, required this.body, required this.receivedAt});
  final String sender;
  final String body;
  final DateTime receivedAt;

  static RawSms fromMap(Map<dynamic, dynamic> map) => RawSms(
        sender: (map['sender'] as String?) ?? '',
        body: (map['body'] as String?) ?? '',
        receivedAt: DateTime.fromMillisecondsSinceEpoch((map['date'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch),
      );
}

/// Thin wrapper over the Android platform channel. Every method is a no-op on
/// iOS, where apps cannot read SMS; iOS users paste or share messages instead.
class SmsChannel {
  static const _methods = MethodChannel('com.sarv.hisab/sms');
  static const _events = EventChannel('com.sarv.hisab/sms_events');

  static bool get isSupported => Platform.isAndroid;

  static Future<List<RawSms>> readInbox({required DateTime since, int limit = 2000}) async {
    if (!isSupported) return const [];
    final result = await _methods.invokeMethod<List<dynamic>>('readInbox', {'since': since.millisecondsSinceEpoch, 'limit': limit});
    return (result ?? const []).map((row) => RawSms.fromMap(row as Map)).toList();
  }

  /// Bank SMS the background receiver queued while the app was closed.
  /// Reading empties the native queue.
  static Future<List<RawSms>> drainQueue() async {
    if (!isSupported) return const [];
    final result = await _methods.invokeMethod<List<dynamic>>('drainQueue');
    return (result ?? const []).map((row) => RawSms.fromMap(row as Map)).toList();
  }

  /// Clears the "New bank transaction" notifications of [messages] once the
  /// app has processed them.
  static Future<void> cancelNotifications(List<RawSms> messages) async {
    if (!isSupported || messages.isEmpty) return;
    await _methods.invokeMethod<void>('cancelNotifications', [
      for (final message in messages) {'sender': message.sender, 'body': message.body},
    ]);
  }

  /// Turns the background receiver on or off and hands it the notification
  /// text in the user's language.
  static Future<void> configureCapture(SmsCaptureConfig config) async {
    if (!isSupported) return;
    await _methods.invokeMethod<void>('configureCapture', config.toMap());
  }

  /// Fires each time the receiver queues a message while the app runs.
  static Stream<void> queueSignals() {
    if (!isSupported) return const Stream.empty();
    return _events.receiveBroadcastStream().map((_) {});
  }
}

/// Settings for the native background receiver. The body templates keep
/// literal `{amount}` and `{sender}` placeholders for the receiver to fill.
class SmsCaptureConfig {
  const SmsCaptureConfig({
    required this.enabled,
    required this.channelName,
    required this.title,
    required this.bodyWithAmount,
    required this.bodyWithoutAmount,
  });

  final bool enabled;
  final String channelName;
  final String title;
  final String bodyWithAmount;
  final String bodyWithoutAmount;

  Map<String, Object> toMap() => {
        'enabled': enabled,
        'channelName': channelName,
        'title': title,
        'bodyWithAmount': bodyWithAmount,
        'bodyWithoutAmount': bodyWithoutAmount,
      };
}

/// The device side of SMS capture, behind an interface so the ingest
/// service can be tested without a platform channel.
abstract interface class SmsSource {
  Future<List<RawSms>> readInbox({required DateTime since});
  Future<List<RawSms>> drainQueue();
  Future<void> cancelNotifications(List<RawSms> messages);
}

class PlatformSmsSource implements SmsSource {
  const PlatformSmsSource();

  @override
  Future<List<RawSms>> readInbox({required DateTime since}) => SmsChannel.readInbox(since: since);

  @override
  Future<List<RawSms>> drainQueue() => SmsChannel.drainQueue();

  @override
  Future<void> cancelNotifications(List<RawSms> messages) => SmsChannel.cancelNotifications(messages);
}

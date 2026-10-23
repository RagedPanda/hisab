import 'dart:io';

import 'package:flutter/services.dart';

/// Raw SMS as delivered by the platform.
class RawSms {
  const RawSms({required this.sender, required this.body, required this.receivedAt});

  /// Sender recorded for messages the user pasted or shared into Hisab.
  /// Their receive time is the paste time, not an inbox time.
  static const pastedSender = 'PASTED';
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

  static Stream<RawSms> incoming() {
    if (!isSupported) return const Stream.empty();
    return _events.receiveBroadcastStream().map((event) => RawSms.fromMap(event as Map));
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/sms/sms_channel.dart';

/// The host running these tests is not Android, so every channel call takes
/// its early return; the Android side needs an on-device test.
void main() {
  group('raw SMS from the platform map', () {
    test('reads sender, body and the epoch date', () {
      final sms = RawSms.fromMap({'sender': 'HDFCBK', 'body': 'Rs.459.00 debited', 'date': 1792540800000});
      expect(sms.sender, 'HDFCBK');
      expect(sms.body, 'Rs.459.00 debited');
      expect(sms.receivedAt, DateTime.fromMillisecondsSinceEpoch(1792540800000));
    });

    test('missing fields fall back to empty text and now', () {
      // The platform date has millisecond precision.
      final before = DateTime.now().subtract(const Duration(milliseconds: 1));
      final sms = RawSms.fromMap(const {});
      expect((sms.sender, sms.body), ('', ''));
      expect(sms.receivedAt.isBefore(before), isFalse);
    });
  });

  test('the capture config is sent as a flat map', () {
    const config = SmsCaptureConfig(enabled: true, channelName: 'Bank SMS', title: 'New bank transaction', bodyWithAmount: '{amount} from {sender}', bodyWithoutAmount: 'From {sender}');
    expect(config.toMap(), {
      'enabled': true,
      'channelName': 'Bank SMS',
      'title': 'New bank transaction',
      'bodyWithAmount': '{amount} from {sender}',
      'bodyWithoutAmount': 'From {sender}',
      'notify': true,
    });
  });

  test('off Android the platform source reads nothing and sends nothing', () async {
    const source = PlatformSmsSource();
    final message = RawSms(sender: 'HDFCBK', body: 'Rs.459.00 debited', receivedAt: DateTime(2026, 10, 21));

    expect(SmsChannel.isSupported, isFalse);
    expect(await source.readInbox(since: DateTime(2026, 10, 1)), isEmpty);
    expect(await source.drainQueue(), isEmpty);
    await source.cancelNotifications([message]);
    await SmsChannel.configureCapture(const SmsCaptureConfig(enabled: false, channelName: '', title: '', bodyWithAmount: '', bodyWithoutAmount: ''));
    expect(await SmsChannel.queueSignals().isEmpty, isTrue);
  });
}

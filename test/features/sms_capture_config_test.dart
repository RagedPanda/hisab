import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/features/sms/sms_auto_sync.dart';
import 'package:hisab/l10n/l10n.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final hi = lookupAppLocalizations(const Locale('hi'));

  test('#103: with auto-add on the notification does not ask for a review', () {
    final config = smsCaptureConfig(en, enabled: true, autoAdd: true);
    expect(config.bodyWithAmount, '{amount} from {sender}. Open Hisab to add it.');
    expect(config.bodyWithoutAmount, 'From {sender}. Open Hisab to add it.');
  });

  test('with auto-add off the notification asks for a review', () {
    final config = smsCaptureConfig(en, enabled: true, autoAdd: false);
    expect(config.bodyWithAmount, '{amount} from {sender}. Tap to review.');
    expect(config.bodyWithoutAmount, 'From {sender}. Tap to review.');
  });

  test('Hindi text keeps both placeholders for the native side', () {
    for (final autoAdd in [true, false]) {
      final config = smsCaptureConfig(hi, enabled: true, autoAdd: autoAdd);
      expect(config.bodyWithAmount, allOf(contains('{amount}'), contains('{sender}')));
      expect(config.bodyWithoutAmount, contains('{sender}'));
      expect(config.bodyWithAmount, isNot(config.bodyWithoutAmount));
    }
    expect(smsCaptureConfig(hi, enabled: true, autoAdd: true).bodyWithAmount, isNot(smsCaptureConfig(hi, enabled: true, autoAdd: false).bodyWithAmount));
  });
}

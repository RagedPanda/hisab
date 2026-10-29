import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/money.dart';
import 'package:hisab/core/notifications/background_actions.dart';
import 'package:hisab/core/notifications/reminder_alert_text.dart';
import 'package:hisab/core/notifications/reminder_payload.dart';
import 'package:hisab/core/notifications/sms_entry_alert.dart';
import 'package:hisab/core/notifications/sms_entry_payload.dart';
import 'package:hisab/features/sms/sms_entry_notifier.dart';

void main() {
  const ref = (smsId: 'a1b2c3', entryId: 'entry-9');
  final payload = smsEntryPayload(smsId: ref.smsId, entryId: ref.entryId);

  group('SMS entry payload', () {
    test('round-trips the SMS and entry ids', () {
      expect(smsEntryFromPayload(payload), ref);
    });
    test('reminder payloads, junk and half-filled payloads are not SMS entries', () {
      expect(smsEntryFromPayload(reminderPayload('r1')), isNull);
      expect(smsEntryFromPayload(null), isNull);
      expect(smsEntryFromPayload('not a uri ::'), isNull);
      expect(smsEntryFromPayload('hisab://sms-entry?sms=a1'), isNull);
      expect(reminderIdFromPayload(payload), isNull, reason: 'the reminder handlers ignore it');
    });
    test('one stable notification id per SMS', () {
      expect(smsEntryNotificationId('a1'), smsEntryNotificationId('a1'));
      expect(smsEntryNotificationId('a1'), isNot(smsEntryNotificationId('a2')));
    });
    test('Change category opens the picker, a tap opens the entry, Undo opens nothing', () {
      expect(smsEntryLocationFor(payload: payload, actionId: kSmsChangeCategoryActionId), '/sms/entry-category?entry=entry-9&sms=a1b2c3');
      expect(smsEntryLocationFor(payload: payload, actionId: null), '/entry?id=entry-9');
      expect(smsEntryLocationFor(payload: payload, actionId: kSmsUndoActionId), isNull);
      expect(smsEntryLocationFor(payload: reminderPayload('r1'), actionId: null), isNull);
    });
  });

  group('BackgroundAction.of', () {
    test('Undo on an SMS entry and Snooze on a reminder run in the background', () {
      expect(BackgroundAction.of(payload: payload, actionId: kSmsUndoActionId), isA<UndoSmsEntry>().having((action) => action.ref, 'ref', ref));
      expect(BackgroundAction.of(payload: reminderPayload('r1'), actionId: kSnoozeActionId), isA<SnoozeReminder>());
    });
    test('UI actions, plain taps and crossed ids do nothing there', () {
      expect(BackgroundAction.of(payload: payload, actionId: kSmsChangeCategoryActionId), isNull);
      expect(BackgroundAction.of(payload: payload, actionId: null), isNull);
      expect(BackgroundAction.of(payload: payload, actionId: kSnoozeActionId), isNull);
      expect(BackgroundAction.of(payload: reminderPayload('r1'), actionId: kSmsUndoActionId), isNull);
      expect(BackgroundAction.of(payload: reminderPayload('r1'), actionId: kMarkPaidActionId), isNull);
    });
  });

  group('smsEntryAlertFor', () {
    SmsEntryAlertBuilder build(String localeCode) => ({String? payee, String? categoryName, String? accountName, bool asks = false}) => smsEntryAlertFor(
          ref: ref,
          amountMinor: 45900,
          payee: payee,
          categoryName: categoryName,
          accountName: accountName,
          asksForCategory: asks,
          l10n: notificationLocalizations(localeCode),
          moneyFormat: MoneyFormat.inr,
        );

    test('amount in the title; payee, category and account in the body', () {
      final alert = build('en')(payee: 'Swiggy', categoryName: 'Food delivery', accountName: 'HDFC Bank ••1234');
      expect(alert.title, 'Added ₹459 from SMS');
      expect(alert.body, 'Swiggy · Food delivery · HDFC Bank ••1234');
      expect(alert.id, smsEntryNotificationId(ref.smsId));
      expect(smsEntryFromPayload(alert.payload), ref);
    });
    test('missing parts are left out and a new person gets the hint', () {
      expect(build('en')(payee: 'Rahul Sharma', accountName: ' ', asks: true).body, 'Rahul Sharma\nNew payee: pick a category');
      expect(build('en')().body, '');
    });
    test('labels follow the app language', () {
      final alert = build('hi')(payee: 'Swiggy');
      expect(alert.changeCategoryLabel, 'श्रेणी बदलें');
      expect(alert.undoLabel, 'पूर्ववत करें');
    });
  });

  test('announces by notification only while Hisab is off screen', () {
    expect(announcesInNotification(AppLifecycleState.resumed), isFalse);
    expect(announcesInNotification(null), isFalse);
    for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused, AppLifecycleState.detached]) {
      expect(announcesInNotification(state), isTrue, reason: '$state');
    }
  });
}

typedef SmsEntryAlertBuilder = dynamic Function({String? payee, String? categoryName, String? accountName, bool asks});

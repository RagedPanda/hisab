import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/money.dart';
import 'package:hisab/core/notifications/notification_gateway.dart';
import 'package:hisab/core/notifications/reminder_alert_text.dart';
import 'package:hisab/domain/notifications/evening_summary.dart';
import 'package:hisab/domain/notifications/notification_kinds.dart';
import 'package:hisab/features/notifications/notification_texts.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  final en = notificationLocalizations('en');
  final hi = notificationLocalizations('hi');
  const quiet = EveningSummary(spentMinor: 0, reviewCount: 0, dueCount: 0, dueMinor: 0);
  const busy = EveningSummary(spentMinor: 45000, reviewCount: 2, dueCount: 1, dueMinor: 185000);

  setUpAll(() => initializeDateFormatting('hi'));

  group('eveningSummaryBody', () {
    test('says what was spent, what waits for review and what falls due', () {
      expect(eveningSummaryBody(busy, en, moneyFormat: MoneyFormat.inr), 'Spent ₹450 today · 2 SMS to review · 1 bill due in the next 3 days (₹1,850)');
    });

    test('a quiet day leaves out the empty parts', () {
      expect(eveningSummaryBody(quiet, en, moneyFormat: MoneyFormat.inr), 'Nothing spent today');
    });

    test('bills without a known amount are only counted', () {
      const unpriced = EveningSummary(spentMinor: 0, reviewCount: 1, dueCount: 3, dueMinor: 0);
      expect(eveningSummaryBody(unpriced, en, moneyFormat: MoneyFormat.inr), 'Nothing spent today · 1 SMS to review · 3 bills due in the next 3 days');
    });

    test('is written in Hindi for Hindi users', () {
      expect(eveningSummaryBody(busy, hi, moneyFormat: MoneyFormat.inr), 'आज ₹450 खर्च · 2 SMS देखने बाकी · अगले 3 दिन में 1 बिल देय (₹1,850)');
    });
  });

  test('the summary alert fires at its evening on the updates channel without actions', () {
    final fireAt = DateTime(2026, 10, 29, 21);
    final alert = eveningSummaryAlert(busy, en, slot: 1, fireAt: fireAt, moneyFormat: MoneyFormat.inr);
    expect(alert.id, eveningSummaryNotificationId(1));
    expect(alert.title, 'Your day in Hisab');
    expect(alert.fireAt, fireAt);
    expect(alert.payload, kEveningSummaryPayload);
    expect(alert.withActions, isFalse);
    expect(alert.channel, AlertChannel.updates);
    expect({for (var slot = 0; slot < kEveningSummaryNightsAhead; slot++) eveningSummaryNotificationId(slot)}, hasLength(kEveningSummaryNightsAhead));
  });

  group('sampleAlertFor', () {
    final now = DateTime(2026, 10, 29, 18);
    AlertRequest sample(NotificationKind kind, {bool smsAutoAdd = false}) =>
        sampleAlertFor(kind, en, now: now, moneyFormat: MoneyFormat.inr, summary: busy, smsAutoAdd: smsAutoAdd);

    test('every kind is marked as a sample, has no actions and opens nothing in particular', () {
      for (final kind in NotificationKind.values) {
        final alert = sample(kind);
        expect(alert.title, startsWith('Sample · '), reason: kind.name);
        expect(alert.withActions, isFalse);
        expect(alert.payload, kSamplePayload);
        expect(alert.id, sampleNotificationId(kind));
        expect(alert.channel, AlertChannel.updates);
      }
      expect(NotificationKind.values.map(sampleNotificationId).toSet(), hasLength(NotificationKind.values.length));
    });

    test('shows what each kind looks like', () {
      expect(sample(NotificationKind.reminders).title, 'Sample · Electricity bill');
      expect(sample(NotificationKind.reminders).body, 'Due in 2 days · ₹1,850');
      expect(sample(NotificationKind.salary).title, 'Sample · ${en.salaryNotSeenTitle}');
      expect(sample(NotificationKind.bankSms).body, en.smsNotificationBodyAmount('₹1,850', kSampleSmsSender));
      expect(sample(NotificationKind.bankSms, smsAutoAdd: true).body, en.smsNotificationBodyAmountAutoAdd('₹1,850', kSampleSmsSender));
      expect(sample(NotificationKind.eveningSummary).body, eveningSummaryBody(busy, en, moneyFormat: MoneyFormat.inr));
    });

    test('is localised', () {
      final alert = sampleAlertFor(NotificationKind.reminders, hi, now: now, moneyFormat: MoneyFormat.inr, summary: quiet);
      expect(alert.title, 'नमूना · बिजली का बिल');
    });
  });
}

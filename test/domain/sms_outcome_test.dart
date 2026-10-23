import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/sms/sms_outcome.dart';

void main() {
  group('smsOutcomeFor', () {
    test('maps every stored status to its outcome', () {
      expect(smsOutcomeFor(SmsLogStatus.added), SmsOutcome.added);
      expect(smsOutcomeFor(SmsLogStatus.duplicate), SmsOutcome.duplicate);
      expect(smsOutcomeFor(SmsLogStatus.notBank), SmsOutcome.ignored);
      expect(smsOutcomeFor(SmsLogStatus.ignored), SmsOutcome.ignored);
      expect(smsOutcomeFor(SmsLogStatus.skipped), SmsOutcome.unparsed);
      expect(smsOutcomeFor(SmsLogStatus.pending), SmsOutcome.pending);
      expect(smsOutcomeFor(SmsLogStatus.undone), SmsOutcome.undone);
    });

    test('an unknown status reads as ignored', () => expect(smsOutcomeFor('something_new'), SmsOutcome.ignored));
  });

  test('only ignored and unparsed messages can be processed again', () {
    final reprocessable = SmsOutcome.values.where(canReprocessSms).toSet();
    expect(reprocessable, {SmsOutcome.ignored, SmsOutcome.unparsed});
  });

  test('not-bank messages never keep their text; possible transactions do', () {
    expect(storedSmsBody(SmsLogStatus.notBank, 'Your order has shipped'), isEmpty);
    for (final status in [SmsLogStatus.added, SmsLogStatus.pending, SmsLogStatus.skipped, SmsLogStatus.duplicate, SmsLogStatus.ignored]) {
      expect(storedSmsBody(status, 'Rs.10 debited'), 'Rs.10 debited', reason: status);
    }
  });

  test('OTPs and promotions never keep their text, whatever the status', () {
    const otp = 'Your OTP for login is 482913. Do not share it.';
    const promo = 'Congratulations! You are eligible for a pre-approved loan. Apply now.';
    for (final status in [SmsLogStatus.skipped, SmsLogStatus.duplicate, SmsLogStatus.ignored, SmsLogStatus.notBank]) {
      expect(storedSmsBody(status, otp), isEmpty, reason: status);
      expect(storedSmsBody(status, promo), isEmpty, reason: status);
    }
    expect(storedSmsBody(SmsLogStatus.skipped, 'Your statement is ready on NetBanking.'), isNotEmpty,
        reason: 'a bank text that is neither an OTP nor a promotion stays re-processable');
    expect(storedSmsBody(SmsLogStatus.added, 'Refund of Rs.200 under the cashback offer credited to A/c XX1234'), isNotEmpty,
        reason: 'a refund is a real transaction even when it mentions an offer');
  });

  test('re-deliveries are logged only when their text could be kept', () {
    expect(logsDuplicateOf(SmsLogStatus.notBank, 'Your order has shipped'), isFalse);
    expect(logsDuplicateOf(SmsLogStatus.skipped, 'Your OTP is 123456'), isFalse);
    expect(logsDuplicateOf(SmsLogStatus.added, 'Rs.10 debited'), isTrue);
    expect(logsDuplicateOf(SmsLogStatus.skipped, 'Your statement is ready'), isTrue);
  });

  group('isSameDelivery', () {
    final logged = DateTime(2026, 10, 21, 10, 0, 0);
    test('a few seconds apart is one delivery read twice', () {
      expect(isSameDelivery(logged, logged), isTrue);
      expect(isSameDelivery(logged, logged.add(const Duration(seconds: 7))), isTrue);
      expect(isSameDelivery(logged, logged.subtract(const Duration(seconds: 59))), isTrue);
    });
    test('a minute or more apart is a re-delivery', () {
      expect(isSameDelivery(logged, logged.add(const Duration(minutes: 1))), isFalse);
      expect(isSameDelivery(logged, logged.add(const Duration(hours: 3))), isFalse);
    });
  });

  test('isPersonalSender tells phone numbers from business headers', () {
    expect(isPersonalSender('+919810000000'), isTrue);
    expect(isPersonalSender('98100 00000'), isTrue);
    expect(isPersonalSender('VM-HDFCBK'), isFalse);
    expect(isPersonalSender('AMAZON'), isFalse);
    expect(isPersonalSender('57575'), isFalse, reason: 'short codes belong to businesses');
  });

  group('smsBodyPreview', () {
    test('collapses line breaks and runs of spaces', () => expect(smsBodyPreview('Rs.10\ndebited   from\tA/c'), 'Rs.10 debited from A/c'));
    test('keeps short bodies whole', () => expect(smsBodyPreview('short', maxChars: 10), 'short'));
    test('cuts long bodies with an ellipsis', () => expect(smsBodyPreview('abcde fghij', maxChars: 6), 'abcde…'));
  });

  test('countSmsOutcomes counts each outcome and reports zeros', () {
    final counts = countSmsOutcomes([SmsOutcome.added, SmsOutcome.added, SmsOutcome.pending]);
    expect(counts[SmsOutcome.added], 2);
    expect(counts[SmsOutcome.pending], 1);
    expect(counts[SmsOutcome.undone], 0);
    expect(counts.length, SmsOutcome.values.length);
  });
}

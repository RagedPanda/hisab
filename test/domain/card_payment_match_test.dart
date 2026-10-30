import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/cards/card_payment_match.dart';

void main() {
  final at = DateTime(2026, 10, 20, 11);

  CardPaymentCandidate candidate(String id, {int amount = 1200000, Duration offset = Duration.zero, bool hinted = false}) =>
      CardPaymentCandidate(entryId: id, amountMinor: amount, occurredAt: at.add(offset), hintsCardBill: hinted);

  group('pickCardPaymentMatch', () {
    test('takes the single debit of the same amount within the window', () {
      final match = pickCardPaymentMatch([candidate('a', offset: const Duration(days: -1))], amountMinor: 1200000, at: at);
      expect(match?.entryId, 'a');
    });

    test('ignores other amounts and debits outside the window', () {
      final candidates = [candidate('other', amount: 1100000), candidate('old', offset: const Duration(days: -4))];
      expect(pickCardPaymentMatch(candidates, amountMinor: 1200000, at: at), isNull);
    });

    test('two equal debits without card wording cannot be told apart', () {
      expect(pickCardPaymentMatch([candidate('a'), candidate('b', offset: const Duration(hours: 2))], amountMinor: 1200000, at: at), isNull);
    });

    test('a debit naming a card bill wins, the closest first', () {
      final candidates = [
        candidate('plain'),
        candidate('far', hinted: true, offset: const Duration(days: 2)),
        candidate('near', hinted: true, offset: const Duration(hours: -3)),
      ];
      expect(pickCardPaymentMatch(candidates, amountMinor: 1200000, at: at)?.entryId, 'near');
    });
  });

  group('hintsCardBillPayment', () {
    test('names a card bill', () {
      expect(hintsCardBillPayment('Rs 12,000 debited towards HDFC Credit Card bill'), isTrue);
      expect(hintsCardBillPayment('UPI to CRED Club'), isTrue);
      expect(hintsCardBillPayment('BillDesk CC payment'), isTrue);
    });

    test('does not fire on ordinary payees', () {
      expect(hintsCardBillPayment('Paid to Credence Foods'), isFalse);
      expect(hintsCardBillPayment('Swiggy order'), isFalse);
    });
  });

  group('linkedCardPaymentCategoryId', () {
    test('keeps the category the entry had', () {
      expect(linkedCardPaymentCategoryId(entryCategoryId: 'bill', entrySeedKey: 'credit_card_bill', cardPaymentCategoryId: 'ccp'), 'bill');
      expect(linkedCardPaymentCategoryId(entryCategoryId: 'mine', cardPaymentCategoryId: 'ccp'), 'mine', reason: 'a category the user made');
    });

    test('takes Credit Card Payment for none or a catch-all', () {
      expect(linkedCardPaymentCategoryId(cardPaymentCategoryId: 'ccp'), 'ccp');
      expect(linkedCardPaymentCategoryId(entryCategoryId: 'other', entrySeedKey: 'other_expense', cardPaymentCategoryId: 'ccp'), 'ccp');
      expect(linkedCardPaymentCategoryId(entryCategoryId: 'other', entrySeedKey: 'other_expense'), isNull);
    });
  });
}

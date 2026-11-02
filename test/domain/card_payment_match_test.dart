import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/domain/cards/card_payment_match.dart';

Account account(String id, {String type = 'card', String? bank, String? last4}) => Account(
      updatedAt: DateTime(2026),
      id: id,
      name: id,
      type: type,
      balanceMinor: 0,
      includeInTotal: type != 'card',
      color: 0,
      sortOrder: 0,
      bankName: bank,
      last4: last4,
    );

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

  // Made-up digits; wording follows the banks' public debit SMS.
  group('isCardBillDebitText', () {
    test('a debit towards a card bill', () {
      expect(isCardBillDebitText('Rs 12,000.00 debited from HDFC Bank A/c XX7781 on 21-10-26 towards HDFC Credit Card bill. Avl Bal Rs 30,000.00'), isTrue);
      expect(isCardBillDebitText('Rs.15,000.00 debited from A/c XX7781 on 20-10-26 towards CRED CLUB credit card bill. UPI Ref 629450500001.'), isTrue);
      expect(isCardBillDebitText('Your A/C XXXXX7781 Debited INR 8,000.00 on 21/10/26 -Transferred to BILLDESK-SBI CARD. Avl Balance INR 22,000.00'), isTrue);
    });

    test('not a debit card purchase or an ordinary payment', () {
      expect(isCardBillDebitText('Rs 500.00 debited from A/c XX7781 for Debit Card payment at AMAZON on 21-10-26'), isFalse);
      expect(isCardBillDebitText('Rs 250.00 debited from A/c XX7781 to VPA swiggy@icici on 21-10-26'), isFalse);
    });
  });

  group('billedCardLast4', () {
    test('reads the card digits, never the bank account digits', () {
      expect(billedCardLast4('Rs 8,000.00 debited from HDFC Bank A/c XX7781 on 21-10-26 towards Credit Card XX4521.'), '4521');
      expect(billedCardLast4('INR 8,000 debited from A/c XX7781 for CC ending 4521 payment'), '4521');
      expect(billedCardLast4('Rs 8,000 debited from A/c XX7781 towards Card No. XXXX4521 via BillDesk'), '4521');
      expect(billedCardLast4('Rs 8,000 debited from A/c XX7781 towards card 4xxx xxxx xxxx 4521'), '4521');
    });

    test('null when no card digits are named', () {
      expect(billedCardLast4('Rs 12,000.00 debited from HDFC Bank A/c XX7781 on 21-10-26 towards HDFC Credit Card bill.'), isNull);
    });
  });

  group('cardForBillDebit', () {
    final hdfc = account('hdfc', bank: 'HDFC Bank', last4: '4521');
    final axis = account('axis', bank: 'Axis Bank', last4: '9902');
    final savings = account('savings', type: 'bank', bank: 'HDFC Bank', last4: '7781');

    test('the card with the digits the SMS names, else none', () {
      expect(cardForBillDebit([hdfc, axis, savings], cardLast4: '9902', bank: 'HDFC Bank'), 'axis');
      expect(cardForBillDebit([hdfc, axis], cardLast4: '1111', bank: 'HDFC Bank'), isNull, reason: 'a card not added yet');
    });

    test('without digits, the one card of the bank, else the only card', () {
      expect(cardForBillDebit([hdfc, axis, savings], cardLast4: null, bank: 'HDFC Bank'), 'hdfc');
      expect(cardForBillDebit([axis, savings], cardLast4: null, bank: 'HDFC Bank'), 'axis');
      expect(cardForBillDebit([hdfc, axis], cardLast4: null, bank: 'SBI'), isNull);
      expect(cardForBillDebit([savings], cardLast4: null, bank: 'HDFC Bank'), isNull);
    });
  });

  group('awaitsCardPaymentSide', () {
    bool awaits({required bool missingCardSide, required bool ownIsCardSide, List<({String id, bool isDuplicate})>? pointing}) => awaitsCardPaymentSide(
          missingCardSide: missingCardSide,
          ownIsCardSide: ownIsCardSide,
          ownSmsId: 'own',
          pointing: pointing ?? [(id: 'own', isDuplicate: false)],
        );

    test('a transfer from one side waits for the other', () {
      expect(awaits(missingCardSide: true, ownIsCardSide: false), isTrue);
      expect(awaits(missingCardSide: false, ownIsCardSide: true), isTrue);
    });

    test('never for a second SMS of its own side', () {
      expect(awaits(missingCardSide: false, ownIsCardSide: false), isFalse, reason: 'two equal bank debits are two payments');
      expect(awaits(missingCardSide: true, ownIsCardSide: true), isFalse);
    });

    test('not once the other side links it; re-deliveries do not count', () {
      expect(awaits(missingCardSide: true, ownIsCardSide: false, pointing: [(id: 'own', isDuplicate: false), (id: 'card', isDuplicate: false)]), isFalse);
      expect(awaits(missingCardSide: true, ownIsCardSide: false, pointing: [(id: 'own', isDuplicate: false), (id: 'again', isDuplicate: true)]), isTrue);
    });

    test('not without an SMS of its own', () {
      expect(awaitsCardPaymentSide(missingCardSide: true, ownIsCardSide: false, ownSmsId: null, pointing: const []), isFalse);
    });
  });
}

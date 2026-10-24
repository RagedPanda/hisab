import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/sms/parsed_transaction.dart';
import 'package:hisab/domain/sms/payee_category_memory.dart';
import 'package:hisab/domain/sms/payee_normaliser.dart';

void main() {
  group('payee keys', () {
    test('a VPA is keyed by the lower-cased VPA, then by its readable name', () {
      expect(payeeMemoryKeys('Rahul.Sharma@OKAXIS'), ['vpa:rahul.sharma@okaxis', 'name:rahul sharma']);
      expect(payeeMemoryKey('Rahul.Sharma@OKAXIS'), 'vpa:rahul.sharma@okaxis');
    });
    test('a name is keyed by its normalised form, punctuation folded', () {
      expect(payeeMemoryKeys('MYNTRA DESIGNS'), ['name:myntra']);
      expect(payeeNameKey('M/s SHARMA TRADERS'), 'name:sharma traders');
      expect(payeeNameKey('  Cafe   Coffee-Day '), payeeNameKey('cafe coffee day'));
    });
    test('a known merchant VPA shares its name key with the card SMS name', () {
      expect(payeeNameKey('swiggy-order@icici'), payeeNameKey('SWIGGY'));
    });
    test('an opaque VPA has only the VPA key', () {
      expect(payeeMemoryKeys('9876543210@paytm'), ['vpa:9876543210@paytm']);
      expect(payeeMemoryKeys('paytmqr281005050101@paytm'), ['vpa:paytmqr281005050101@paytm']);
    });
    test('an empty or missing payee has no key', () {
      expect(payeeMemoryKeys(null), isEmpty);
      expect(payeeMemoryKeys('   '), isEmpty);
      expect(payeeMemoryKey(null), isNull);
    });
    test('Devanagari names keep their letters', () {
      expect(payeeNameKey('राम किराना'), 'name:राम किराना');
    });
    test('row ids carry the kind and round-trip the key', () {
      final rowId = payeeMemoryRowId(kPayeeExpense, 'vpa:x@ybl');
      expect(rowId, 'expense|vpa:x@ybl');
      expect(payeeKeyOfRowId(rowId), 'vpa:x@ybl');
      expect(payeeMemoryRowIds(kPayeeIncome, 'rahul@okaxis'), ['income|vpa:rahul@okaxis', 'income|name:rahul']);
    });
    test('payeeKindFor maps debit to expense and credit to income', () {
      expect(payeeKindFor(TxnDirection.debit), kPayeeExpense);
      expect(payeeKindFor(TxnDirection.credit), kPayeeIncome);
    });
  });

  group('rememberedCategoryId', () {
    test('the VPA wins over the name', () {
      final memory = {'expense|name:rahul sharma': 'byName', 'expense|vpa:rahul.sharma@okaxis': 'byVpa'};
      expect(rememberedCategoryId(memory, kind: kPayeeExpense, raw: 'rahul.sharma@okaxis'), 'byVpa');
    });
    test('falls back to the name key', () {
      final memory = {'expense|name:swiggy': 'food'};
      expect(rememberedCategoryId(memory, kind: kPayeeExpense, raw: 'swiggy@ybl'), 'food');
      expect(rememberedCategoryId(memory, kind: kPayeeExpense, raw: 'SWIGGY'), 'food');
    });
    test('expense and income memories stay apart', () {
      final memory = {'expense|name:swiggy': 'food'};
      expect(rememberedCategoryId(memory, kind: kPayeeIncome, raw: 'SWIGGY'), isNull);
    });
    test('an unknown or missing payee finds nothing', () {
      expect(rememberedCategoryId(const {}, kind: kPayeeExpense, raw: 'x@ybl'), isNull);
      expect(rememberedCategoryId(const {'expense|name:x': 'c'}, kind: kPayeeExpense, raw: null), isNull);
    });
  });

  group('isPersonToPersonPayee', () {
    bool p2p(String? counterparty, {Instrument instrument = Instrument.upi, String suggested = 'other_expense'}) =>
        isPersonToPersonPayee(counterparty: counterparty, instrument: instrument, suggestedCategoryKey: suggested);

    test('a person VPA or name paid over UPI with no keyword match', () {
      expect(p2p('rahul.sharma@okaxis'), isTrue);
      expect(p2p('9876543210@paytm'), isTrue);
      expect(p2p('PRADEEP KUMAR'), isTrue);
      expect(p2p('rahul@okaxis', suggested: 'other_income'), isTrue);
    });
    test('known merchants, merchant QR codes and business words are shops', () {
      expect(p2p('swiggy@ybl'), isFalse);
      expect(p2p('q123456789@ybl'), isFalse);
      expect(p2p('paytmqr281005050101@paytm'), isFalse);
      expect(p2p('sharma_stores_12@ybl'), isFalse);
      expect(p2p('GREEN LEAF FOODS PVT LTD'), isFalse);
    });
    test('a keyword match, a non-UPI instrument or no payee is not asked about', () {
      expect(p2p('rahul@okaxis', suggested: 'food'), isFalse);
      expect(p2p('rahul@okaxis', instrument: Instrument.card), isFalse);
      expect(p2p(null), isFalse);
      expect(p2p(''), isFalse);
    });
  });

  group('parsedSmsPayee and asksForPayeeCategory', () {
    String parsed({String direction = 'debit', String? counterparty = 'rahul@okaxis', String instrument = 'upi', String? suggested = 'other_expense'}) =>
        jsonEncode({'direction': direction, 'counterparty': counterparty, 'instrument': instrument, 'suggestedCategory': ?suggested});

    test('reads kind, payee, instrument and suggestion back', () {
      final payee = parsedSmsPayee(parsed(direction: 'credit', suggested: 'salary'))!;
      expect(payee.kind, kPayeeIncome);
      expect(payee.counterparty, 'rahul@okaxis');
      expect(payee.instrument, Instrument.upi);
      expect(payee.suggestedCategoryKey, 'salary');
    });
    test('a missing suggestion reads as the fallback of its side', () {
      expect(parsedSmsPayee(parsed(suggested: null))!.suggestedCategoryKey, 'other_expense');
      expect(parsedSmsPayee(parsed(direction: 'credit', suggested: null))!.suggestedCategoryKey, 'other_income');
    });
    test('an unread SMS has no payee', () {
      expect(parsedSmsPayee(null), isNull);
      expect(parsedSmsPayee('[]'), isNull);
    });
    test('a new person is asked about until a category is remembered', () {
      final payee = parsedSmsPayee(parsed())!;
      expect(asksForPayeeCategory(payee, const {}), isTrue);
      expect(asksForPayeeCategory(payee, const {'expense|vpa:rahul@okaxis': 'family'}), isFalse);
      expect(asksForPayeeCategory(payee, const {'income|vpa:rahul@okaxis': 'family'}), isTrue);
    });
    test('a merchant is never asked about', () {
      expect(asksForPayeeCategory(parsedSmsPayee(parsed(counterparty: 'swiggy@ybl'))!, const {}), isFalse);
    });
  });

  group('payee normaliser helpers', () {
    test('isKnownMerchantPayee spots known handles and names', () {
      expect(isKnownMerchantPayee('blinkit@ybl'), isTrue);
      expect(isKnownMerchantPayee('Swiggy'), isTrue);
      expect(isKnownMerchantPayee('rahul@okaxis'), isFalse);
    });
    test('isOpaqueVpa spots VPAs with no readable name', () {
      expect(isOpaqueVpa('9876543210@paytm'), isTrue);
      expect(isOpaqueVpa('bharatpe.123@yesbank'), isTrue);
      expect(isOpaqueVpa('rahul@okaxis'), isFalse);
      expect(isOpaqueVpa('PRADEEP KUMAR'), isFalse);
    });
  });
}

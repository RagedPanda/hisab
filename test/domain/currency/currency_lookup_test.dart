import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/backup/backup_settings.dart';
import 'package:hisab/domain/currency/currency_lookup.dart';
import 'package:hisab/domain/currency/currency_setup.dart';
import 'package:hisab/domain/currency/currency_table.dart';

void main() {
  group('bundled table', () {
    test('codes are unique three-letter ISO codes', () {
      final codes = kCurrencies.map((currency) => currency.code).toList();
      expect(codes.toSet().length, codes.length);
      expect(codes.every(RegExp(r'^[A-Z]{3}$').hasMatch), isTrue);
      expect(kCurrencies.length, greaterThan(140));
    });
    test('every entry has a name, symbol, valid minor digits and named regions', () {
      for (final currency in kCurrencies) {
        expect(currency.name, isNotEmpty, reason: currency.code);
        expect(currency.symbol.trim(), isNotEmpty, reason: currency.code);
        expect(currency.minorDigits, inInclusiveRange(0, 3), reason: currency.code);
        expect(currency.regions.every(kCountryNames.containsKey), isTrue, reason: currency.code);
      }
    });
    test('minor digits follow ISO 4217 for known cases', () {
      expect(currencyByCode('INR')!.minorDigits, 2);
      expect(currencyByCode('JPY')!.minorDigits, 0);
      expect(currencyByCode('KWD')!.minorDigits, 3);
    });
    test('common currencies lead the list', () {
      expect(kCurrencies.take(4).map((currency) => currency.code), ['INR', 'USD', 'EUR', 'GBP']);
    });
  });

  group('legacy symbol migration', () {
    const cases = <(String?, String)>[
      ('₹', 'INR'),
      (r'$', 'USD'),
      ('€', 'EUR'),
      ('£', 'GBP'),
      ('¥', 'JPY'),
      ('Rs', 'INR'),
      ('Rs.', 'INR'),
      ('₨', 'INR'),
      ('CHF', 'CHF'),
      ('chf', 'CHF'),
      (' AED ', 'AED'),
      (r'A$', 'AUD'),
      ('₩', 'KRW'),
      ('฿', 'THB'),
      ('', 'INR'),
      (null, 'INR'),
      ('money', 'INR'),
      ('\u{1F4B0}', 'INR'),
    ];
    for (final (symbol, code) in cases) {
      test('${symbol ?? 'null'} -> $code', () => expect(currencyCodeForLegacySymbol(symbol), code));
    }
  });

  group('search', () {
    List<String> codes(String query) => searchCurrencies(query).map((currency) => currency.code).toList();
    test('empty query returns the whole table', () => expect(codes('  ').length, kCurrencies.length));
    test('exact code ranks first, case-insensitive', () => expect(codes('chf').first, 'CHF'));
    test('code prefix', () => expect(codes('US'), contains('USD')));
    test('name word', () => expect(codes('swiss').first, 'CHF'));
    test('name finds every rupee, Indian first', () {
      final rupees = codes('rupee');
      expect(rupees.first, 'INR');
      expect(rupees, containsAll(['PKR', 'LKR', 'NPR']));
    });
    test('country name', () {
      expect(codes('japan'), ['JPY']);
      expect(codes('germany'), ['EUR']);
      expect(codes('ecuador'), contains('USD'));
    });
    test('symbol', () => expect(codes('₹'), ['INR']));
    test('no match', () => expect(codes('zzqq'), isEmpty));
  });

  group('labels and ordering', () {
    test('short label shows symbol and code', () {
      expect(currencyShortLabel('INR'), '₹ INR');
      expect(currencyShortLabel('CHF'), 'CHF');
    });
    test('symbol for an unknown code is the code', () => expect(symbolForCurrencyCode('xyz'), 'XYZ'));
    test('selected currency moves first', () {
      final ordered = selectedFirst(kCurrencies, 'JPY');
      expect(ordered.first.code, 'JPY');
      expect(ordered.length, kCurrencies.length);
    });
  });

  group('first-launch gating decision', () {
    test('fresh install is asked', () => expect(currencyCodeToMigrate(storedCode: null, legacySymbol: null, hasUserData: false), isNull));
    test('stored code is left alone', () => expect(currencyCodeToMigrate(storedCode: 'EUR', legacySymbol: r'$', hasUserData: true), isNull));
    test('upgrade with an old symbol migrates it', () => expect(currencyCodeToMigrate(storedCode: null, legacySymbol: '€', hasUserData: false), 'EUR'));
    test('upgrade with an unknown old symbol gets INR', () => expect(currencyCodeToMigrate(storedCode: null, legacySymbol: 'zz', hasUserData: false), 'INR'));
    test('upgrade that never changed settings gets INR', () => expect(currencyCodeToMigrate(storedCode: null, legacySymbol: null, hasUserData: true), 'INR'));
  });

  group('backup currency', () {
    test('reads the stored code', () => expect(backupCurrencyCode({'settings': backupSettingsSection(currencyCode: 'GBP')}), 'GBP'));
    test('older backup without settings keeps the current currency', () => expect(backupCurrencyCode({'app': 'hisab'}), isNull));
    test(
      'unknown code is ignored',
      () => expect(
        backupCurrencyCode({
          'settings': {'currencyCode': 'XXX'},
        }),
        isNull,
      ),
    );
  });
}

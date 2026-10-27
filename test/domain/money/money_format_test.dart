import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/core/money.dart';
import 'package:hisab/domain/money/money_format_resolver.dart';
import 'package:hisab/domain/stats/spend_series.dart';

/// No-break space: between a trailing symbol and the number, and the "space"
/// group separator.
const nbsp = ' ';

MoneyFormat _format(String code, String language, String country) =>
    resolveMoneyFormat(currencyCode: code, deviceLanguage: language, deviceCountry: country);

void main() {
  final usd = _format('USD', 'en', 'US');
  final eurDe = _format('EUR', 'de', 'DE');
  final eurIe = _format('EUR', 'en', 'IE');
  final chf = _format('CHF', 'de', 'CH');
  final jpy = _format('JPY', 'ja', 'JP');

  group('formatMinor', () {
    test('INR output is unchanged by default', () {
      expect(formatMinor(123456789), '₹12,34,567.89');
      expect(formatMinor(25000), '₹250');
      expect(formatMinor(9950), '₹99.50');
      expect(formatMinor(-123456), '-₹1,234.56');
      expect(formatMinor(25000, symbol: 'CHF'), 'CHF 250');
      expect(formatMinor(123456789, format: _format('INR', 'en', 'IN')), '₹12,34,567.89');
    });

    test('USD groups in thousands', () {
      expect(formatMinor(123456789, format: usd), '\$1,234,567.89');
    });

    test('EUR on a German device: dot groups, comma decimals, symbol after', () {
      expect(formatMinor(123456789, format: eurDe), '1.234.567,89$nbsp€');
    });

    test('EUR on an Irish device keeps the symbol in front', () {
      expect(formatMinor(123456789, format: eurIe), '€1,234,567.89');
    });

    test('CHF uses apostrophe groups', () {
      expect(formatMinor(123456789, format: chf), 'CHF 1’234’567.89');
    });

    test('JPY has no decimals and rounds', () {
      expect(jpy.fractionDigits, 0);
      expect(formatMinor(123456789, format: jpy), '${jpy.symbol}1,234,568');
      expect(formatMinor(123456789, format: jpy, showDecimals: true), '${jpy.symbol}1,234,568');
    });

    test('negatives lead with a minus in every style', () {
      expect(formatMinor(-123456, format: usd), '-\$1,234.56');
      expect(formatMinor(-123456, format: eurDe), '-1.234,56$nbsp€');
      expect(formatMinor(-123456, format: chf), '-CHF 1’234.56');
    });

    test('showDecimals null, true and false', () {
      expect(formatMinor(25000, format: eurDe), '250$nbsp€');
      expect(formatMinor(25000, format: eurDe, showDecimals: true), '250,00$nbsp€');
      expect(formatMinor(98767, format: eurDe, showDecimals: false), '988$nbsp€');
      expect(formatMinor(98767, format: eurDe), '987,67$nbsp€');
      expect(formatMinor(25000, showDecimals: true), '₹250.00');
      expect(formatMinor(98767, showDecimals: false), '₹988');
    });

    test('compact uses L / Cr for Indian and K / M / B for Western', () {
      expect(formatMinor(25000000, compact: true), '₹2.50L');
      expect(formatMinor(1200000000, compact: true), '₹1.20Cr');
      expect(formatMinor(9999900, compact: true), '₹99,999');
      expect(formatMinor(25000000, format: usd, compact: true), '\$250.00K');
      expect(formatMinor(150000000, format: eurDe, compact: true), '1,50M$nbsp€');
      expect(formatMinor(250000000000, format: usd, compact: true), '\$2.50B');
    });

    test('space groups use a no-break space', () {
      final spaced = applyNumberFormatChoice(usd, NumberFormatChoice.spaceGroupCommaDecimal);
      expect(formatMinor(123456789, format: spaced), '\$1${nbsp}234${nbsp}567,89');
    });

    test('settings sample shows the separators without a symbol', () {
      expect(numberFormatSample(MoneyFormat.inr), '1,23,456.78');
      expect(numberFormatSample(usd), '123,456.78');
      expect(numberFormatSample(eurDe), '123.456,78');
      expect(numberFormatSample(jpy), '123,456.78');
    });
  });

  group('axisAmountLabel', () {
    test('Western formats use K / M and their decimal separator', () {
      expect(axisAmountLabel(2500, format: eurDe), '2,5K$nbsp€');
      expect(axisAmountLabel(1500000, format: usd), '\$1.5M');
      expect(axisAmountLabel(150000), '1.5L');
    });
  });

  group('resolveMoneyFormat', () {
    test('the device region decides when it uses the currency', () {
      expect(eurDe.decimalSeparator, ',');
      expect(eurIe.decimalSeparator, '.');
    });

    test('a region that does not use the currency falls back to its own locale', () {
      final inrOnUs = _format('INR', 'en', 'US');
      expect(inrOnUs.grouping, DigitGrouping.indian);
      final usdOnIndia = _format('USD', 'en', 'IN');
      expect(usdOnIndia.grouping, DigitGrouping.western);
      final eurOnUs = _format('EUR', 'en', 'US');
      expect(eurOnUs.decimalSeparator, ',');
    });

    test('English on a German device writes euros the German way', () {
      final eurEnDe = _format('EUR', 'en', 'DE');
      expect(eurEnDe.groupSeparator, '.');
      expect(eurEnDe.decimalSeparator, ',');
    });

    test('INR stays Indian for Indian languages', () {
      for (final language in ['hi', 'ml', 'mr', 'ta', 'bn']) {
        expect(_format('INR', language, 'IN').grouping, DigitGrouping.indian, reason: language);
      }
    });

    test('no device locale uses the canonical one', () {
      expect(resolveMoneyFormat(currencyCode: 'INR'), MoneyFormat.inr);
      expect(resolveMoneyFormat(currencyCode: 'CHF').groupSeparator, '’');
    });

    test('the override replaces grouping and separators but not decimals or placement', () {
      final indianEuro = resolveMoneyFormat(currencyCode: 'EUR', deviceLanguage: 'de', deviceCountry: 'DE', choice: NumberFormatChoice.indian);
      expect(formatMinor(123456789, format: indianEuro), '12,34,567.89$nbsp€');
      final dotted = resolveMoneyFormat(currencyCode: 'INR', choice: NumberFormatChoice.dotGroupCommaDecimal);
      expect(formatMinor(123456789, format: dotted), '₹1.234.567,89');
      final western = resolveMoneyFormat(currencyCode: 'INR', choice: NumberFormatChoice.western);
      expect(formatMinor(123456789, format: western), '₹1,234,567.89');
      final yen = resolveMoneyFormat(currencyCode: 'JPY', choice: NumberFormatChoice.dotGroupCommaDecimal);
      expect(yen.fractionDigits, 0);
    });

    test('canonical locales come from the table, then CLDR', () {
      expect(canonicalLocaleFor('EUR'), 'de');
      expect(canonicalLocaleFor('XYZ'), 'en');
      expect(displayFractionDigits('KRW'), 0);
      expect(displayFractionDigits('HUF'), 0);
      expect(displayFractionDigits('KWD'), 2);
      expect(displayFractionDigits('USD'), 2);
    });
  });

  group('moneyFormatForLabel', () {
    test('no label, or the home symbol, is the home format', () {
      expect(moneyFormatForLabel(null, home: MoneyFormat.inr), MoneyFormat.inr);
      expect(moneyFormatForLabel('  ', home: MoneyFormat.inr), MoneyFormat.inr);
      expect(moneyFormatForLabel('₹', home: MoneyFormat.inr), MoneyFormat.inr);
    });

    test('a known currency label gets that currency\'s conventions', () {
      final euro = moneyFormatForLabel('€', home: MoneyFormat.inr);
      expect(formatMinor(123456, format: euro), '1.234,56$nbsp€');
      final dollar = moneyFormatForLabel('USD', home: MoneyFormat.inr);
      expect(dollar.grouping, DigitGrouping.western);
      expect(dollar.symbol, 'USD');
    });

    test('an unknown label keeps the home conventions', () {
      expect(formatMinor(123456789, format: moneyFormatForLabel('Tokens', home: MoneyFormat.inr)), 'Tokens 12,34,567.89');
    });
  });

  group('parseAmountToMinor', () {
    final spaced = applyNumberFormatChoice(usd, NumberFormatChoice.spaceGroupCommaDecimal);

    test('dot-decimal styles behave as before', () {
      expect(parseAmountToMinor('1,23,456.78'), 12345678);
      expect(parseAmountToMinor('₹ 250'), 25000);
      expect(parseAmountToMinor('12.5'), 1250);
      expect(parseAmountToMinor('1.2.3'), isNull);
      expect(parseAmountToMinor('1,234.56', format: usd), 123456);
    });

    test('comma-decimal styles read a comma as the decimal', () {
      expect(parseAmountToMinor('12,50', format: eurDe), 1250);
      expect(parseAmountToMinor('1.234,56', format: eurDe), 123456);
      expect(parseAmountToMinor('1.234.567,89 €', format: eurDe), 123456789);
      expect(parseAmountToMinor('1 234,56', format: spaced), 123456);
      expect(parseAmountToMinor('1${nbsp}234,56', format: spaced), 123456);
    });

    test('a comma style still accepts a dot decimal', () {
      expect(parseAmountToMinor('12.50', format: eurDe), 1250);
      expect(parseAmountToMinor('12.5', format: eurDe), 1250);
      expect(parseAmountToMinor('1234.5', format: eurDe), 123450);
    });

    test('pasted dot groups are stripped when unambiguous', () {
      expect(parseAmountToMinor('1.234', format: eurDe), 123400);
      expect(parseAmountToMinor('1.234.567', format: eurDe), 123456700);
    });

    test('ambiguous or malformed input is rejected', () {
      expect(parseAmountToMinor('1,2,3', format: eurDe), isNull);
      expect(parseAmountToMinor('1.23.4', format: eurDe), isNull);
      expect(parseAmountToMinor('12,345', format: eurDe), isNull);
      expect(parseAmountToMinor('', format: eurDe), isNull);
    });

    test('CHF apostrophe groups are stripped', () {
      expect(parseAmountToMinor('1’234.50', format: chf), 123450);
      expect(parseAmountToMinor("1'234.50", format: chf), 123450);
    });

    test('amountInputText round-trips in every style', () {
      for (final format in [MoneyFormat.inr, usd, eurDe, eurIe, chf, spaced]) {
        for (final minor in [0, 5, 1250, 25000, 123456789]) {
          expect(parseAmountToMinor(amountInputText(minor, format: format), format: format), minor, reason: '$format $minor');
        }
      }
      expect(amountInputText(1250, format: eurDe), '12,50');
      expect(amountInputText(1250), '12.50');
    });

    test('reformatAmountInput moves text between decimal separators', () {
      expect(reformatAmountInput('12,50', from: eurDe, to: MoneyFormat.inr), '12.50');
      expect(reformatAmountInput('12.50', from: MoneyFormat.inr, to: eurDe), '12,50');
      expect(reformatAmountInput('12.50', from: MoneyFormat.inr, to: usd), '12.50');
      expect(reformatAmountInput('', from: MoneyFormat.inr, to: eurDe), '');
    });

    test('zero-decimal currencies take whole amounts only (#90)', () {
      expect(parseAmountToMinor('1,000', format: jpy), 100000);
      expect(parseAmountToMinor('¥1,000', format: jpy), 100000);
      expect(parseAmountToMinor('1000.', format: jpy), 100000);
      expect(parseAmountToMinor('1000.5', format: jpy), isNull);
      expect(parseAmountToMinor('1000.50', format: jpy), isNull);
      final dottedYen = jpy.copyWith(groupSeparator: '.', decimalSeparator: ',');
      expect(parseAmountToMinor('1.000', format: dottedYen), 100000);
      expect(parseAmountToMinor('1000,5', format: dottedYen), isNull);
      expect(parseAmountToMinor('1000.5', format: dottedYen), isNull);
    });

    test('zero-decimal amountInputText shows the rounded whole amount', () {
      expect(amountInputText(100000, format: jpy), '1000');
      expect(amountInputText(100050, format: jpy), '1001');
      expect(amountInputText(100049, format: jpy), '1000');
      expect(amountInputText(-100050, format: jpy), '-1001');
      for (final minor in [0, 100, 25000, 123456700]) {
        expect(parseAmountToMinor(amountInputText(minor, format: jpy), format: jpy), minor, reason: '$minor');
      }
    });

    test('reformatAmountInput rounds into and out of zero-decimal currencies', () {
      expect(reformatAmountInput('12.50', from: MoneyFormat.inr, to: jpy), '13');
      expect(reformatAmountInput('1000', from: jpy, to: MoneyFormat.inr), '1000');
      expect(reformatAmountInput('1000', from: jpy, to: jpy), '1000');
    });

    test('amountInputCharacters drops the decimal separator for zero-decimal currencies', () {
      bool accepts(MoneyFormat format, String character) => amountInputCharacters(format).hasMatch(character);
      expect([accepts(usd, '.'), accepts(usd, ','), accepts(eurDe, ','), accepts(eurDe, '.')], everyElement(isTrue));
      expect(accepts(jpy, '7'), isTrue);
      expect(accepts(jpy, ','), isTrue);
      expect(accepts(jpy, '.'), isFalse);
      final dottedYen = jpy.copyWith(groupSeparator: '.', decimalSeparator: ',');
      expect(accepts(dottedYen, '.'), isTrue);
      expect(accepts(dottedYen, ','), isFalse);
    });
  });

  group('amount field affixes', () {
    test('a leading symbol is a prefix, a trailing one a suffix', () {
      expect(amountPrefixText(MoneyFormat.inr), '₹ ');
      expect(amountSuffixText(MoneyFormat.inr), isNull);
      expect(amountPrefixText(eurDe), isNull);
      expect(amountSuffixText(eurDe), '€');
    });
  });
}

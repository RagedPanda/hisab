import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hisab/core/money.dart';
import 'package:hisab/domain/launcher/spend_widget_figures.dart';
import 'package:hisab/domain/ledger/personal_totals.dart';
import 'package:hisab/features/shortcuts/spend_widget_data.dart';
import 'package:hisab/l10n/generated/app_localizations.dart';

SpendWidgetFigures _figures({required int october, required int september}) => spendWidgetFigures(
      lines: [
        if (october > 0) LedgerLine(kind: 'expense', amountMinor: october, occurredAt: DateTime(2026, 10, 5)),
        if (september > 0) LedgerLine(kind: 'expense', amountMinor: september, occurredAt: DateTime(2026, 9, 5)),
      ],
      now: DateTime(2026, 10, 20),
      monthStartDay: 1,
    );

void main() {
  final english = lookupAppLocalizations(const Locale('en'));
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('hi');
  });

  test('names the month, the spend and the change against last month', () {
    final data = spendWidgetData(_figures(october: 1100000, september: 1000000), l10n: english, moneyFormat: MoneyFormat.inr, locale: 'en', opacity: 80);
    expect(data.title, 'Spent in October');
    expect(data.amount, '₹11,000');
    expect(data.comparison, '▲ 10% vs Sep');
    expect(data.previous, 'Sep: ₹10,000');
    expect(data.validUntil, DateTime(2026, 11, 1));
    expect(data.toMap()['opacity'], 80);
  });

  test('says less spend as a fall and leaves the comparison out with no spend last month', () {
    expect(spendWidgetData(_figures(october: 500, september: 1000), l10n: english, moneyFormat: MoneyFormat.inr, locale: 'en', opacity: 100).comparison, '▼ 50% vs Sep');
    expect(spendWidgetData(_figures(october: 500, september: 0), l10n: english, moneyFormat: MoneyFormat.inr, locale: 'en', opacity: 100).comparison, isEmpty);
  });

  test('follows the app language', () {
    final data = spendWidgetData(_figures(october: 1000, september: 1000), l10n: lookupAppLocalizations(const Locale('hi')), moneyFormat: MoneyFormat.inr, locale: 'hi', opacity: 100);
    expect(data.title, contains('अक्टूबर'));
  });
}
